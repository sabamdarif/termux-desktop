/*
 * add2menu.c - GTK application to add PRoot-Distro applications to Termux menu
 */

#include <gtk/gtk.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>

typedef struct {
    char *display_name;
    char *file_path;
    char *icon_name;
    gboolean selected;
} AppItem;

typedef struct {
    GtkWidget *window;
    GtkWidget *add_radio;
    GtkWidget *remove_radio;
    GtkWidget *treeview;
    GtkWidget *select_all_check;
    GtkWidget *action_button;
    GtkWidget *statusbar;
    GtkListStore *liststore;
    
    char *prefix;
    char *distro_name;
    char *distro_path;
    char *applications_dir;
    char *added_dir;

    GSList *app_items;
    gboolean add_mode;
} Add2MenuApp;

// Function prototypes
static void setup_css(void);
static void setup_window(Add2MenuApp *app);
static void setup_header_bar(Add2MenuApp *app);
static void setup_main_content(Add2MenuApp *app);
static void refresh_list(GtkWidget *widget, Add2MenuApp *app);
static void on_mode_changed(GtkToggleButton *button, Add2MenuApp *app);
static void on_item_toggled(GtkCellRendererToggle *cell, gchar *path, Add2MenuApp *app);
static void on_select_all_toggled(GtkToggleButton *button, Add2MenuApp *app);
static void on_action_clicked(GtkButton *button, Add2MenuApp *app);
static void update_status(Add2MenuApp *app);
static void list_desktop_files(Add2MenuApp *app, const char *directory);
static void add_applications(Add2MenuApp *app);
static void remove_applications(Add2MenuApp *app);
static void update_system_and_show_success(Add2MenuApp *app);
static void show_message_dialog(Add2MenuApp *app, const char *message, const char *title);
static gboolean on_single_click(GtkTreeView *treeview, GdkEventButton *event, Add2MenuApp *app);
static void on_column_clicked(GtkTreeViewColumn *column, Add2MenuApp *app);
static void free_app_items(Add2MenuApp *app);
static void g_file_copy_file(const char *src, const char *dest);

