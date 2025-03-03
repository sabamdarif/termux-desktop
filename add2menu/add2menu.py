import os
import shutil
import gi
import sys
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib, Gdk, Gio

class Add2MenuWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        Gtk.ApplicationWindow.__init__(
            self,
            application=app,
            title="Add To Menu"
        )
        
        # Set window properties
        self.set_wmclass("add2menu", "Add To Menu")
        self.set_role("add2menu")
        self.set_default_size(600, 500)
        self.set_position(Gtk.WindowPosition.CENTER)
        
        # Constants
        self.PREFIX = os.getenv("PREFIX", "/data/data/com.termux/files/usr")
        self.DISTRO_NAME = os.getenv("distro_name", "debian")
        self.DISTRO_PATH = os.getenv("distro_path", f"/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/{self.DISTRO_NAME}")
        self.APPLICATIONS_DIR = os.path.join(self.PREFIX, "share/applications")
        self.ADDED_DIR = os.path.join(self.APPLICATIONS_DIR, "pd_added")

        # Create pd_added directory if it doesn't exist
        os.makedirs(self.ADDED_DIR, exist_ok=True)

        # Debug print to verify paths
        print(f"Looking for .desktop files in: {os.path.join(self.DISTRO_PATH, 'usr/share/applications')}")
        
        # Setup CSS
        self.setup_css()
        
        # Main container
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(self.main_box)

        # Setup components in correct order
        self.setup_header_bar()
        self.setup_status_bar()
        self.setup_main_content()

        # Initial load
        self.refresh_list()
        
        # Show all widgets
        self.show_all()

    def setup_css(self):
        css = """
            .main-window {
                background-color: #f5f6f7;
            }
            .header-bar {
                background: linear-gradient(to bottom, #2c3e50, #34495e);
                color: white;
                padding: 8px;
            }
            .mode-switch {
                border-radius: 20px;
                padding: 5px 10px;
                background: rgba(255,255,255,0.1);
            }
            .app-list {
                background-color: white;
                border-radius: 5px;
                border: 1px solid #ddd;
                color: #333333;
            }
            .app-list row {
                padding: 8px;
            }
            .app-list row:selected {
                background-color: #3498db;
                color: white;
            }
            .action-button {
                background: linear-gradient(to bottom, #3498db, #2980b9);
                color: white;
                border-radius: 5px;
                padding: 8px 15px;
            }
            .action-button:hover {
                background: linear-gradient(to bottom, #2980b9, #2471a3);
            }
            .status-bar {
                background-color: #f8f9fa;
                border-top: 1px solid #dee2e6;
                padding: 5px;
                color: #333333;
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
        header = Gtk.HeaderBar()
        header.set_show_close_button(True)
        header.get_style_context().add_class('header-bar')
        
        # Mode switch
        mode_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        mode_box.get_style_context().add_class('mode-switch')
        
        self.add_radio = Gtk.RadioButton.new_with_label_from_widget(None, "Add")
        self.remove_radio = Gtk.RadioButton.new_with_label_from_widget(self.add_radio, "Remove")
        self.add_radio.connect("toggled", self.on_mode_changed)
        
        mode_box.pack_start(self.add_radio, False, False, 5)
        mode_box.pack_start(self.remove_radio, False, False, 5)
        
        header.pack_start(mode_box)
        
        # Refresh button
        refresh_button = Gtk.Button()
        refresh_icon = Gio.ThemedIcon(name="view-refresh-symbolic")
        refresh_image = Gtk.Image.new_from_gicon(refresh_icon, Gtk.IconSize.BUTTON)
        refresh_button.add(refresh_image)
        refresh_button.connect("clicked", self.refresh_list)
        header.pack_end(refresh_button)
        
        self.set_titlebar(header)

    def setup_main_content(self):
        # Content area with padding
        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        content_box.set_margin_start(20)
        content_box.set_margin_end(20)
        content_box.set_margin_top(20)
        content_box.set_margin_bottom(20)
        
        # Select all checkbox at top
        self.select_all_check = Gtk.CheckButton(label="Select All")
        self.select_all_check.connect("toggled", self.on_select_all_toggled)
        self.select_all_check.set_halign(Gtk.Align.START)  # Align to the left
        content_box.pack_start(self.select_all_check, False, False, 0)
        
        # Apps list
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        
        self.liststore = Gtk.ListStore(bool, str, str, str)  # checkbox, name, path, icon
        self.treeview = Gtk.TreeView(model=self.liststore)
        self.treeview.get_style_context().add_class('app-list')
        
        # Checkbox column
        renderer_toggle = Gtk.CellRendererToggle()
        renderer_toggle.connect("toggled", self.on_item_toggled)
        column_toggle = Gtk.TreeViewColumn("", renderer_toggle, active=0)
        self.treeview.append_column(column_toggle)
        
        # Icon column
        renderer_icon = Gtk.CellRendererPixbuf()
        column_icon = Gtk.TreeViewColumn("", renderer_icon, icon_name=3)
        self.treeview.append_column(column_icon)
        
        # Name column
        renderer_text = Gtk.CellRendererText()
        renderer_text.set_property("ellipsize", "end")
        column_text = Gtk.TreeViewColumn("Application", renderer_text, text=1)
        column_text.set_expand(True)
        column_text.set_clickable(True)
        column_text.connect("clicked", self.on_column_clicked)
        
        self.treeview.append_column(column_text)
        
        # Connect single click handler
        self.treeview.connect("button-press-event", self.on_single_click)
        
        scroll.add(self.treeview)
        content_box.pack_start(scroll, True, True, 0)
        
        # Action button
        button_box = Gtk.Box(spacing=6)
        button_box.set_halign(Gtk.Align.END)
        
        self.action_button = Gtk.Button.new_with_label("Add Selected")
        self.action_button.get_style_context().add_class('action-button')
        self.action_button.connect("clicked", self.on_action_clicked)
        button_box.pack_start(self.action_button, False, False, 0)
        
        content_box.pack_start(button_box, False, False, 0)
        self.main_box.pack_start(content_box, True, True, 0)

    def setup_status_bar(self):
        self.status_bar = Gtk.Statusbar()
        self.status_bar.get_style_context().add_class('status-bar')
        self.main_box.pack_start(self.status_bar, False, False, 0)

    def list_desktop_files(self, directory):
        desktop_files = []
        if not os.path.exists(directory):
            print(f"Directory does not exist: {directory}")
            return desktop_files
            
        print(f"Scanning directory: {directory}")
        for root, _, files in os.walk(directory):
            print(f"Found files: {files}")
            for file in files:
                if file.endswith(".desktop"):
                    filepath = os.path.join(root, file)
                    try:
                        name = None
                        generic_name = None
                        icon = None
                        no_display = False
                        
                        with open(filepath, "r", encoding="utf-8") as f:
                            content = f.read()
                            for line in content.splitlines():
                                if line.startswith("Name[") and not name:
                                    name = line.split("=", 1)[1].strip()
                                elif line.startswith("Name=") and not name:
                                    name = line.split("=", 1)[1].strip()
                                elif line.startswith("GenericName=") and not generic_name:
                                    generic_name = line.split("=", 1)[1].strip()
                                elif line.startswith("Icon="):
                                    icon_name = line.split("=", 1)[1].strip()
                                    # Handle different icon formats
                                    if icon_name.endswith('.png') or icon_name.endswith('.svg'):
                                        icon = icon_name
                                    else:
                                        # Try different icon names and themes
                                        possible_icons = [
                                            icon_name,
                                            f"{icon_name}-symbolic",
                                            f"application-x-{icon_name}",
                                            f"{icon_name.lower()}",
                                            f"applications-{icon_name.lower()}"
                                        ]
                                        icon = self.find_icon(possible_icons)
                                elif line.startswith("NoDisplay=") and "true" in line.lower():
                                    no_display = True
                                    break
                        
                        if not no_display:
                            display_name = name or generic_name or os.path.splitext(file)[0]
                            display_name = display_name.replace("_", " ").strip()
                            print(f"Found application: {display_name} with icon: {icon}")
                            desktop_files.append((display_name, filepath, icon))
                    except Exception as e:
                        print(f"Error processing {filepath}: {str(e)}")
                        
        return desktop_files

    def find_icon(self, icon_names):
        # Common icon paths in the distro
        icon_paths = [
            os.path.join(self.DISTRO_PATH, "usr/share/icons"),
            os.path.join(self.DISTRO_PATH, "usr/share/pixmaps"),
            os.path.join(self.PREFIX, "share/icons"),
            "/usr/share/icons"
        ]
        
        # Common icon themes
        icon_themes = ["hicolor", "Adwaita", "gnome", "breeze", "oxygen"]
        
        # Common icon sizes
        icon_sizes = ["48x48", "32x32", "24x24", "16x16"]
        
        # Common icon categories
        icon_categories = ["apps", "applications", "mimetypes", "categories"]

        for icon_name in icon_names:
            # First check if it's a full path
            if os.path.isfile(icon_name):
                return icon_name
                
            # Then check common locations
            for icon_path in icon_paths:
                for theme in icon_themes:
                    for size in icon_sizes:
                        for category in icon_categories:
                            # Check PNG
                            icon_file = os.path.join(icon_path, theme, size, category, f"{icon_name}.png")
                            if os.path.isfile(icon_file):
                                return icon_name
                            
                            # Check SVG
                            icon_file = os.path.join(icon_path, theme, "scalable", category, f"{icon_name}.svg")
                            if os.path.isfile(icon_file):
                                return icon_name
                                
            # Check pixmaps directory
            for icon_path in icon_paths:
                pixmaps = os.path.join(icon_path, "..", "pixmaps")
                for ext in [".png", ".svg", ".xpm"]:
                    icon_file = os.path.join(pixmaps, f"{icon_name}{ext}")
                    if os.path.isfile(icon_file):
                        return icon_name
        
        # If no specific icon is found, try some fallbacks
        fallbacks = [
            "application-x-executable",
            "applications-office",
            "applications-other",
            "application-default-icon"
        ]
        
        for fallback in fallbacks:
            for icon_path in icon_paths:
                for theme in icon_themes:
                    for size in icon_sizes:
                        icon_file = os.path.join(icon_path, theme, size, "apps", f"{fallback}.png")
                        if os.path.isfile(icon_file):
                            return fallback
        
        # Final fallback
        return "application-x-executable"

    def refresh_list(self, widget=None):
        self.liststore.clear()
        
        if self.add_radio.get_active():
            path = os.path.join(self.DISTRO_PATH, "usr/share/applications")
            self.action_button.set_label("Add Selected")
        else:
            path = self.ADDED_DIR
            self.action_button.set_label("Remove Selected")
            
        print(f"Refreshing list from path: {path}")
        apps = self.list_desktop_files(path)
        print(f"Found {len(apps)} applications")
        
        for name, filepath, icon in sorted(apps, key=lambda x: x[0].lower()):
            self.liststore.append([False, name, filepath, icon or "application-x-executable"])
            
        self.update_status()

    def on_mode_changed(self, button):
        self.refresh_list()

    def on_item_toggled(self, cell, path):
        self.liststore[path][0] = not self.liststore[path][0]
        self.update_status()

    def update_status(self):
        selected_count = sum(1 for row in self.liststore if row[0])
        total_count = len(self.liststore)
        self.status_bar.push(0, f"Selected {selected_count} of {total_count} applications")

    def on_action_clicked(self, button):
        selected = [(row[1], row[2]) for row in self.liststore if row[0]]
        if not selected:
            self.show_message_dialog("Please select at least one application")
            return
            
        if self.add_radio.get_active():
            self.add_applications(selected)
        else:
            self.remove_applications(selected)

    def on_select_all_toggled(self, button):
        is_active = button.get_active()
        for row in self.liststore:
            row[0] = is_active
        self.update_status()

    def add_applications(self, selected):
        try:
            os.makedirs(self.ADDED_DIR, exist_ok=True)
            desktop_dir = os.path.join(os.path.expanduser("~"), "Desktop")
            
            for name, filepath in selected:
                new_path = os.path.join(self.ADDED_DIR, os.path.basename(filepath))
                desktop_path = os.path.join(desktop_dir, os.path.basename(filepath))
                
                # Skip if already exists in either location
                if os.path.exists(new_path) or os.path.exists(desktop_path):
                    print(f"Skipping {name} - already exists")
                    continue
                
                # Copy and modify the file
                shutil.copy(filepath, new_path)
                with open(new_path, "r+") as f:
                    content = f.read()
                    content = content.replace("Exec=", "Exec=pdrun ")
                    f.seek(0)
                    f.write(content)
                    f.truncate()
                
                # Copy to desktop
                shutil.copy2(new_path, desktop_path)
                os.chmod(desktop_path, 0o755)  # Make executable
                
            self.update_system_and_show_success()
        except Exception as e:
            self.show_message_dialog(f"Error adding applications: {str(e)}", "Error")
            print(f"Error adding applications: {str(e)}")

    def remove_applications(self, selected):
        try:
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
                    
            self.update_system_and_show_success()
        except Exception as e:
            self.show_message_dialog(f"Error removing applications: {str(e)}", "Error")
            print(f"Error removing applications: {str(e)}")

    def update_system_and_show_success(self):
        try:
            # Update desktop database
            os.system(f"update-desktop-database {self.APPLICATIONS_DIR}")
            
            # Update icon cache
            os.system(f"gtk-update-icon-cache {self.PREFIX}/share/icons/hicolor")
            
            # Force reload of applications in desktop environment
            os.system("setsid xdg-desktop-menu forceupdate &> /dev/null")  # Generic XDG update
            
            # Create .desktop files in Desktop directory
            desktop_dir = os.path.join(os.path.expanduser("~"), "Desktop")
            os.makedirs(desktop_dir, exist_ok=True)
            
            # Copy all .desktop files from pd_added to Desktop
            for desktop_file in os.listdir(self.ADDED_DIR):
                if desktop_file.endswith('.desktop'):
                    src = os.path.join(self.ADDED_DIR, desktop_file)
                    dst = os.path.join(desktop_dir, desktop_file)
                    shutil.copy2(src, dst)
                    os.chmod(dst, 0o755)  # Make executable
            
            # Notify user
            self.show_message_dialog("Operation completed successfully!", "Success")
            
            # Refresh our list
            self.refresh_list()
            
        except Exception as e:
            self.show_message_dialog(f"Error updating system: {str(e)}", "Error")
            print(f"Error updating system: {str(e)}")

    def show_message_dialog(self, message, title="Notice"):
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.INFO if title == "Success" else Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text=message
        )
        dialog.set_title(title)
        dialog.run()
        dialog.destroy()

    def on_single_click(self, treeview, event):
        if event.button == 1:  # Left click
            path = treeview.get_path_at_pos(int(event.x), int(event.y))
            if path is not None:
                path = path[0]  # Get the path from the tuple
                model = treeview.get_model()
                model[path][0] = not model[path][0]
                self.update_status()
                return True
        return False

    def on_column_clicked(self, column):
        self.liststore.set_sort_column_id(1, Gtk.SortType.ASCENDING)

class Add2MenuApplication(Gtk.Application):
    def __init__(self):
        Gtk.Application.__init__(
            self,
            application_id="org.sabamdarif.termux.add2menu",
            flags=Gio.ApplicationFlags.FLAGS_NONE
        )
        self.window = None

    def do_startup(self):
        Gtk.Application.do_startup(self)
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
        if not self.window:
            self.window = Add2MenuWindow(self)
        self.window.present()

def main():
    app = Add2MenuApplication()
    return app.run(sys.argv)

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(0)
