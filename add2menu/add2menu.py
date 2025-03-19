import os
import shutil
import gi
import sys
import threading
import re
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib, Gdk, Gio, GdkPixbuf
from datetime import datetime

# Icon cache to avoid repeated searches
ICON_CACHE = {}

class Add2MenuWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        Gtk.ApplicationWindow.__init__(
            self,
            application=app,
            title="Add To Menu"
        )
        
        # Set window properties properly following GTK standards
        self.set_default_size(600, 500)
        self.set_position(Gtk.WindowPosition.CENTER)
        
        # Constants
        self.PREFIX = os.getenv("PREFIX", "/data/data/com.termux/files/usr")
        self.DISTRO_NAME = os.getenv("distro_name", "debian")
        self.DISTRO_PATH = os.getenv("distro_path", f"/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/{self.DISTRO_NAME}")
        self.APPLICATIONS_DIR = os.path.join(self.PREFIX, "share/applications")
        self.ADDED_DIR = os.path.join(self.APPLICATIONS_DIR, "pd_added")
        
        # Task status
        self.is_loading = False
        self.cancellable = Gio.Cancellable()

        # Create pd_added directory if it doesn't exist
        os.makedirs(self.ADDED_DIR, exist_ok=True)
        
        # Setup CSS
        self.setup_css()
        
        # Main container using GtkBuilder for better performance
        builder = Gtk.Builder()
        builder.add_from_string("""
        <interface>
          <object class="GtkBox" id="main_box">
            <property name="visible">True</property>
            <property name="orientation">vertical</property>
            <property name="spacing">0</property>
          </object>
        </interface>
        """)
        self.main_box = builder.get_object("main_box")
        self.add(self.main_box)

        # Setup components in correct order
        self.setup_header_bar()
        self.setup_status_bar()
        self.setup_main_content()
        
        # Initialize loading indicator for async operations
        self.spinner = Gtk.Spinner()
        self.spinner.set_size_request(22, 22)
        self.status_bar.pack_end(self.spinner, False, False, 5)
        
        # Show everything before starting the load
        self.show_all()
        self.status_label.set_text("Loading applications...")
        
        # Delay app loading to let the UI render first
        GLib.timeout_add(100, self._delayed_load)

        # Store reference to application actions for enabling/disabling
        self.app = app
        self.no_sandbox_action = app.lookup_action("no-sandbox")
        self.absolute_path_action = app.lookup_action("absolute-path")
        self.nogpu_action = app.lookup_action("nogpu")

    def setup_css(self):
        css = """
            .main-window {
                background-color: @theme_bg_color;
            }
            headerbar {
                /* Let the theme control the headerbar colors */
                padding: 8px;
                min-height: 0;
            }
            .mode-switch {
                border-radius: 20px;
                padding: 5px 10px;
                background: alpha(@theme_fg_color, 0.1);
            }
            .app-list {
                background-color: @theme_base_color;
                border-radius: 5px;
                border: 1px solid @borders;
                color: @theme_fg_color;
            }
            .app-list row {
                padding: 8px;
            }
            .app-list row:selected {
                background-color: @theme_selected_bg_color;
                color: @theme_selected_fg_color;
            }
            /* Style the play button column */
            .play-button {
                color: @theme_selected_bg_color;
                padding: 4px;
                border-radius: 50%;
            }
            .play-button:hover {
                background-color: alpha(@theme_selected_bg_color, 0.1);
            }
            .action-button {
                color: @theme_selected_fg_color;
                border-radius: 5px;
                padding: 8px 15px;
                background-color: @theme_selected_bg_color;
            }
            .action-button:hover {
                background-color: shade(@theme_selected_bg_color, 0.9);
            }
            .status-bar {
                background-color: @theme_bg_color;
                border-top: 1px solid @borders;
                padding: 5px;
                color: @theme_fg_color;
            }
            /* Animation for app launch */
            .launch-flash {
                background-color: alpha(@theme_selected_bg_color, 0.2);
                transition: background-color 400ms ease-out;
            }
            /* Search bar styling */
            entry.search {
                border-radius: 5px;
                min-height: 36px;
            }
            button.search-button {
                border-radius: 5px;
                min-height: 36px;
                padding: 0 15px;
                background-color: @theme_selected_bg_color;
                color: @theme_selected_fg_color;
            }
            button.search-button:hover {
                background-color: shade(@theme_selected_bg_color, 0.9);
            }
        """
        style_provider = Gtk.CssProvider()
        style_provider.load_from_data(css.encode())
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def setup_header_bar(self):
        # Create a properly integrated headerbar
        header = Gtk.HeaderBar()
        header.set_show_close_button(True)  # This enables the standard window controls
        header.set_title("Add To Menu")
        header.set_subtitle(f"Distro: {self.DISTRO_NAME}")
        
        # Mode switch
        mode_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        mode_box.get_style_context().add_class('mode-switch')
        
        self.add_radio = Gtk.RadioButton.new_with_label_from_widget(None, "Add")
        self.remove_radio = Gtk.RadioButton.new_with_label_from_widget(self.add_radio, "Remove")
        
        # Connect BOTH radio buttons to ensure mode changes are detected properly
        self.add_radio.connect("toggled", self.on_mode_changed)
        self.remove_radio.connect("toggled", self.on_mode_changed)
        
        mode_box.pack_start(self.add_radio, False, False, 5)
        mode_box.pack_start(self.remove_radio, False, False, 5)
        
        # Search toggle button
        self.search_toggle_button = Gtk.ToggleButton()
        search_icon = Gio.ThemedIcon(name="system-search-symbolic")
        search_image = Gtk.Image.new_from_gicon(search_icon, Gtk.IconSize.BUTTON)
        self.search_toggle_button.add(search_image)
        self.search_toggle_button.set_tooltip_text("Toggle search bar")
        self.search_toggle_button.connect("toggled", self.on_search_toggle)
        
        # Style the search toggle button
        self.search_toggle_button.get_style_context().add_class('suggested-action')
        
        # Add a small margin between mode switches and search button
        self.search_toggle_button.set_margin_start(8)
        
        # Add search button to the mode box
        mode_box.pack_start(self.search_toggle_button, False, False, 0)
        
        header.pack_start(mode_box)
        
        # Add a proper menu button (hamburger menu) to headerbar
        menu_button = Gtk.MenuButton()
        menu_button.set_tooltip_text("Main Menu")
        
        # Create app menu
        menu = Gio.Menu()
        menu.append("Launch with --no-sandbox", "app.no-sandbox")  # Add no-sandbox toggle
        menu.append("Use Absolute Paths", "app.absolute-path")     # Add absolute path toggle
        menu.append("Launch with --nogpu", "app.nogpu")            # Add nogpu toggle
        menu.append("About Add2Menu", "app.about")
        menu.append("Quit", "app.quit")
        
        # Set popover menu
        popover = Gtk.Popover.new_from_model(menu_button, menu)
        menu_button.set_popover(popover)
        
        # Use hamburger icon for menu button
        hamburger_icon = Gio.ThemedIcon(name="open-menu-symbolic")
        menu_image = Gtk.Image.new_from_gicon(hamburger_icon, Gtk.IconSize.BUTTON)
        menu_button.add(menu_image)
        
        # Refresh button
        refresh_button = Gtk.Button()
        refresh_icon = Gio.ThemedIcon(name="view-refresh-symbolic")
        refresh_image = Gtk.Image.new_from_gicon(refresh_icon, Gtk.IconSize.BUTTON)
        refresh_button.add(refresh_image)
        refresh_button.set_tooltip_text("Refresh application list")
        refresh_button.connect("clicked", self.on_refresh_clicked)
        
        # Add buttons to header
        header.pack_end(menu_button)
        header.pack_end(refresh_button)
        
        # Properly set the titlebar to integrate with the window manager
        self.set_titlebar(header)
        
        # Set window decoration hints to follow GTK standards
        self.set_decorated(True) # Let GTK manage the window decorations
        
        # Make the headerbar use theme styling
        context = header.get_style_context()
        context.add_class('titlebar')
        context.add_class('default-decoration')

    def setup_main_content(self):
        # Content area with padding
        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        content_box.set_margin_start(20)
        content_box.set_margin_end(20)
        content_box.set_margin_top(20)
        content_box.set_margin_bottom(20)
        
        # Search bar at the top
        self.search_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.search_box.set_margin_bottom(10)
        
        # Create search entry
        self.search_entry = Gtk.SearchEntry()
        self.search_entry.set_placeholder_text("Search applications...")
        self.search_entry.connect("search-changed", self.on_search_changed)
        self.search_entry.set_hexpand(True)
        self.search_entry.get_style_context().add_class('search')
        
        # Create search button
        search_button = Gtk.Button.new_with_label("Search")
        search_button.connect("clicked", self.on_search_button_clicked)
        search_button.get_style_context().add_class('search-button')
        
        # Add to search box
        self.search_box.pack_start(self.search_entry, True, True, 0)
        self.search_box.pack_start(search_button, False, False, 0)
        
        # Initialize search box as hidden but keep all children visible
        self.search_box.set_no_show_all(True)
        self.search_box.hide()
        
        # Add search box to main content
        content_box.pack_start(self.search_box, False, False, 0)
        
        # Select all checkbox at top
        self.select_all_check = Gtk.CheckButton(label="Select All")
        self.select_all_check.connect("toggled", self.on_select_all_toggled)
        self.select_all_check.set_halign(Gtk.Align.START)  # Align to the left
        content_box.pack_start(self.select_all_check, False, False, 0)
        
        # Apps list with proper selection mode
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_shadow_type(Gtk.ShadowType.IN)
        
        # Use TreeView with exec command
        self.liststore = Gtk.ListStore(bool, str, str, str, str)  # checkbox, name, path, icon, exec_cmd
        self.treeview = Gtk.TreeView(model=self.liststore)
        self.treeview.set_headers_visible(True)
        self.treeview.get_style_context().add_class('app-list')
        
        # Checkbox column
        renderer_toggle = Gtk.CellRendererToggle()
        renderer_toggle.connect("toggled", self.on_item_toggled)
        column_toggle = Gtk.TreeViewColumn("", renderer_toggle, active=0)
        self.treeview.append_column(column_toggle)
        
        # Icon column with efficient rendering
        renderer_icon = Gtk.CellRendererPixbuf()
        column_icon = Gtk.TreeViewColumn("", renderer_icon, icon_name=3)
        self.treeview.append_column(column_icon)
        
        # Name column
        renderer_text = Gtk.CellRendererText()
        renderer_text.set_property("ellipsize", "end")
        column_text = Gtk.TreeViewColumn("Application", renderer_text, text=1)
        column_text.set_expand(True)
        column_text.set_resizable(True)
        column_text.set_sort_column_id(1)  # Enable sorting by default
        self.treeview.append_column(column_text)
        
        # Play button column - create a custom renderer with button-like style
        # We'll use a box with padding to act like a button
        play_button_renderer = Gtk.CellRendererPixbuf()
        play_button_renderer.set_property("icon-name", "media-playback-start")
        play_button_renderer.set_property("stock-size", Gtk.IconSize.MENU)
        play_button_renderer.set_property("xpad", 12)  # Add horizontal padding
        play_button_renderer.set_property("ypad", 6)   # Add vertical padding
        
        # Create the column with our play button
        play_column = Gtk.TreeViewColumn("Run", play_button_renderer)
        play_column.set_alignment(0.5)  # Center the header text
        
        # Only show play button if exec_cmd exists
        play_column.set_cell_data_func(play_button_renderer, self.play_button_visibility_func)
        
        self.treeview.append_column(play_column)
        
        # Connect button click handler
        self.treeview.connect("button-press-event", self.on_treeview_button_press)
        
        # Connect row activation handler (for checkbox toggle)
        self.treeview.connect("row-activated", self.on_row_activated)
        
        scroll.add(self.treeview)
        content_box.pack_start(scroll, True, True, 0)
        
        # Action button
        button_box = Gtk.Box(spacing=6)
        button_box.set_halign(Gtk.Align.END)
        
        self.action_button = Gtk.Button.new_with_label("Add Selected")
        self.action_button.get_style_context().add_class('action-button')
        self.action_button.get_style_context().add_class('suggested-action')  # Use theme's suggested action style
        self.action_button.connect("clicked", self.on_action_clicked)
        button_box.pack_start(self.action_button, False, False, 0)
        
        content_box.pack_start(button_box, False, False, 0)
        self.main_box.pack_start(content_box, True, True, 0)

    def setup_status_bar(self):
        self.status_bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.status_bar.get_style_context().add_class('status-bar')
        
        self.status_label = Gtk.Label(label="Ready")
        self.status_label.set_halign(Gtk.Align.START)
        self.status_bar.pack_start(self.status_label, True, True, 5)
        
        self.main_box.pack_end(self.status_bar, False, False, 0)

    def start_background_task(self, task_func, *args):
        """Start a background thread for heavy operations"""
        if self.is_loading:
            return
        
        self.is_loading = True
        self.spinner.start()
        self.action_button.set_sensitive(False)
        
        # Create a new thread
        thread = threading.Thread(target=self._run_task_thread, args=(task_func, args))
        thread.daemon = True
        thread.start()

    def _run_task_thread(self, task_func, args):
        """Run the task in a background thread and update UI when done"""
        try:
            result = task_func(*args)
            # Use GLib.idle_add to safely update the UI from the background thread
            GLib.idle_add(self._complete_background_task, result)
        except Exception as e:
            GLib.idle_add(self._handle_background_error, str(e))
            
    def _complete_background_task(self, result):
        """Handle the result of the background task"""
        self.is_loading = False
        self.spinner.stop()
        self.action_button.set_sensitive(True)
        self.update_status()
        return False  # Important: return False to remove the idle callback
        
    def _handle_background_error(self, error_message):
        """Handle errors from the background thread"""
        self.is_loading = False
        self.spinner.stop()
        self.action_button.set_sensitive(True)
        self.show_message_dialog(f"Operation failed: {error_message}", "Error")
        return False  # Important: return False to remove the idle callback

    def load_apps(self):
        """Background task to load applications"""
        if self.add_radio.get_active():
            # In add mode, show apps from the distro's application directory
            path = os.path.join(self.DISTRO_PATH, "usr/share/applications")
            action_label = "Add Selected"
        else:
            # In remove mode, show ONLY apps from the pd_added directory
            path = self.ADDED_DIR
            action_label = "Remove Selected"
        
        # Get apps from directory
        apps = self.list_desktop_files(path)
        
        # Sort the apps for initial display
        sorted_apps = sorted(apps, key=lambda x: x[0].lower())
        
        # Update UI in the main thread
        GLib.idle_add(self._update_app_list, sorted_apps, action_label)
        
        return len(apps)
        
    def _update_app_list(self, apps, action_label):
        """Update the UI with the loaded apps (called in main thread)"""
        self.liststore.clear()
        self.action_button.set_label(action_label)
        
        for name, filepath, icon, exec_cmd in apps:
            self.liststore.append([False, name, filepath, icon or "application-x-executable", exec_cmd])
        
        self.update_status()
        return False  # Important: remove the idle callback

    def list_desktop_files(self, directory):
        """Parse desktop files with efficient caching"""
        desktop_files = []
        if not os.path.exists(directory):
            return desktop_files
            
        # Use a set for faster lookups of processed files
        processed_files = set()
        
        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith(".desktop") and file not in processed_files:
                    processed_files.add(file)
                    filepath = os.path.join(root, file)
                    try:
                        desktop_entry = self.parse_desktop_file(filepath)
                        if desktop_entry and not desktop_entry.get('no_display', False):
                            display_name = desktop_entry.get('name') or os.path.splitext(file)[0]
                            display_name = display_name.replace("_", " ").strip()
                            icon = desktop_entry.get('icon') or "application-x-executable"
                            exec_cmd = desktop_entry.get('exec') or ""
                            desktop_files.append((display_name, filepath, icon, exec_cmd))
                    except Exception as e:
                        print(f"Error processing {filepath}: {str(e)}")
        
        # If we're in remove mode, only show files from pd_added directory
        if directory == self.ADDED_DIR:
            # Make sure we're only seeing pd_added files
            desktop_files = [(name, path, icon, exec_cmd) for name, path, icon, exec_cmd in desktop_files
                              if path.startswith(self.ADDED_DIR)]
                        
        return desktop_files

    def parse_desktop_file(self, filepath):
        """Parse a desktop file and return a dict of key attributes"""
        result = {
            'name': None,
            'icon': None,
            'no_display': False,
            'exec': None  # Add exec command field
        }
        
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith('#'):
                        continue
                    if line.startswith('Name=') and not result['name']:
                        result['name'] = line.split("=", 1)[1].strip()
                    elif line.startswith('Icon='):
                        icon_name = line.split("=", 1)[1].strip()
                        result['icon'] = self.find_icon_cached(icon_name)
                    elif line.startswith('Exec='):
                        result['exec'] = line.split("=", 1)[1].strip()
                    elif line.startswith('NoDisplay=true'):
                        result['no_display'] = True
                        break
        except Exception as e:
            print(f"Error parsing desktop file {filepath}: {e}")
            return None
            
        return result

    def find_icon_cached(self, icon_name):
        """Find an icon with caching for performance"""
        if not icon_name:
            return "application-x-executable"
            
        # Check cache first
        if icon_name in ICON_CACHE:
            return ICON_CACHE[icon_name]
            
        # For full path icons, just return as is
        if os.path.isfile(icon_name):
            ICON_CACHE[icon_name] = icon_name
            return icon_name
            
        # If it's an icon name without extension, try GTK icon theme
        icon_theme = Gtk.IconTheme.get_default()
        
        # Check if the icon exists in the theme
        if icon_theme.has_icon(icon_name):
            ICON_CACHE[icon_name] = icon_name
            return icon_name
            
        # Try some variations of the icon name
        variations = [
            icon_name,
            f"{icon_name}-symbolic",
            icon_name.lower(),
            f"application-x-{icon_name.lower()}",
            f"applications-{icon_name.lower()}"
        ]
        
        for variation in variations:
            if icon_theme.has_icon(variation):
                ICON_CACHE[icon_name] = variation
                return variation
                
        # Fallback if no icon was found
        ICON_CACHE[icon_name] = "application-x-executable"
        return "application-x-executable"

    def on_refresh_clicked(self, button):
        """Handle refresh button click"""
        if not self.is_loading:
            # Clear search entry
            self.search_entry.set_text("")
            self.start_background_task(self.load_apps)

    def on_mode_changed(self, button):
        """Handle mode switch"""
        # We only want to trigger refresh when a button becomes active
        # This prevents double-refresh since both buttons emit signals
        if button.get_active():
            # Get the current button mode (add or remove)
            mode = "Add" if self.add_radio.get_active() else "Remove"
            print(f"Mode changed to: {mode}")
            
            # Enable/disable menu options based on mode
            is_add_mode = mode == "Add"
            self.no_sandbox_action.set_enabled(is_add_mode)
            self.absolute_path_action.set_enabled(is_add_mode)
            self.nogpu_action.set_enabled(is_add_mode)
            
            # Reset search toggle button 
            self.search_toggle_button.set_active(False)
            # Ensure search box is hidden
            self.search_box.hide()
            self.search_box.set_no_show_all(True)
            
            # Clear the search entry
            self.search_entry.set_text("")
            
            # Clear current list immediately for better user feedback
            self.liststore.clear()
            
            # Show loading indication with the current mode
            self.status_label.set_text(f"Loading {mode.lower()} applications...")
            
            # Ensure the spinner is visible
            self.spinner.start()
            
            # Force a refresh regardless of loading state
            if self.is_loading:
                # Cancel any current loading operation
                self.is_loading = False
            
            # Directly call load_apps after a brief delay to let UI update
            GLib.timeout_add(100, self._force_refresh)
    
    def _force_refresh(self):
        """Force a refresh of the application list"""
        self.is_loading = True
        thread = threading.Thread(target=self._run_task_thread, args=(self.load_apps, ()))
        thread.daemon = True
        thread.start()
        return False  # Don't repeat

    def on_item_toggled(self, cell, path):
        """Handle checkbox toggle"""
        self.liststore[path][0] = not self.liststore[path][0]
        self.update_status()

    def on_row_activated(self, treeview, path, column):
        """Handle row activation (double-click)"""
        self.liststore[path][0] = not self.liststore[path][0]
        self.update_status()

    def update_status(self):
        """Update the status bar with current selection info"""
        selected_count = sum(1 for row in self.liststore if row[0])
        total_count = len(self.liststore)
        self.status_label.set_text(f"Selected {selected_count} of {total_count} applications")

    def on_action_clicked(self, button):
        """Handle the main action button click"""
        selected = [(row[1], row[2]) for row in self.liststore if row[0]]
        if not selected:
            self.show_message_dialog("Please select at least one application")
            return
            
        if self.add_radio.get_active():
            self.start_background_task(self.process_add_applications, selected)
        else:
            self.start_background_task(self.process_remove_applications, selected)

    def on_select_all_toggled(self, button):
        """Handle select all checkbox toggle"""
        is_active = button.get_active()
        for row in self.liststore:
            row[0] = is_active
        self.update_status()

    def process_add_applications(self, selected):
        """Background task to add applications"""
        os.makedirs(self.ADDED_DIR, exist_ok=True)
        desktop_dir = os.path.join(os.path.expanduser("~"), "Desktop")
        os.makedirs(desktop_dir, exist_ok=True)
        
        for name, filepath in selected:
            new_path = os.path.join(self.ADDED_DIR, os.path.basename(filepath))
            desktop_path = os.path.join(desktop_dir, os.path.basename(filepath))
            
            # Skip if already exists in either location
            if os.path.exists(new_path) or os.path.exists(desktop_path):
                continue
            
            # Build the pdrun command with appropriate flags
            pdrun_cmd = "Exec=pdrun"
            
            # Add --nogpu flag if enabled
            if self.nogpu_action.get_state().get_boolean():
                pdrun_cmd += " --nogpu"
            
            # Copy and modify the file
            shutil.copy(filepath, new_path)
            
            # Read the original desktop file contents
            with open(new_path, "r", encoding="utf-8") as f:
                content = f.read()
                
            # Replace the Exec line with our modified pdrun command
            exec_pattern = re.compile(r'Exec=(.+)')
            
            if exec_pattern.search(content):
                # Extract the original command
                original_cmd = exec_pattern.search(content).group(1)
                
                # Build new command with the original command, but without duplicating "Exec="
                new_cmd = f"pdrun"
                
                # Add --nogpu flag if enabled
                if self.nogpu_action.get_state().get_boolean():
                    new_cmd += " --nogpu"
                
                # Add the original command
                new_cmd += f" {original_cmd}"
                
                # Add --no-sandbox at the end if enabled
                if self.no_sandbox_action.get_state().get_boolean():
                    new_cmd += " --no-sandbox"
                
                # Replace the Exec line
                content = exec_pattern.sub(f"Exec={new_cmd}", content)
                
                # Write the modified content back
                with open(new_path, "w", encoding="utf-8") as f:
                    f.write(content)
            
            # Copy to desktop
            shutil.copy2(new_path, desktop_path)
            os.chmod(desktop_path, 0o755)  # Make executable
        
        # Update system
        self.update_system()
        return len(selected)

    def process_remove_applications(self, selected):
        """Background task to remove applications"""
        desktop_dir = os.path.join(os.path.expanduser("~"), "Desktop")
        
        for _, filepath in selected:
            # Remove from pd_added directory if exists
            if os.path.exists(filepath):
                os.remove(filepath)
            
            # Remove from Desktop directory if exists
            desktop_file = os.path.basename(filepath)
            desktop_filepath = os.path.join(desktop_dir, desktop_file)
            if os.path.exists(desktop_filepath):
                os.remove(desktop_filepath)
        
        # Update system
        self.update_system()
        return len(selected)

    def update_system(self):
        """Update desktop database and icon cache using Gio.Subprocess"""
        # Update desktop database
        launcher = Gio.SubprocessLauncher.new(Gio.SubprocessFlags.NONE)
        launcher.set_cwd(self.APPLICATIONS_DIR)
        launcher.spawnv(["/usr/bin/update-desktop-database", self.APPLICATIONS_DIR])
        
        # Update icon cache
        launcher = Gio.SubprocessLauncher.new(Gio.SubprocessFlags.NONE)
        launcher.spawnv(["/usr/bin/gtk-update-icon-cache", 
                        os.path.join(self.PREFIX, "share/icons/hicolor")])
        
        # Force reload of applications in desktop environment
        launcher = Gio.SubprocessLauncher.new(Gio.SubprocessFlags.NONE)
        launcher.spawnv(["/usr/bin/setsid", "xdg-desktop-menu", "forceupdate"])
        
        # Signal success
        GLib.idle_add(self.show_success_message)
        
        return True

    def show_success_message(self):
        """Show success message and refresh the list"""
        self.show_message_dialog("Operation completed successfully!", "Success")
        
        # Force a refresh of the application list
        self.is_loading = False  # Reset loading state to ensure refresh works
        self._force_refresh()  # Use the same method as when changing modes
        return False

    def show_message_dialog(self, message, title="Notice"):
        """Show a modal dialog with the given message"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.INFO if title == "Success" else Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text=message
        )
        dialog.set_title(title)
        dialog.connect("response", lambda dialog, response: dialog.destroy())
        dialog.show()

    def play_button_visibility_func(self, column, cell, model, iter, data):
        """Only show play button if exec_cmd exists and style the button"""
        exec_cmd = model.get_value(iter, 4)  # Get exec_cmd from column 4
        if exec_cmd and exec_cmd.strip():
            cell.set_property("visible", True)
            
            # Set a nice icon that matches the system theme
            if Gtk.Settings.get_default().get_property("gtk-application-prefer-dark-theme"):
                cell.set_property("icon-name", "media-playback-start-symbolic")
            else:
                cell.set_property("icon-name", "media-playback-start")
        else:
            cell.set_property("visible", False)

    def on_treeview_button_press(self, treeview, event):
        """Handle button press events in the treeview"""
        if event.button == 1:  # Left click
            # Get the path and column at the click position
            pos = treeview.get_path_at_pos(int(event.x), int(event.y))
            if pos is None:
                return False
                
            path, column, _, _ = pos
            
            # Check if the click was on the play button column (last column)
            if column == treeview.get_columns()[-1]:
                # Get the exec command from the model
                model = treeview.get_model()
                exec_cmd = model[path][4]  # Get the exec command
                
                if exec_cmd:
                    # Show visual feedback for the click
                    self.highlight_row_temporarily(treeview, path)
                    
                    # Show a small animation around the play button
                    self.animate_play_button(treeview, path, column)
                    
                    # Run the application
                    self.run_application(exec_cmd)
                    return True
                
            # Check if the click was on the checkbox column
            elif column == treeview.get_columns()[0]:
                model = treeview.get_model()
                model[path][0] = not model[path][0]
                self.update_status()
                return True
                
        return False
    
    def highlight_row_temporarily(self, treeview, path):
        """Temporarily highlight a row to provide visual feedback"""
        selection = treeview.get_selection()
        selection.select_path(path)
        
        # Deselect after a short delay
        GLib.timeout_add(300, lambda: selection.unselect_all() or False)
    
    def animate_play_button(self, treeview, path, column):
        """Create a small animation to visually indicate the app is launching"""
        # Just flash the status bar a different color briefly
        self.status_bar.get_style_context().add_class("launch-flash")
        
        # Reset after a delay
        GLib.timeout_add(400, lambda: self.status_bar.get_style_context().remove_class("launch-flash") or False)
    
    def run_application(self, exec_cmd):
        """Run an application with pdrun"""
        try:
            # Parse the command properly - remove .desktop file field codes
            cleaned_cmd = self.clean_desktop_exec(exec_cmd)
            
            # Check if we're in remove mode
            is_remove_mode = self.remove_radio.get_active()
            
            # In remove mode, we use the command as-is from the desktop file
            if is_remove_mode:
                # If it doesn't start with pdrun, add it
                if not cleaned_cmd.startswith("pdrun "):
                    cmd_parts = ["pdrun"]
                    cmd_parts.extend(cleaned_cmd.split())
                else:
                    # Already has pdrun, just split it for execution
                    cmd_parts = cleaned_cmd.split()
            else:
                # In add mode, construct the command with the current toggle states
                # Remove the pdrun prefix if it exists
                if cleaned_cmd.startswith("pdrun "):
                    # Remove the pdrun prefix since we'll add it again later
                    cleaned_cmd = cleaned_cmd[6:].strip()
                
                # Build the final command with appropriate flags
                cmd_parts = ["pdrun"]
                
                # Add --nogpu if enabled
                if self.nogpu_action.get_state().get_boolean():
                    cmd_parts.append("--nogpu")
                
                # Add the command
                cmd_parts.extend(cleaned_cmd.split())
                
                # Add --no-sandbox if enabled
                if self.no_sandbox_action.get_state().get_boolean():
                    cmd_parts.append("--no-sandbox")
                
                # Convert to absolute path if enabled
                if self.absolute_path_action.get_state().get_boolean():
                    # Find the index of the actual command after pdrun and flags
                    cmd_idx = 1
                    while cmd_idx < len(cmd_parts) and cmd_parts[cmd_idx].startswith("--"):
                        cmd_idx += 1
                    if cmd_idx < len(cmd_parts):
                        cmd_parts[cmd_idx] = self.ensure_absolute_path(cmd_parts[cmd_idx])
            
            # Join the command parts for display and logging
            display_cmd = " ".join(cmd_parts[1:])  # Skip pdrun for display
            
            # Create notification toast
            self.show_launch_notification(display_cmd)
            
            # Prepare the launcher
            launcher = Gio.SubprocessLauncher.new(Gio.SubprocessFlags.STDOUT_SILENCE | 
                                                  Gio.SubprocessFlags.STDERR_SILENCE)
            
            # Launch in background
            subprocess = launcher.spawnv(cmd_parts)
            
            # Log the launch
            print(f"Launched application: {' '.join(cmd_parts)}")
            
        except Exception as e:
            self.show_message_dialog(f"Error launching application: {str(e)}", "Error")
            print(f"Error launching application: {str(e)}")
    
    def ensure_absolute_path(self, cmd):
        """Ensure the command uses absolute paths if possible"""
        parts = cmd.split()
        if not parts:
            return cmd
            
        # Check if the first part is already an absolute path
        if parts[0].startswith('/'):
            # Strip out the distro path prefix for cleaner display
            if parts[0].startswith(self.DISTRO_PATH):
                parts[0] = parts[0].replace(self.DISTRO_PATH, '', 1)
                # Make sure it still starts with a slash
                if not parts[0].startswith('/'):
                    parts[0] = '/' + parts[0]
            return ' '.join(parts)
            
        # Try to find the program in the distro filesystem's common executable locations
        common_paths = [
            "/usr/bin/",
            "/usr/local/bin/",
            "/bin/",
            "/usr/sbin/",
            "/sbin/"
        ]
        
        # Try each common path
        for path in common_paths:
            full_path = os.path.join(self.DISTRO_PATH, path.lstrip('/'), parts[0])
            if os.path.isfile(full_path) and os.access(full_path, os.X_OK):
                # Replace with the full path but strip the distro path prefix
                parts[0] = path + parts[0]
                break
                
        return ' '.join(parts)
    
    def clean_desktop_exec(self, exec_cmd):
        """Clean the Exec command from .desktop file format"""
        # Handle % parameters in .desktop files
        # See: https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#exec-variables
        parts = []
        skip_next = False
        
        for part in exec_cmd.split():
            # Skip parts that are field codes like %f, %F, %u, etc.
            if skip_next:
                skip_next = False
                continue
                
            if part.startswith('%'):
                # Handle special case where % is escaped
                if part == '%%':
                    parts.append('%')
                # Skip field codes
                elif len(part) == 2 and part[1] in "fFuUdDnNickvm":
                    continue
                # Handle parameters to field codes
                elif len(part) > 2 and part[1] in "fFuUdDnNickvm" and part[2] == '=':
                    skip_next = True
                    continue
                else:
                    parts.append(part)
            else:
                parts.append(part)
                
        return ' '.join(parts)
    
    def show_launch_notification(self, cmd):
        """Show a notification that an application is being launched"""
        # Limit command length to prevent UI stretching
        max_length = 50
        if len(cmd) > max_length:
            display_cmd = cmd[:max_length] + "..."
        else:
            display_cmd = cmd
            
        # Update status bar
        self.status_label.set_text(f"Launching: {display_cmd}")
        
        # Reset status after a delay
        GLib.timeout_add(3000, lambda: self.status_label.set_text("Ready") or False)
        
        # Optionally, you could show a toast notification here using a custom popup

    def _delayed_load(self):
        """Start loading apps after a short delay to show the UI first"""
        # Launch initial load in the background
        self.start_background_task(self.load_apps)
        return False  # Don't repeat

    def on_search_changed(self, entry):
        """Handle search entry change"""
        query = entry.get_text().lower()
        self.filter_apps(query)

    def on_search_button_clicked(self, button):
        """Handle search button click"""
        self.on_search_changed(self.search_entry)

    def filter_apps(self, query):
        """Filter the application list based on the search query"""
        # Store the currently selected items for preservation during filtering
        selected_items = {}
        for i, row in enumerate(self.liststore):
            if row[0]:  # If checked
                selected_items[row[1]] = True  # Use app name as key
        
        # Get the current mode
        is_add_mode = self.add_radio.get_active()
        
        # Remember the current spinner state and start it if not already running
        was_loading = self.is_loading
        spinner_active = self.spinner.get_property("active")
        if not spinner_active:
            self.spinner.start()
        
        if not query:
            # If search query is empty, reload the full list
            if not was_loading:
                self.is_loading = False
                self._force_refresh()
            return
        
        # Update status
        self.status_label.set_text(f"Searching for: {query}")
        
        # Create a new list to store filtered results
        filtered_apps = []
        
        # Get the appropriate directory based on mode
        if is_add_mode:
            apps_dir = os.path.join(self.DISTRO_PATH, "usr/share/applications")
        else:
            apps_dir = self.ADDED_DIR
        
        # Perform the search
        for root, _, files in os.walk(apps_dir):
            for file in files:
                if file.endswith(".desktop"):
                    filepath = os.path.join(root, file)
                    try:
                        desktop_entry = self.parse_desktop_file(filepath)
                        if desktop_entry and not desktop_entry.get('no_display', False):
                            app_name = desktop_entry.get('name') or os.path.splitext(file)[0]
                            app_name = app_name.replace("_", " ").strip()
                            
                            # Check if the app matches the search query
                            if query.lower() in app_name.lower() or query.lower() in file.lower():
                                icon = desktop_entry.get('icon') or "application-x-executable"
                                exec_cmd = desktop_entry.get('exec') or ""
                                
                                # Check if the item was previously selected
                                is_selected = app_name in selected_items
                                
                                filtered_apps.append((is_selected, app_name, filepath, icon, exec_cmd))
                    except Exception as e:
                        print(f"Error processing {filepath}: {str(e)}")
        
        # Update the list store with filtered results
        self.liststore.clear()
        for item in sorted(filtered_apps, key=lambda x: x[1].lower()):
            self.liststore.append(item)
        
        # Update status bar
        self.status_label.set_text(f"Found {len(filtered_apps)} apps matching: {query}")
        
        # Stop spinner if it wasn't running before
        if not spinner_active:
            self.spinner.stop()

    def on_search_toggle(self, button):
        """Handle search toggle button click"""
        is_active = button.get_active()
        
        if is_active:
            # First, ensure no_show_all is set to False to allow showing the widget
            self.search_box.set_no_show_all(False)
            # Show the search box and all its children
            self.search_box.show_all()
            # Force UI update immediately
            while Gtk.events_pending():
                Gtk.main_iteration_do(False)
            # Focus on the search field
            self.search_entry.grab_focus()
            # Print debug info
            print("Search bar activated")
        else:
            # Hide search bar and clear search
            self.search_box.hide()
            self.search_entry.set_text("")
            # Set no_show_all back to True
            self.search_box.set_no_show_all(True)
            # Reset filter
            self.filter_apps("")
            # Print debug info
            print("Search bar deactivated")

class Add2MenuApplication(Gtk.Application):
    def __init__(self):
        Gtk.Application.__init__(
            self,
            application_id="org.sabamdarif.termux.add2menu",
            flags=Gio.ApplicationFlags.FLAGS_NONE
        )
        self.window = None
        self.no_sandbox = False  # Default setting for no-sandbox option
        self.use_absolute_path = False  # Default setting for absolute path option
        self.nogpu = False  # Default setting for nogpu option

    def do_startup(self):
        Gtk.Application.do_startup(self)
        
        # Add application actions
        quit_action = Gio.SimpleAction.new("quit", None)
        quit_action.connect("activate", self.on_quit)
        self.add_action(quit_action)
        
        # Add standard application actions
        about_action = Gio.SimpleAction.new("about", None)
        about_action.connect("activate", self.on_about)
        self.add_action(about_action)

        # Add no-sandbox toggle action
        no_sandbox_action = Gio.SimpleAction.new_stateful("no-sandbox", None, 
                                                         GLib.Variant.new_boolean(False))
        no_sandbox_action.connect("change-state", self.on_no_sandbox_toggled)
        self.add_action(no_sandbox_action)
        
        # Add absolute path toggle action
        absolute_path_action = Gio.SimpleAction.new_stateful("absolute-path", None, 
                                                            GLib.Variant.new_boolean(False))
        absolute_path_action.connect("change-state", self.on_absolute_path_toggled)
        self.add_action(absolute_path_action)
        
        # Add nogpu toggle action
        nogpu_action = Gio.SimpleAction.new_stateful("nogpu", None, 
                                                    GLib.Variant.new_boolean(False))
        nogpu_action.connect("change-state", self.on_nogpu_toggled)
        self.add_action(nogpu_action)
        
        # Add keyboard accelerators
        self.set_accels_for_action("app.quit", ["<Ctrl>Q", "<Ctrl>W"])
        
        # Set application name
        GLib.set_application_name("Add To Menu")
        
        # Set the application icon
        icon_theme = Gtk.IconTheme.get_default()
        try:
            icon = icon_theme.load_icon("edit-move", 128, 0)
            Gtk.Window.set_default_icon(icon)
        except Exception as e:
            print(f"Failed to set application icon: {e}")

    def do_activate(self):
        # Get the active window or create a new one
        if not self.window:
            self.window = Add2MenuWindow(self)
        self.window.present()

    def on_quit(self, action, param):
        self.quit()
        
    def on_about(self, action, param):
        """Show about dialog"""
        current_year = datetime.now().year
        
        about_dialog = Gtk.AboutDialog(transient_for=self.window, modal=True)
        about_dialog.set_program_name("Add To Menu")
        about_dialog.set_version("2.1")
        about_dialog.set_comments("A utility to add Linux applications to Termux desktop")
        about_dialog.set_copyright(f"© {current_year} Termux-desktop (sabamdarif)")
        about_dialog.set_license_type(Gtk.License.GPL_3_0)
        about_dialog.set_website("https://github.com/sabamdarif/termux-desktop")
        
        # Connect the response signal to close the dialog
        about_dialog.connect("response", lambda dialog, response: dialog.destroy())
        about_dialog.show()

    def on_no_sandbox_toggled(self, action, value):
        """Handle no-sandbox toggle"""
        action.set_state(value)
        self.no_sandbox = value.get_boolean()
        
    def on_absolute_path_toggled(self, action, value):
        """Handle absolute path toggle"""
        action.set_state(value)
        self.use_absolute_path = value.get_boolean()

    def on_nogpu_toggled(self, action, value):
        """Handle nogpu toggle"""
        action.set_state(value)
        self.nogpu = value.get_boolean()

def main():
    # Make GTK use system's preferred theme
    settings = Gtk.Settings.get_default()
    if settings:
        settings.set_property("gtk-application-prefer-dark-theme", 
                             Gtk.Settings.get_default().get_property("gtk-application-prefer-dark-theme"))
    
    # Create and run the application
    app = Add2MenuApplication()
    return app.run(sys.argv)

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(0)