static void setup_css(void) {
    GtkCssProvider *provider;
    GdkDisplay *display;
    GdkScreen *screen;
    
    const gchar *css = 
        ".main-window { background-color: #f5f6f7; }"
        ".header-bar { background: linear-gradient(to bottom, #2c3e50, #34495e); color: white; padding: 8px; }"
        ".mode-switch { border-radius: 20px; padding: 5px 10px; background: rgba(255,255,255,0.1); }"
        ".app-list { background-color: white; border-radius: 5px; border: 1px solid #ddd; color: #333333; }"
        ".app-list row { padding: 8px; }"
        ".app-list row:selected { background-color: #3498db; color: white; }"
        ".action-button { background: linear-gradient(to bottom, #3498db, #2980b9); color: white; border-radius: 5px; padding: 8px 15px; }"
        ".action-button:hover { background: linear-gradient(to bottom, #2980b9, #2471a3); }"
        ".status-bar { background-color: #f8f9fa; border-top: 1px solid #dee2e6; padding: 5px; color: #333333; }";
    
    provider = gtk_css_provider_new();
    display = gdk_display_get_default();
    screen = gdk_display_get_default_screen(display);
    gtk_style_context_add_provider_for_screen(screen, GTK_STYLE_PROVIDER(provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    
    gtk_css_provider_load_from_data(provider, css, -1, NULL);
    g_object_unref(provider);
}

static void setup_window(Add2MenuApp *app) {
    // Create main window
    app->window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(app->window), "Add To Menu");
    gtk_window_set_default_size(GTK_WINDOW(app->window), 600, 500);
    gtk_window_set_position(GTK_WINDOW(app->window), GTK_WIN_POS_CENTER);
    
    // Set window role
    gtk_window_set_role(GTK_WINDOW(app->window), "add2menu");
    
    // Connect destroy signal
    g_signal_connect(app->window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
}

static void setup_header_bar(Add2MenuApp *app) {
    GtkWidget *header, *mode_box, *refresh_button, *refresh_image;
    
    // Create header bar
    header = gtk_header_bar_new();
    gtk_header_bar_set_show_close_button(GTK_HEADER_BAR(header), TRUE);
    gtk_style_context_add_class(gtk_widget_get_style_context(header), "header-bar");
    
    // Create mode switch box
    mode_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    gtk_style_context_add_class(gtk_widget_get_style_context(mode_box), "mode-switch");
    
    // Create radio buttons for mode
    app->add_radio = gtk_radio_button_new_with_label(NULL, "Add");
    app->remove_radio = gtk_radio_button_new_with_label_from_widget(GTK_RADIO_BUTTON(app->add_radio), "Remove");
    
    // Connect signals
    g_signal_connect(app->add_radio, "toggled", G_CALLBACK(on_mode_changed), app);
    
    // Add radios to box
    gtk_box_pack_start(GTK_BOX(mode_box), app->add_radio, FALSE, FALSE, 5);
    gtk_box_pack_start(GTK_BOX(mode_box), app->remove_radio, FALSE, FALSE, 5);
    
    // Add mode box to header
    gtk_header_bar_pack_start(GTK_HEADER_BAR(header), mode_box);
    
    // Create refresh button
    refresh_button = gtk_button_new();
    refresh_image = gtk_image_new_from_icon_name("view-refresh-symbolic", GTK_ICON_SIZE_BUTTON);
    gtk_container_add(GTK_CONTAINER(refresh_button), refresh_image);
    g_signal_connect(refresh_button, "clicked", G_CALLBACK(refresh_list), app);
    gtk_header_bar_pack_end(GTK_HEADER_BAR(header), refresh_button);
    
    // Set header as titlebar
    gtk_window_set_titlebar(GTK_WINDOW(app->window), header);
}

static void setup_main_content(Add2MenuApp *app) {
    GtkWidget *main_box, *content_box, *scroll, *button_box;
    GtkCellRenderer *renderer_toggle, *renderer_icon, *renderer_text;
    GtkTreeViewColumn *column_toggle, *column_icon, *column_text;
    
    // Create main box
    main_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_container_add(GTK_CONTAINER(app->window), main_box);
    
    // Create content box with padding
    content_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 10);
    gtk_widget_set_margin_start(content_box, 20);
    gtk_widget_set_margin_end(content_box, 20);
    gtk_widget_set_margin_top(content_box, 20);
    gtk_widget_set_margin_bottom(content_box, 20);
    
    // Create select all checkbox
    app->select_all_check = gtk_check_button_new_with_label("Select All");
    g_signal_connect(app->select_all_check, "toggled", G_CALLBACK(on_select_all_toggled), app);
    gtk_widget_set_halign(app->select_all_check, GTK_ALIGN_START);
    gtk_box_pack_start(GTK_BOX(content_box), app->select_all_check, FALSE, FALSE, 0);
    
    // Create scrolled window
    scroll = gtk_scrolled_window_new(NULL, NULL);
    gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scroll), GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);
    
    // Create list store and tree view
    app->liststore = gtk_list_store_new(4, G_TYPE_BOOLEAN, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING);
    app->treeview = gtk_tree_view_new_with_model(GTK_TREE_MODEL(app->liststore));
    gtk_style_context_add_class(gtk_widget_get_style_context(app->treeview), "app-list");
    
    // Create checkbox column
    renderer_toggle = gtk_cell_renderer_toggle_new();
    g_signal_connect(renderer_toggle, "toggled", G_CALLBACK(on_item_toggled), app);
    column_toggle = gtk_tree_view_column_new_with_attributes("", renderer_toggle, "active", 0, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(app->treeview), column_toggle);
    
    // Create icon column
    renderer_icon = gtk_cell_renderer_pixbuf_new();
    column_icon = gtk_tree_view_column_new_with_attributes("", renderer_icon, "icon-name", 3, NULL);
    gtk_tree_view_append_column(GTK_TREE_VIEW(app->treeview), column_icon);
    
    // Create text column
    renderer_text = gtk_cell_renderer_text_new();
    g_object_set(renderer_text, "ellipsize", PANGO_ELLIPSIZE_END, NULL);
    column_text = gtk_tree_view_column_new_with_attributes("Application", renderer_text, "text", 1, NULL);
    gtk_tree_view_column_set_expand(column_text, TRUE);
    gtk_tree_view_column_set_clickable(column_text, TRUE);
    g_signal_connect(column_text, "clicked", G_CALLBACK(on_column_clicked), app);
    gtk_tree_view_append_column(GTK_TREE_VIEW(app->treeview), column_text);
    
    // Connect single click handler
    g_signal_connect(app->treeview, "button-press-event", G_CALLBACK(on_single_click), app);
    
    // Add tree view to scroll window
    gtk_container_add(GTK_CONTAINER(scroll), app->treeview);
    gtk_box_pack_start(GTK_BOX(content_box), scroll, TRUE, TRUE, 0);
    
    // Create action button
    button_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 6);
    gtk_widget_set_halign(button_box, GTK_ALIGN_END);
    
    app->action_button = gtk_button_new_with_label("Add Selected");
    gtk_style_context_add_class(gtk_widget_get_style_context(app->action_button), "action-button");
    g_signal_connect(app->action_button, "clicked", G_CALLBACK(on_action_clicked), app);
    gtk_box_pack_start(GTK_BOX(button_box), app->action_button, FALSE, FALSE, 0);
    
    gtk_box_pack_start(GTK_BOX(content_box), button_box, FALSE, FALSE, 0);
    
    // Create status bar
    app->statusbar = gtk_statusbar_new();
    gtk_style_context_add_class(gtk_widget_get_style_context(app->statusbar), "status-bar");
    
    // Add all to main box
    gtk_box_pack_start(GTK_BOX(main_box), content_box, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(main_box), app->statusbar, FALSE, FALSE, 0);
}

