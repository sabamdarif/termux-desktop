#!/usr/bin/env python3

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib, GdkPixbuf, Pango, Gio
import os
import json
import subprocess
from pathlib import Path
import stat
import time
from datetime import datetime, timedelta
import threading
import sys
import queue
import shutil
from PIL import Image
import platform

# Termux-specific paths
TERMUX_PREFIX = "/data/data/com.termux/files/usr"
TERMUX_TMP = os.path.join(TERMUX_PREFIX, "tmp")

# App store paths
APPSTORE_DIR = os.path.expanduser("~/.appstore")
APPSTORE_LOGO_DIR = os.path.join(APPSTORE_DIR, "logo")
APPSTORE_JSON = os.path.join(APPSTORE_DIR, "apps.json")
LAST_REFRESH_FILE = os.path.join(APPSTORE_DIR, "last_refresh")
GITHUB_APPS_JSON = "https://raw.githubusercontent.com/sabamdarif/Termux-AppStore/main/data/apps.json"

# Function to validate logo size
def validate_logo_size(logo_path):
    """Check if the logo is within the required size range."""
    try:
        with Image.open(logo_path) as img:
            width, height = img.size
            if 20 <= width <= 180 and 20 <= height <= 180:
                return True
            else:
                print(f"Logo for {os.path.basename(logo_path)} is not within the required size range (20x20 to 180x180).")
                return False
    except Exception as e:
        print(f"Error validating logo size for {logo_path}: {e}")
        return False

class AppStoreApplication(Gtk.Application):
    def __init__(self):
        Gtk.Application.__init__(
            self,
            application_id="org.sabamdarif.termux.appstore",
            flags=Gio.ApplicationFlags.FLAGS_NONE
        )
        self.window = None

    def do_startup(self):
        Gtk.Application.do_startup(self)
        # Set application name
        GLib.set_application_name("Termux AppStore")
        # Set the application icon
        icon_theme = Gtk.IconTheme.get_default()
        try:
            icon = icon_theme.load_icon("org.gnome.Software", 128, 0)
            Gtk.Window.set_default_icon(icon)
        except Exception as e:
            print(f"Failed to set application icon: {e}")

    def do_activate(self):
        if not self.window:
            self.window = AppStoreWindow(self)
        self.window.present()

class AppStoreWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        Gtk.ApplicationWindow.__init__(
            self,
            application=app,
            title="Termux AppStore"
        )
        
        # Set window properties
        self.set_wmclass("termux-appstore", "Termux AppStore")
        self.set_role("termux-appstore")
        self.set_default_size(1000, 600)
        self.set_position(Gtk.WindowPosition.CENTER)
        
        # Initialize installation flags
        self.installation_cancelled = False
        self.uninstallation_cancelled = False

        # Get system architecture
        self.system_arch = platform.machine().lower()
        print(f"System architecture: {self.system_arch}")
        
        # Define architecture compatibility groups
        self.arch_compatibility = {
            'arm64': ['arm64', 'aarch64'],
            'aarch64': ['arm64', 'aarch64'],
            'arm': ['arm', 'armhf', 'armv7', 'armv7l', 'armv7a'],
            'armv7l': ['arm', 'armhf', 'armv7', 'armv7l', 'armv7a'],
            'armhf': ['arm', 'armhf', 'armv7', 'armv7l', 'armv7a']
        }

        # Add keyboard accelerators
        accel = Gtk.AccelGroup()
        self.add_accel_group(accel)
        
        # Add Ctrl+Q shortcut
        key, mod = Gtk.accelerator_parse("<Control>Q")
        accel.connect(key, mod, Gtk.AccelFlags.VISIBLE, self.on_quit_accelerator)

        # Initialize stop flag for background tasks
        self.stop_background_tasks = False

        # Initialize task queue and current task
        self.task_queue = queue.Queue()
        self.current_task = None

        # Start task processor
        self.start_task_processor()

        # Connect the delete-event to handle window closing
        self.connect("delete-event", self.on_delete_event)

        # Initialize paths and create directories
        self.setup_directories()

        # Initialize installed apps tracking
        self.installed_apps_file = Path(os.path.expanduser("~/.termux_appstore/installed_apps.json"))
        self.installed_apps_file.parent.mkdir(parents=True, exist_ok=True)
        self.load_installed_apps()

        # Initialize categories and apps data
        self.categories = []
        self.apps_data = []

        # Load CSS
        css_provider = Gtk.CssProvider()
        css_file = Path(__file__).parent / 'style' / 'style.css'
        # css_file = Path("/data/data/com.termux/files/usr/opt/appstore/style/style.css")
        css_provider.load_from_path(str(css_file))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        # Create main container with overlay
        self.overlay = Gtk.Overlay()
        self.add(self.overlay)

        # Create main content box
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.overlay.add(self.main_box)

        # Create spinner for initial load
        self.spinner = Gtk.Spinner()
        self.spinner.set_size_request(64, 64)

        # Create a label for the loading message
        self.loading_label = Gtk.Label(label="This process will take some time. Please wait...")
        self.loading_label.set_halign(Gtk.Align.CENTER)
        self.loading_label.hide()  # Initially hide the loading label

        spinner_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        spinner_box.pack_start(self.spinner, True, True, 0)
        spinner_box.pack_start(self.loading_label, True, True, 0)  # Add label to the spinner box
        spinner_box.set_valign(Gtk.Align.CENTER)
        spinner_box.set_halign(Gtk.Align.CENTER)
        self.overlay.add_overlay(spinner_box)

        # Create header bar
        header = Gtk.HeaderBar()
        header.set_show_close_button(True)
        header.props.title = "Termux App Store"
        self.set_titlebar(header)

        # Add refresh button to header
        self.refresh_button = Gtk.Button()
        self.refresh_button.set_tooltip_text("Refresh App List")
        refresh_icon = Gtk.Image.new_from_icon_name("view-refresh-symbolic", Gtk.IconSize.BUTTON)
        self.refresh_button.add(refresh_icon)
        self.refresh_button.connect("clicked", self.on_refresh_clicked)
        header.pack_end(self.refresh_button)

        # Create content box for app list
        self.content_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.main_box.pack_start(self.content_box, True, True, 0)

        # Show all widgets
        self.show_all()

        # Start the initial data load
        self.check_for_updates()

    def setup_directories(self):
        """Create necessary directories for the app store"""
        os.makedirs(APPSTORE_DIR, exist_ok=True)
        os.makedirs(APPSTORE_LOGO_DIR, exist_ok=True)

    def check_for_updates(self):
        print('Checking for updates...')  # Log when checking for updates
        """Check if updates are needed based on last refresh time"""
        try:
            # Show loading indicators at the start of the check
            self.spinner.show()
            self.spinner.start()
            self.loading_label.show()

            # Check if apps.json exists
            if not os.path.exists(APPSTORE_JSON):
                self.start_refresh()
                return

            # Check last refresh time
            if os.path.exists(LAST_REFRESH_FILE):
                with open(LAST_REFRESH_FILE, 'r') as f:
                    last_refresh = datetime.fromtimestamp(float(f.read().strip()))
                    if datetime.now() - last_refresh > timedelta(days=7):
                        self.start_refresh()
                    else:
                        # Load existing data without refresh in a background thread
                        thread = threading.Thread(target=self.load_app_metadata_and_setup_ui)
                        thread.daemon = True
                        thread.start()
            else:
                self.start_refresh()
        except (FileNotFoundError, ValueError) as e:
            print(f"Error checking updates: {e}")
            self.start_refresh()

    def load_app_metadata_and_setup_ui(self):
        """Load app metadata and set up UI in the background"""
        self.load_app_metadata()
        GLib.idle_add(self.setup_app_list_ui)
        GLib.idle_add(self.hide_loading_indicators)  # Add this line to hide both spinner and label

    def hide_loading_indicators(self):
        """Hide both spinner and loading label"""
        self.spinner.stop()
        self.spinner.hide()
        self.loading_label.hide()
        return False

    def start_refresh(self):
        """Start the refresh process in a background thread"""
        print("\nStarting refresh process...")
        
        # Clear existing content
        for child in self.content_box.get_children():
            child.destroy()

        # Show and start spinner
        self.spinner.show()
        self.spinner.start()
        self.loading_label.show()
        self.refresh_button.set_sensitive(False)

        # Start background thread for downloading
        thread = threading.Thread(target=self.refresh_data_background)
        thread.daemon = True
        thread.start()

    def refresh_data_background(self):
        """Run refresh in background thread"""
        try:
            print("\nStarting refresh process...")
            
            # Step 1: Wait briefly to ensure any previous download is complete
            time.sleep(1)
            
            # Step 2: Check and backup existing apps.json
            if os.path.exists(APPSTORE_JSON):
                print(f"Found existing apps.json at: {APPSTORE_JSON}")
                
                # Create old_json directory if it doesn't exist
                old_json_dir = os.path.join(APPSTORE_DIR, 'old_json')
                os.makedirs(old_json_dir, exist_ok=True)
                
                # Remove old backup if it exists
                old_json_path = os.path.join(old_json_dir, 'apps.json')
                if os.path.exists(old_json_path):
                    print(f"Removing old backup at: {old_json_path}")
                    os.remove(old_json_path)
                
                # Create new backup
                print(f"Creating backup at: {old_json_path}")
                shutil.copy2(APPSTORE_JSON, old_json_path)
                
                # Verify backup was created
                if os.path.exists(old_json_path):
                    print("Backup created successfully")
                    # Only remove original after successful backup
                    os.remove(APPSTORE_JSON)
                    print(f"Removed original apps.json at: {APPSTORE_JSON}")
            else:
                print("No existing apps.json found to backup")

            # Step 3: Clean up logo directory
            if os.path.exists(APPSTORE_LOGO_DIR):
                print(f"Cleaning up logo directory: {APPSTORE_LOGO_DIR}")
                shutil.rmtree(APPSTORE_LOGO_DIR)
                os.makedirs(APPSTORE_LOGO_DIR)

            # Step 4: Download new apps.json
            print("Downloading new apps.json...")
            command = f"aria2c -x 16 -s 16 {GITHUB_APPS_JSON} -d {APPSTORE_DIR} -o apps.json"
            result = os.system(command)
            if result != 0:
                print("Error downloading apps.json. Please check the URL or your connection.")
                GLib.idle_add(self.refresh_error, "Failed to download apps.json")
                return False

            # Rest of the download and processing code...
            with open(APPSTORE_JSON, 'r') as f:
                try:
                    all_apps = json.load(f)
                    
                    # Get compatible architectures for the system
                    compatible_archs = self.arch_compatibility.get(self.system_arch, [self.system_arch])
                    print(f"System architecture: {self.system_arch}")
                    print(f"Compatible architectures: {compatible_archs}")
                    
                    # Filter apps based on architecture compatibility
                    self.apps_data = []
                    for app in all_apps:
                        app_arch = app.get('supported_arch', '')
                        if not app_arch:  # If no architecture specified, assume compatible
                            self.apps_data.append(app)
                            continue
                            
                        # Split and clean architecture strings
                        supported_archs = [arch.strip().lower() for arch in app_arch.split(',')]
                        
                        # Check if any of the app's architectures are compatible
                        if any(arch in compatible_archs for arch in supported_archs):
                            self.apps_data.append(app)
                            print(f"Added compatible app: {app['app_name']} ({app_arch})")
                        else:
                            print(f"Skipped incompatible app: {app['app_name']} ({app_arch})")
                    
                    print(f"Loaded {len(self.apps_data)} compatible apps out of {len(all_apps)} total apps")
                    
                    # Download logos for compatible apps
                    for app in self.apps_data:
                        if self.stop_background_tasks:
                            return False

                        logo_dir = os.path.join(APPSTORE_LOGO_DIR, app['folder_name'])
                        os.makedirs(logo_dir, exist_ok=True)

                        print(f"Downloading logo for {app['app_name']}...")
                        logo_path = os.path.join(logo_dir, 'logo.png')
                        command = f"aria2c -x 16 -s 16 {app['logo_url']} -d {logo_dir} -o logo.png"
                        os.system(command)

                        # Validate the logo size
                        if not validate_logo_size(logo_path):
                            continue

                    print("Refresh completed successfully!")

                    # Update last refresh time
                    with open(LAST_REFRESH_FILE, 'w') as f:
                        f.write(str(time.time()))

                    # Update UI in main thread
                    if not self.stop_background_tasks:
                        GLib.idle_add(self.refresh_complete)

                except json.JSONDecodeError as e:
                    print(f"Failed to decode JSON: {str(e)}")
                    GLib.idle_add(self.refresh_error, str(e))
                    return False

        except Exception as e:
            print(f"Error during refresh: {e}")
            import traceback
            traceback.print_exc()
            if not self.stop_background_tasks:
                GLib.idle_add(self.refresh_error, str(e))

        return False

    def refresh_complete(self):
        print('Refresh complete!')  # Log when refresh is complete
        """Called when refresh is complete"""
        
        # Load app metadata first
        self.load_app_metadata()
        
        # Clear current content
        for child in self.content_box.get_children():
            child.destroy()
        
        # Hide loading indicators
        self.spinner.stop()
        self.spinner.hide()
        self.loading_label.hide()
        self.refresh_button.set_sensitive(True)

        # Setup UI with the new data
        self.setup_app_list_ui()
        
        return False

    def load_installed_apps(self):
        """Load the list of installed apps"""
        try:
            if os.path.exists(self.installed_apps_file):
                with open(self.installed_apps_file) as f:
                    self.installed_apps = json.load(f)
            else:
                self.installed_apps = []
                self.save_installed_apps()
        except (FileNotFoundError, json.JSONDecodeError):
            self.installed_apps = []
            self.save_installed_apps()

    def save_installed_apps(self):
        """Save the list of installed apps"""
        with open(self.installed_apps_file, 'w') as f:
            json.dump(self.installed_apps, f, indent=2)

    def update_installation_status(self, app_name, installed):
        """Update the installation status of an app"""
        if installed and app_name not in self.installed_apps:
            self.installed_apps.append(app_name)
        elif not installed and app_name in self.installed_apps:
            self.installed_apps.remove(app_name)
        self.save_installed_apps()
        GLib.idle_add(self.show_apps)

    def is_arch_compatible(self, app_arch):
        """Check if the app's architecture is compatible with the system"""
        if not app_arch:  # If no architecture specified, assume compatible
            return True
            
        # Split multiple architectures if present
        supported_archs = [arch.strip().lower() for arch in app_arch.split(',')]
        
        # Get compatible architectures for the system
        compatible_archs = self.arch_compatibility.get(self.system_arch, [self.system_arch])
        
        # Check if any of the app's supported architectures match the system's compatible ones
        return any(arch in compatible_archs for arch in supported_archs)

    def load_app_metadata(self):
        """Load app metadata from the centralized JSON file"""
        try:
            with open(APPSTORE_JSON) as f:
                all_apps = json.load(f)
                
            # Get compatible architectures for the system
            compatible_archs = self.arch_compatibility.get(self.system_arch, [self.system_arch])
            print(f"System architecture: {self.system_arch}")
            print(f"Compatible architectures: {compatible_archs}")
            
            # Filter apps based on architecture compatibility
            self.apps_data = []
            for app in all_apps:
                app_arch = app.get('supported_arch', '')
                if not app_arch:  # If no architecture specified, assume compatible
                    self.apps_data.append(app)
                    continue
                    
                # Split and clean architecture strings
                supported_archs = [arch.strip().lower() for arch in app_arch.split(',')]
                
                # Check if any of the app's architectures are compatible
                if any(arch in compatible_archs for arch in supported_archs):
                    self.apps_data.append(app)
                    print(f"Added compatible app: {app['app_name']} ({app_arch})")
                else:
                    print(f"Skipped incompatible app: {app['app_name']} ({app_arch})")
            
            # Extract categories from filtered apps
            self.categories = sorted(list(set(
                cat for app in self.apps_data
                for cat in app['categories']
            )))
            
            print(f"Loaded {len(self.apps_data)} compatible apps out of {len(all_apps)} total apps")
            
        except FileNotFoundError:
            self.apps_data = []
            self.categories = []
            print("No apps.json file found")
        except Exception as e:
            print(f"Error loading app metadata: {e}")
            self.apps_data = []
            self.categories = []

    def setup_app_list_ui(self):
        """Set up the main app list UI"""
        # Left panel - Categories
        sidebar = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        sidebar.set_size_request(200, -1)
        sidebar.set_margin_start(10)
        sidebar.set_margin_end(10)
        sidebar.set_margin_top(10)
        self.content_box.pack_start(sidebar, False, True, 0)

        # Category list
        categories_label = Gtk.Label()
        categories_label.set_markup("<b>Categories</b>")
        categories_label.set_xalign(0)
        categories_label.set_margin_start(10)
        categories_label.set_margin_top(10)
        categories_label.set_margin_bottom(10)
        sidebar.pack_start(categories_label, False, True, 0)

        # Add "All Apps" button first
        all_button = Gtk.Button(label="All Apps")
        all_button.connect("clicked", self.on_category_clicked)
        all_button.set_size_request(-1, 40)
        all_button.get_style_context().add_class("category-button")
        sidebar.pack_start(all_button, False, True, 0)

        # Category buttons
        self.category_buttons = [all_button]
        for category in sorted(self.categories):
            button = Gtk.Button(label=category)
            button.connect("clicked", self.on_category_clicked)
            button.set_size_request(-1, 40)
            button.get_style_context().add_class("category-button")
            sidebar.pack_start(button, False, True, 0)
            self.category_buttons.append(button)

        # Right panel - App list
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.content_box.pack_start(scrolled, True, True, 0)

        # Container for search and app list
        right_panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        right_panel.set_margin_start(10)
        right_panel.set_margin_end(10)
        right_panel.set_margin_top(10)
        scrolled.add(right_panel)

        # Add search entry at the top of app list
        search_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.search_entry = Gtk.SearchEntry()
        self.search_entry.set_placeholder_text("Search apps...")
        self.search_entry.connect("search-changed", self.on_search_changed)
        self.search_entry.set_size_request(-1, 40)
        search_box.pack_start(self.search_entry, True, True, 0)
        right_panel.pack_start(search_box, False, True, 0)

        # App list box
        self.app_list_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        right_panel.pack_start(self.app_list_box, True, True, 0)

        # Show all apps initially
        self.show_apps()
        self.content_box.show_all()

    def on_category_clicked(self, button):
        # Update selected state of category buttons
        for btn in self.category_buttons:
            btn.get_style_context().remove_class('selected')
        button.get_style_context().add_class('selected')

        category = button.get_label()
        # Clear search when changing categories
        self.search_entry.set_text("")
        self.show_apps(category)

    def on_refresh_clicked(self, button):
        """Handle refresh button click"""
        # Delete apps.json and logo folder
        if os.path.exists(APPSTORE_JSON):
            os.remove(APPSTORE_JSON)
        if os.path.exists(APPSTORE_LOGO_DIR):
            shutil.rmtree(APPSTORE_LOGO_DIR)

        # Start the refresh process
        self.start_refresh()

    def show_error_dialog(self, message):
        """Show an error dialog with the given message"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text=message
        )
        dialog.run()
        dialog.destroy()

    def on_install_clicked(self, button, app):
        """Handle install button click"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            modal=True,
            message_type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.YES_NO,
            text=f"Install {app['app_name']}?"
        )
        response = dialog.run()
        dialog.destroy()

        if response == Gtk.ResponseType.YES:
            # Create progress dialog with fixed width but expandable height
            progress_dialog = Gtk.Dialog(
                title="Installing...",
                parent=self,
                modal=True
            )
            progress_dialog.set_default_size(350, 150)  # Set initial size
            progress_dialog.set_resizable(True)  # Allow resizing
            
            # Add minimize button to titlebar
            header = Gtk.HeaderBar()
            header.set_show_close_button(False)
            minimize_button = Gtk.Button()
            minimize_button.set_relief(Gtk.ReliefStyle.NONE)
            minimize_icon = Gtk.Image.new_from_icon_name("window-minimize", Gtk.IconSize.MENU)
            minimize_button.add(minimize_icon)
            minimize_button.connect("clicked", lambda x: progress_dialog.iconify())
            header.pack_end(minimize_button)
            progress_dialog.set_titlebar(header)
            
            # Add cancel button and connect to response signal
            cancel_button = progress_dialog.add_button("Cancel", Gtk.ResponseType.CANCEL)
            
            vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
            vbox.set_margin_start(10)
            vbox.set_margin_end(10)
            vbox.set_margin_top(10)
            vbox.set_margin_bottom(10)
            
            # Status label with better text handling
            status_label = Gtk.Label()
            status_label.set_line_wrap(True)
            status_label.set_line_wrap_mode(Gtk.WrapMode.WORD_CHAR)
            status_label.set_justify(Gtk.Justification.LEFT)
            status_label.set_halign(Gtk.Align.START)
            status_label.set_text("Starting installation...")
            
            # Create a scrolled window for status label that expands
            scroll = Gtk.ScrolledWindow()
            scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
            scroll.set_size_request(-1, 80)  # Minimum height
            scroll.add(status_label)
            vbox.pack_start(scroll, True, True, 0)  # Allow vertical expansion
            
            # Progress bar that expands horizontally
            progress_bar = Gtk.ProgressBar()
            progress_bar.set_show_text(True)
            progress_bar.set_size_request(300, -1)
            vbox.pack_start(progress_bar, False, True, 0)
            
            progress_dialog.get_content_area().add(vbox)
            progress_dialog.show_all()

            # Track current process and script path
            current_process = {'process': None}
            script_path = [None]  # Use list to allow modification in nested functions

            def on_cancel_clicked(dialog, response_id):
                if response_id == Gtk.ResponseType.CANCEL:
                    # Set cancellation flag
                    self.installation_cancelled = True
                    
                    # Terminate current process if it exists
                    if current_process['process']:
                        try:
                            current_process['process'].terminate()
                            current_process['process'].wait()
                        except:
                            pass  # Process might have already ended
                    
                    # Clean up script if it exists
                    if script_path[0] and os.path.exists(script_path[0]):
                        try:
                            os.remove(script_path[0])
                        except:
                            pass
                    
                    dialog.destroy()

            # Connect the response signal
            progress_dialog.connect('response', on_cancel_clicked)

            def update_progress(fraction, status_text):
                if not status_text:
                    return False
                
                # Parse aria2c download progress format
                if '[#' in status_text and ']' in status_text:
                    # Extract progress details from aria2c output
                    progress_part = status_text[status_text.find('['):status_text.find(']')+1]
                    file_part = status_text[status_text.find(']')+1:].strip()
                    
                    # Format the status text to show both progress and file
                    status_label.set_text(f"{progress_part}\n{file_part}")
                elif isinstance(status_text, str) and status_text.strip() and not all(c in '-' for c in status_text.strip()):
                    status_label.set_text(status_text)
                
                progress_bar.set_fraction(fraction)
                progress_bar.set_text(f"{int(fraction * 100)}%")
                return False

            def install_thread():
                try:
                    # Download script (20%)
                    GLib.idle_add(update_progress, 0.2, "Downloading install script...")
                    script_path[0] = self.download_script(app['install_url'])
                    if not script_path[0] or self.installation_cancelled:
                        if script_path[0] and os.path.exists(script_path[0]):
                            os.remove(script_path[0])
                        GLib.idle_add(progress_dialog.destroy)
                        return

                    # Make script executable (30%)
                    GLib.idle_add(update_progress, 0.3, "Preparing installation...")
                    os.chmod(script_path[0], os.stat(script_path[0]).st_mode | stat.S_IEXEC)

                    # Execute script with better progress tracking
                    GLib.idle_add(update_progress, 0.4, "Starting installation...")
                    process = subprocess.Popen(
                        ['bash', script_path[0]],
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        universal_newlines=True,
                        bufsize=1
                    )
                    
                    # Store process reference for cancellation
                    current_process['process'] = process

                    for line in process.stdout:
                        if self.installation_cancelled:
                            process.terminate()
                            process.wait()
                            GLib.idle_add(progress_dialog.destroy)
                            return

                        line = line.strip()
                        progress = 0.4

                        # Update progress based on specific actions
                        if "download" in line.lower():
                            progress = 0.5
                        elif "extracting" in line.lower() or "tar" in line.lower():
                            progress = 0.7
                        elif "installing" in line.lower():
                            progress = 0.8
                        elif "creating desktop entry" in line.lower():
                            progress = 0.9

                        if line:  # Only update if line is not empty
                            GLib.idle_add(update_progress, progress, line)

                    process.wait()
                    if process.returncode == 0 and not self.installation_cancelled:
                        GLib.idle_add(update_progress, 0.95, "Finalizing installation...")
                        GLib.idle_add(lambda: self.update_installation_status(app['folder_name'], True))
                        time.sleep(0.5)
                        GLib.idle_add(update_progress, 1.0, "Installation complete!")
                        time.sleep(1)
                        GLib.idle_add(progress_dialog.destroy)
                    else:
                        GLib.idle_add(update_progress, 1.0, "Installation failed!")
                        time.sleep(2)
                        GLib.idle_add(progress_dialog.destroy)

                except Exception as e:
                    print(f"Installation error: {str(e)}")
                    GLib.idle_add(update_progress, 1.0, f"Error: {str(e)}")
                    time.sleep(2)
                    GLib.idle_add(progress_dialog.destroy)
                
                finally:
                    current_process['process'] = None
                    if script_path[0] and os.path.exists(script_path[0]):
                        try:
                            os.remove(script_path[0])
                            print(f"Cleaned up script: {script_path[0]}")
                        except Exception as e:
                            print(f"Error cleaning up script: {e}")

            thread = threading.Thread(target=install_thread)
            thread.daemon = True
            thread.start()

    def modify_script(self, script_path):
        """Add source line for common functions after shebang"""
        try:
            # Read the original script content
            with open(script_path, 'r') as f:
                content = f.read()
            
            # Get path to inbuild_functions
            inbuild_functions_path = Path(__file__).parent / 'inbuild_functions' / 'inbuild_functions'
            
            # Add inbuild_functions source after shebang
            # Try both common shebang variants
            for shebang in ['#!/data/data/com.termux/files/usr/bin/bash\n', '#!/bin/bash\n']:
                if shebang in content:
                    new_content = content.replace(
                        shebang,
                        f'{shebang}source {inbuild_functions_path}\n'
                    )
                    
                    # Write modified content back
                    with open(script_path, 'w') as f:
                        f.write(new_content)
                    return True
            
            print("No compatible shebang found in script")
            return False
                
        except Exception as e:
            print(f"Error injecting common_functions source: {e}")
            return False

    def download_script(self, url):
        """Download a script from URL and return its local path"""
        try:
            # Create temp directory if it doesn't exist
            os.makedirs(TERMUX_TMP, exist_ok=True)

            # Create a temporary file
            script_name = f"appstore_{int(time.time())}.sh"
            script_path = os.path.join(TERMUX_TMP, script_name)

            # Download using aria2c
            print(f"Downloading script from {url} to {script_path}")
            command = f"aria2c -x 16 -s 16 '{url}' -d '{TERMUX_TMP}' -o '{script_name}'"
            result = subprocess.run(command, shell=True, capture_output=True, text=True)
            
            if result.returncode != 0:
                print(f"Download failed: {result.stderr}")
                return None

            # Modify script to source common functions
            if not self.modify_script(script_path):
                print("Failed to modify script")
                return None

            return script_path
        except Exception as e:
            print(f"Error downloading script: {e}")
            return None

    def on_uninstall_clicked(self, button, app):
        """Handle uninstall button click"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.YES_NO,
            text=f"Uninstall {app['app_name']}?"
        )
        response = dialog.run()
        dialog.destroy()

        if response == Gtk.ResponseType.YES:
            progress_dialog = Gtk.Dialog(
                title="Uninstalling...",
                parent=self,
                flags=0
            )
            progress_dialog.set_default_size(400, -1)
            progress_dialog.set_resizable(False)
            progress_dialog.add_button("Cancel", Gtk.ResponseType.CANCEL)
            progress_dialog.set_deletable(False)
            
            vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
            vbox.set_margin_start(20)
            vbox.set_margin_end(20)
            vbox.set_margin_top(20)
            vbox.set_margin_bottom(20)
            
            status_label = Gtk.Label()
            status_label.set_line_wrap(True)
            status_label.set_line_wrap_mode(Gtk.WrapMode.WORD_CHAR)
            status_label.set_max_width_chars(50)
            status_label.set_width_chars(50)
            status_label.set_justify(Gtk.Justification.LEFT)
            status_label.set_halign(Gtk.Align.START)
            status_label.set_text("Starting uninstallation...")
            vbox.pack_start(status_label, True, True, 0)
            
            progress_bar = Gtk.ProgressBar()
            progress_bar.set_show_text(True)
            progress_bar.set_size_request(360, -1)
            vbox.pack_start(progress_bar, True, True, 0)
            
            progress_dialog.get_content_area().add(vbox)
            progress_dialog.show_all()

            def update_progress(fraction, status_text):
                if status_text and not status_text.strip('-'):
                    status_label.set_text(status_text)
                progress_bar.set_fraction(fraction)
                progress_bar.set_text(f"{int(fraction * 100)}%")
                return False

            def uninstall_thread():
                script_path = None
                try:
                    # Download script
                    GLib.idle_add(update_progress, 0.2, "Downloading uninstall script...")
                    script_path = self.download_script(app['uninstall_url'])
                    if not script_path or self.uninstallation_cancelled:
                        if script_path and os.path.exists(script_path):
                            os.remove(script_path)
                        GLib.idle_add(progress_dialog.destroy)
                        return

                    os.chmod(script_path, os.stat(script_path).st_mode | stat.S_IEXEC)

                    process = subprocess.Popen(
                        script_path,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        universal_newlines=True,
                        bufsize=1
                    )

                    for line in process.stdout:
                        if self.uninstallation_cancelled:
                            process.terminate()
                            process.wait()
                            GLib.idle_add(progress_dialog.destroy)
                            return
                        
                        GLib.idle_add(update_progress, 0.5, line.strip())

                    process.wait()
                    if process.returncode == 0 and not self.uninstallation_cancelled:
                        GLib.idle_add(update_progress, 0.95, "Finalizing uninstallation...")
                        self.installed_apps.remove(app['folder_name'])
                        self.save_installed_apps()
                        GLib.idle_add(self.show_apps)
                        GLib.idle_add(update_progress, 1.0, "Uninstallation complete!")
                        time.sleep(1)
                        GLib.idle_add(progress_dialog.destroy)
                    else:
                        GLib.idle_add(update_progress, 1.0, "Uninstallation failed!")
                        time.sleep(2)
                        GLib.idle_add(progress_dialog.destroy)

                except Exception as e:
                    print(f"Uninstallation error: {str(e)}")
                    GLib.idle_add(update_progress, 1.0, f"Error: {str(e)}")
                    time.sleep(2)
                    GLib.idle_add(progress_dialog.destroy)
                
                finally:
                    # Clean up downloaded script
                    if script_path and os.path.exists(script_path):
                        try:
                            os.remove(script_path)
                            print(f"Cleaned up script: {script_path}")
                        except Exception as e:
                            print(f"Error cleaning up script: {e}")

            thread = threading.Thread(target=uninstall_thread)
            thread.daemon = True
            thread.start()

    def show_apps(self, category=None):
        """Display apps based on category"""
        # Clear current list
        for child in self.app_list_box.get_children():
            child.destroy()

        # Filter apps based on category and search query
        filtered_apps = self.apps_data
        if category and category != "All Apps":
            filtered_apps = [app for app in filtered_apps if category in app['categories']]

        # Apply search filter if search entry has text
        search_text = self.search_entry.get_text().lower()
        if search_text:
            filtered_apps = [
                app for app in filtered_apps
                if search_text in app['app_name'].lower()
                or search_text in app['description'].lower()
                or any(search_text in cat.lower() for cat in app['categories'])
            ]

        # Add filtered apps to the list
        for app in filtered_apps:
            # Create app card
            app_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
            app_card.get_style_context().add_class('app-card')

            # Create card content
            card_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
            card_box.set_margin_start(12)
            card_box.set_margin_end(12)
            card_box.set_margin_top(12)
            card_box.set_margin_bottom(12)

            # App logo
            logo_path = os.path.join(APPSTORE_LOGO_DIR, app['folder_name'], 'logo.png')
            if os.path.exists(logo_path):
                try:
                    pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(logo_path, 64, 64, True)
                    logo_image = Gtk.Image.new_from_pixbuf(pixbuf)
                    logo_image.set_margin_end(12)
                    card_box.pack_start(logo_image, False, False, 0)
                except Exception as e:
                    print(f"Error loading logo for {app['app_name']}: {str(e)}")

            # App info
            info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
            
            # App name
            name_label = Gtk.Label()
            name_label.set_markup(f"<b>{app['app_name']}</b>")
            name_label.set_halign(Gtk.Align.START)
            info_box.pack_start(name_label, False, False, 0)

            # App description
            desc_label = Gtk.Label(label=app['description'][:100] + "..." if len(app['description']) > 100 else app['description'])
            desc_label.set_line_wrap(True)
            desc_label.set_halign(Gtk.Align.START)
            info_box.pack_start(desc_label, False, False, 0)

            # Bottom row box for buttons and source type
            bottom_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
            bottom_box.set_margin_top(6)

            # Button box (left side of bottom row)
            button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)

            # Check if app is installed
            is_installed = app['folder_name'] in self.installed_apps

            if is_installed:
                # Add Open button only if run_cmd exists and is not null
                if app.get('run_cmd') is not None:
                    open_button = Gtk.Button(label="Open")
                    open_button.get_style_context().add_class("open-button")
                    open_button.connect("clicked", self.on_open_clicked, app)
                    button_box.pack_start(open_button, False, False, 0)

                # Add Uninstall button
                uninstall_button = Gtk.Button(label="Uninstall")
                uninstall_button.get_style_context().add_class("uninstall-button")
                uninstall_button.connect("clicked", self.on_uninstall_clicked, app)
                button_box.pack_start(uninstall_button, False, False, 0)
            else:
                # Add Install button
                install_button = Gtk.Button(label="Install")
                install_button.get_style_context().add_class("install-button")
                install_button.connect("clicked", self.on_install_clicked, app)
                button_box.pack_start(install_button, False, False, 0)

            bottom_box.pack_start(button_box, False, False, 0)

            # Source type label (right side of bottom row)
            source_label = Gtk.Label()
            source_type = app.get('app_type', 'unknown').capitalize()
            source_label.set_markup(f"Source: {source_type}")
            source_label.get_style_context().add_class("source-type-label")
            source_label.set_halign(Gtk.Align.END)
            bottom_box.pack_end(source_label, False, False, 0)

            info_box.pack_start(bottom_box, False, False, 0)
            card_box.pack_start(info_box, True, True, 0)
            app_card.add(card_box)
            self.app_list_box.pack_start(app_card, False, True, 0)

        self.app_list_box.show_all()

    def on_search_changed(self, entry):
        """Handle search entry changes"""
        # Get the currently selected category
        selected_category = None
        for button in self.category_buttons:
            if button.get_style_context().has_class('selected'):
                selected_category = button.get_label()
                break

        if selected_category == "All Apps":
            selected_category = None

        # Update the app list with current category and search text
        self.show_apps(selected_category)

    def on_delete_event(self, widget, event):
        """Handle window closing"""
        self.stop_background_tasks = True
        sys.exit(0)
        return False

    def refresh_error(self, error_message):
        """Handle refresh error"""
        print(f"Refresh error: {error_message}")
        # Implement additional error handling logic here if needed

    def download_apps(self):
        """Download apps in the background"""
        # Implement multi-threading logic for downloading apps
        pass

    def on_open_clicked(self, button, app):
        """Handle open button click"""
        try:
            # Show loading cursor
            window = button.get_toplevel()
            window.get_window().set_cursor(Gdk.Cursor.new_from_name(window.get_display(), "wait"))
            
            def run_command():
                try:
                    # Get the run command from the app metadata
                    run_cmd = app.get('run_cmd')
                    if run_cmd:
                        subprocess.Popen(run_cmd, shell=True)
                finally:
                    # Reset cursor back to default
                    GLib.idle_add(lambda: window.get_window().set_cursor(None))

            # Run the command in a separate thread
            thread = threading.Thread(target=run_command)
            thread.daemon = True
            thread.start()

        except Exception as e:
            print(f"Error opening app: {str(e)}")
            # Reset cursor in case of error
            window.get_window().set_cursor(None)

    def start_task_processor(self):
        """Start the background task processor thread"""
        self.task_running = True
        self.task_thread = threading.Thread(target=self.process_tasks)
        self.task_thread.daemon = True
        self.task_thread.start()

    def process_tasks(self):
        """Process tasks from the queue"""
        while self.task_running:
            try:
                task = self.task_queue.get(timeout=1.0)
                if task:
                    task()
                self.task_queue.task_done()
            except queue.Empty:
                continue
            except Exception as e:
                print(f"Error processing task: {str(e)}")

    def stop_task_processor(self):
        """Stop the task processor thread"""
        self.task_running = False
        if self.task_thread:
            self.task_thread.join()

    def on_destroy(self, *args):
        """Clean up when window is closed"""
        self.stop_task_processor()
        sys.exit(0)

    def on_quit_accelerator(self, accel_group, acceleratable, keyval, modifier):
        """Handle Ctrl+Q accelerator"""
        self.on_delete_event(None, None)
        return True

def main():
    app = AppStoreApplication()
    return app.run(sys.argv)

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(0)