static void update_status(Add2MenuApp *app) {
    GtkTreeIter iter;
    gboolean valid;
    gboolean selected;
    int selected_count = 0;
    int total_count = 0;
    gchar *status_text;
    guint context_id;
    
    // Count selected items
    valid = gtk_tree_model_get_iter_first(GTK_TREE_MODEL(app->liststore), &iter);
    while (valid) {
        gtk_tree_model_get(GTK_TREE_MODEL(app->liststore), &iter, 0, &selected, -1);
        if (selected) {
            selected_count++;
        }
        total_count++;
        valid = gtk_tree_model_iter_next(GTK_TREE_MODEL(app->liststore), &iter);
    }
    
    // Update statusbar
    context_id = gtk_statusbar_get_context_id(GTK_STATUSBAR(app->statusbar), "selection");
    gtk_statusbar_pop(GTK_STATUSBAR(app->statusbar), context_id);
    status_text = g_strdup_printf("Selected %d of %d applications", selected_count, total_count);
    gtk_statusbar_push(GTK_STATUSBAR(app->statusbar), context_id, status_text);
    g_free(status_text);
}

static gboolean on_single_click(GtkTreeView *treeview, GdkEventButton *event, Add2MenuApp *app) {
    GtkTreePath *path;
    GtkTreeIter iter;
    gboolean selected;
    
    if (event->button == 1) { // Left click
        if (gtk_tree_view_get_path_at_pos(treeview, event->x, event->y, &path, NULL, NULL, NULL)) {
            gtk_tree_model_get_iter(GTK_TREE_MODEL(app->liststore), &iter, path);
            gtk_tree_model_get(GTK_TREE_MODEL(app->liststore), &iter, 0, &selected, -1);
            gtk_list_store_set(app->liststore, &iter, 0, !selected, -1);
            gtk_tree_path_free(path);
            update_status(app);
            return TRUE;
        }
    }
    return FALSE;
}

static void on_item_toggled(GtkCellRendererToggle *cell G_GNUC_UNUSED, gchar *path_str, Add2MenuApp *app) {
    GtkTreePath *path = gtk_tree_path_new_from_string(path_str);
    GtkTreeIter iter;
    gboolean selected;
    
    gtk_tree_model_get_iter(GTK_TREE_MODEL(app->liststore), &iter, path);
    gtk_tree_model_get(GTK_TREE_MODEL(app->liststore), &iter, 0, &selected, -1);
    gtk_list_store_set(app->liststore, &iter, 0, !selected, -1);
    
    gtk_tree_path_free(path);
    update_status(app);
}

static void on_select_all_toggled(GtkToggleButton *button, Add2MenuApp *app) {
    GtkTreeIter iter;
    gboolean is_active = gtk_toggle_button_get_active(button);
    gboolean valid;
    
    valid = gtk_tree_model_get_iter_first(GTK_TREE_MODEL(app->liststore), &iter);
    while (valid) {
        gtk_list_store_set(app->liststore, &iter, 0, is_active, -1);
        valid = gtk_tree_model_iter_next(GTK_TREE_MODEL(app->liststore), &iter);
    }
    
    update_status(app);
}

static void on_mode_changed(GtkToggleButton *button G_GNUC_UNUSED, Add2MenuApp *app) {
    app->add_mode = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(app->add_radio));
    refresh_list(NULL, app);
}

static void refresh_list(GtkWidget *widget G_GNUC_UNUSED, Add2MenuApp *app) {
    char *path;
    
    // Clear list store
    gtk_list_store_clear(app->liststore);
    
    // Free existing app items
    free_app_items(app);
    app->app_items = NULL;
    
    // Set path based on mode
    if (gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(app->add_radio))) {
        path = g_build_filename(app->distro_path, "usr/share/applications", NULL);
        gtk_button_set_label(GTK_BUTTON(app->action_button), "Add Selected");
    } else {
        path = g_strdup(app->added_dir);
        gtk_button_set_label(GTK_BUTTON(app->action_button), "Remove Selected");
    }
    
    printf("Refreshing list from path: %s\n", path);
    
    // List desktop files
    list_desktop_files(app, path);
    g_free(path);
    
    // Update status
    update_status(app);
}

static gint compare_app_items(gconstpointer a, gconstpointer b) {
    const AppItem *item_a = a;
    const AppItem *item_b = b;
    return g_ascii_strcasecmp(item_a->display_name, item_b->display_name);
}

static void list_desktop_files(Add2MenuApp *app, const char *directory) {
    DIR *dir;
    struct dirent *entry;
    char *filepath, *name, *icon, *line, *key, *value;
    FILE *file;
    char buffer[1024];
    gboolean no_display;
    AppItem *item;
    GSList *sorted_list = NULL;
    GSList *iter;
    GtkTreeIter tree_iter;
    
    // Check if directory exists
    dir = opendir(directory);
    if (!dir) {
        printf("Directory does not exist: %s\n", directory);
        return;
    }
    
    printf("Scanning directory: %s\n", directory);
    
    // Read directory contents
    while ((entry = readdir(dir)) != NULL) {
        // Skip if not a .desktop file
        if (!g_str_has_suffix(entry->d_name, ".desktop")) {
            continue;
        }
        
        // Build full path
        filepath = g_build_filename(directory, entry->d_name, NULL);
        
        // Open file
        file = fopen(filepath, "r");
        if (!file) {
            printf("Could not open file: %s\n", filepath);
            g_free(filepath);
            continue;
        }
        
        // Parse file
        name = NULL;
        icon = NULL;
        no_display = FALSE;
        
        while (fgets(buffer, sizeof(buffer), file)) {
            line = g_strstrip(buffer);
            
            // Skip if not a key=value line
            if (!strchr(line, '=')) {
                continue;
            }
            
            // Split line into key and value
            key = line;
            value = strchr(line, '=');
            *value++ = '\0';
            value = g_strstrip(value);
            
            // Get name
            if (g_str_has_prefix(key, "Name[") && !name) {
                name = g_strdup(value);
            } else if (g_str_has_prefix(key, "Name") && !name) {
                name = g_strdup(value);
            }
            // Get icon
            else if (g_str_has_prefix(key, "Icon")) {
                // Handle different icon formats
                if (g_str_has_suffix(value, ".png") || g_str_has_suffix(value, ".svg")) {
                    icon = g_strdup(value);
                } else {
                    // Just use the icon name as is
                    icon = g_strdup(value);
                }
            }
            // Check NoDisplay
            else if (g_str_has_prefix(key, "NoDisplay") && g_ascii_strcasecmp(value, "true") == 0) {
                no_display = TRUE;
                break;
            }
        }
        
        fclose(file);
        
        // Skip if NoDisplay is true
        if (no_display) {
            g_free(name);
            g_free(icon);
            g_free(filepath);
            continue;
        }
        
        // If no name was found, use filename without extension
        if (!name) {
            char *base = g_path_get_basename(filepath);
            char *dot = strrchr(base, '.');
            if (dot) *dot = '\0';
            name = g_strdup(base);
            g_free(base);
        }
        
        // If no icon was found, use fallback
        if (!icon) {
            icon = g_strdup("application-x-executable");
        }
        
        // Create app item
        item = g_new(AppItem, 1);
        item->display_name = name;
        item->file_path = filepath;
        item->icon_name = icon;
        item->selected = FALSE;
        
        // Add to list
        sorted_list = g_slist_insert_sorted(sorted_list, item, compare_app_items);
    }
    
    closedir(dir);
    
    // Add sorted items to list store
    for (iter = sorted_list; iter; iter = iter->next) {
        item = iter->data;
        
        gtk_list_store_append(app->liststore, &tree_iter);
        gtk_list_store_set(app->liststore, &tree_iter,
                          0, FALSE,  // selected
                          1, item->display_name,
                          2, item->file_path,
                          3, item->icon_name,
                          -1);
        
        // Add to app's list for later reference
        app->app_items = g_slist_append(app->app_items, item);
    }
    
    g_slist_free(sorted_list);
    
    printf("Found %d applications\n", g_slist_length(app->app_items));
}

static void show_message_dialog(Add2MenuApp *app, const char *message, const char *title) {
    GtkWidget *dialog;
    GtkMessageType type;
    
    if (g_strcmp0(title, "Success") == 0) {
        type = GTK_MESSAGE_INFO;
    } else {
        type = GTK_MESSAGE_ERROR;
    }
    
    dialog = gtk_message_dialog_new(GTK_WINDOW(app->window),
                                    GTK_DIALOG_MODAL,
                                    type,
                                    GTK_BUTTONS_OK,
                                    "%s", message);
    gtk_window_set_title(GTK_WINDOW(dialog), title);
    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(dialog);
}

static void on_action_clicked(GtkButton *button G_GNUC_UNUSED, Add2MenuApp *app) {
    GtkTreeIter iter;
    gboolean valid;
    gboolean has_selected = FALSE;
    
    // Check if any item is selected
    valid = gtk_tree_model_get_iter_first(GTK_TREE_MODEL(app->liststore), &iter);
    while (valid) {
        gboolean selected;
        gtk_tree_model_get(GTK_TREE_MODEL(app->liststore), &iter, 0, &selected, -1);
        if (selected) {
            has_selected = TRUE;
            break;
        }
        valid = gtk_tree_model_iter_next(GTK_TREE_MODEL(app->liststore), &iter);
    }
    
    // Show error if no item is selected
    if (!has_selected) {
        show_message_dialog(app, "Please select at least one application", "Notice");
        return;
    }
    
    // Perform action based on mode
    if (app->add_mode) {
        add_applications(app);
    } else {
        remove_applications(app);
    }
}

static void add_applications(Add2MenuApp *app) {
    GtkTreeIter iter;
    gboolean valid;
    gboolean selected;
    gchar *name, *filepath, *new_path, *desktop_path, *home_dir, *desktop_dir;
    FILE *src_file, *dest_file;
    char buffer[1024];
    
    // Create added_dir if it doesn't exist
    g_mkdir_with_parents(app->added_dir, 0755);
    
    // Get home directory
    home_dir = g_strdup(g_getenv("HOME"));
    desktop_dir = g_build_filename(home_dir, "Desktop", NULL);
    g_mkdir_with_parents(desktop_dir, 0755);
    
    // Process each selected item
    valid = gtk_tree_model_get_iter_first(GTK_TREE_MODEL(app->liststore), &iter);
    while (valid) {
        gtk_tree_model_get(GTK_TREE_MODEL(app->liststore), &iter, 
                          0, &selected,
                          1, &name, 
                          2, &filepath, 
                          -1);
        
        if (selected) {
            // Get base name
            char *base_name = g_path_get_basename(filepath);
            
            // Build paths
            new_path = g_build_filename(app->added_dir, base_name, NULL);
            desktop_path = g_build_filename(desktop_dir, base_name, NULL);
            
            // Skip if already exists
            if (g_file_test(new_path, G_FILE_TEST_EXISTS) || g_file_test(desktop_path, G_FILE_TEST_EXISTS)) {
                printf("Skipping %s - already exists\n", name);
                g_free(base_name);
                g_free(new_path);
                g_free(desktop_path);
                g_free(name);
                g_free(filepath);
                valid = gtk_tree_model_iter_next(GTK_TREE_MODEL(app->liststore), &iter);
                continue;
            }
            
            // Copy and modify file
            src_file = fopen(filepath, "r");
            dest_file = fopen(new_path, "w");
            
            if (src_file && dest_file) {
                while (fgets(buffer, sizeof(buffer), src_file)) {
                    // Replace Exec= with Exec=pdrun 
                    if (g_str_has_prefix(buffer, "Exec=")) {
                        fprintf(dest_file, "Exec=pdrun %s", buffer + 5);
                    } else {
                        fputs(buffer, dest_file);
                    }
                }
                
                fclose(src_file);
                fclose(dest_file);
                
                // Copy to desktop
                g_file_copy_file(new_path, desktop_path);
                
                // Make executable
                chmod(desktop_path, 0755);
            }
            
            g_free(base_name);
            g_free(new_path);
            g_free(desktop_path);
        }
        
        g_free(name);
        g_free(filepath);
        valid = gtk_tree_model_iter_next(GTK_TREE_MODEL(app->liststore), &iter);
    }
    
    g_free(home_dir);
    g_free(desktop_dir);
    
    // Update system
    update_system_and_show_success(app);
}

static void g_file_copy_file(const char *src, const char *dest) {
    FILE *src_file, *dest_file;
    char buffer[4096];
    size_t size;
    
    src_file = fopen(src, "rb");
    if (!src_file) return;
    
    dest_file = fopen(dest, "wb");
    if (!dest_file) {
        fclose(src_file);
        return;
    }
    
    while ((size = fread(buffer, 1, sizeof(buffer), src_file)) > 0) {
        fwrite(buffer, 1, size, dest_file);
    }
    
    fclose(src_file);
    fclose(dest_file);
}

static void remove_applications(Add2MenuApp *app) {
    GtkTreeIter iter;
    gboolean valid;
    gboolean selected;
    gchar *name, *filepath, *base_name, *desktop_path, *home_dir, *desktop_dir;
    
    // Get home directory
    home_dir = g_strdup(g_getenv("HOME"));
    desktop_dir = g_build_filename(home_dir, "Desktop", NULL);
    
    // Process each selected item
    valid = gtk_tree_model_get_iter_first(GTK_TREE_MODEL(app->liststore), &iter);
    while (valid) {
        gtk_tree_model_get(GTK_TREE_MODEL(app->liststore), &iter, 
                          0, &selected,
                          1, &name, 
                          2, &filepath, 
                          -1);
        
        if (selected) {
            // Remove from pd_added directory
            if (g_file_test(filepath, G_FILE_TEST_EXISTS)) {
                unlink(filepath);
            }
            
            // Remove from Desktop directory
            base_name = g_path_get_basename(filepath);
            desktop_path = g_build_filename(desktop_dir, base_name, NULL);
            
            if (g_file_test(desktop_path, G_FILE_TEST_EXISTS)) {
                unlink(desktop_path);
            }
            
            g_free(base_name);
            g_free(desktop_path);
        }
        
        g_free(name);
        g_free(filepath);
        valid = gtk_tree_model_iter_next(GTK_TREE_MODEL(app->liststore), &iter);
    }
    
    g_free(home_dir);
    g_free(desktop_dir);
    
    // Update system
    update_system_and_show_success(app);
}

static void update_system_and_show_success(Add2MenuApp *app) {
    gchar *cmd, *home_dir, *desktop_dir;
    
    // Update desktop database
    cmd = g_strdup_printf("update-desktop-database %s", app->applications_dir);
    system(cmd);
    g_free(cmd);
    
    // Update icon cache
    cmd = g_strdup_printf("gtk-update-icon-cache %s/share/icons/hicolor", app->prefix);
    system(cmd);
    g_free(cmd);
    
    // Force desktop menu update
    system("setsid xdg-desktop-menu forceupdate &> /dev/null");
    
    // Create .desktop files in Desktop directory
    home_dir = g_strdup(g_getenv("HOME"));
    desktop_dir = g_build_filename(home_dir, "Desktop", NULL);
    g_mkdir_with_parents(desktop_dir, 0755);
    
    // Copy all .desktop files from pd_added to Desktop
    DIR *dir = opendir(app->added_dir);
    if (dir) {
        struct dirent *entry;
        while ((entry = readdir(dir)) != NULL) {
            if (g_str_has_suffix(entry->d_name, ".desktop")) {
                gchar *src = g_build_filename(app->added_dir, entry->d_name, NULL);
                gchar *dst = g_build_filename(desktop_dir, entry->d_name, NULL);
                
                g_file_copy_file(src, dst);
                chmod(dst, 0755);  // Make executable
                
                g_free(src);
                g_free(dst);
            }
        }
        closedir(dir);
    }
    
    g_free(home_dir);
    g_free(desktop_dir);
    
    // Show success dialog
    show_message_dialog(app, "Operation completed successfully!", "Success");
    
    // Refresh list
    refresh_list(NULL, app);
}

static void on_column_clicked(GtkTreeViewColumn *column G_GNUC_UNUSED, Add2MenuApp *app) {
    gtk_tree_sortable_set_sort_column_id(GTK_TREE_SORTABLE(app->liststore), 1, GTK_SORT_ASCENDING);
}

static void free_app_items(Add2MenuApp *app) {
    GSList *iter;
    
    for (iter = app->app_items; iter; iter = iter->next) {
        AppItem *item = iter->data;
        g_free(item->display_name);
        g_free(item->file_path);
        g_free(item->icon_name);
        g_free(item);
    }
    
    g_slist_free(app->app_items);
    app->app_items = NULL;
}

int main(int argc, char *argv[]) {
    Add2MenuApp app;
    
    // Initialize GTK
    gtk_init(&argc, &argv);
    
    // Set up CSS
    setup_css();
    
    // Initialize app data
    app.app_items = NULL;
    app.add_mode = TRUE;
    
    // Get environment variables or set defaults
    app.prefix = g_strdup(g_getenv("PREFIX") ? g_getenv("PREFIX") : "/data/data/com.termux/files/usr");
    app.distro_name = g_strdup(g_getenv("distro_name") ? g_getenv("distro_name") : "debian");
    
    // Build paths
    app.distro_path = g_strdup_printf("/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/%s", app.distro_name);
    app.applications_dir = g_build_filename(app.prefix, "share/applications", NULL);
    app.added_dir = g_build_filename(app.applications_dir, "pd_added", NULL);
    
    // Create directories
    g_mkdir_with_parents(app.added_dir, 0755);
    
    // Debug print to verify paths
    printf("Looking for .desktop files in: %s/usr/share/applications\n", app.distro_path);
    
    // Set up window
    setup_window(&app);
    
    // Set up components
    setup_header_bar(&app);
    setup_main_content(&app);
    
    // Initial load
    refresh_list(NULL, &app);
    
    // Show all
    gtk_widget_show_all(app.window);
    
    // Main loop
    gtk_main();
    
    // Cleanup
    free_app_items(&app);
    g_free(app.prefix);
    g_free(app.distro_name);
    g_free(app.distro_path);
    g_free(app.applications_dir);
    g_free(app.added_dir);
    
    return 0;
} 