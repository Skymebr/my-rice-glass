#define _POSIX_C_SOURCE 200809L

#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <gtk4-layer-shell.h>
#include <cairo.h>
#include <glib/gstdio.h>

#include <math.h>
#include <string.h>

#define APP_ID "dev.skyme.skywall"
#define THUMB_WIDTH 640
#define THUMB_HEIGHT 416

typedef enum {
    CARD_SHAPE_RECTANGLE = 0,
    CARD_SHAPE_SOFT = 1,
    CARD_SHAPE_PARALLELOGRAM = 2,
} CardShape;

typedef struct {
    gboolean fullscreen;
    gint width;
    gint height;
    gint columns;
    gint min_columns;
    gint max_columns;
    gint card_width;
    gint min_card_width;
    gint max_card_width;
    gdouble aspect_ratio;
    CardShape shape;
    gdouble slant;
    gboolean stagger_rows;
    gdouble row_offset_ratio;
    gint spacing;
    gint row_spacing;
    gint padding;
    gboolean show_video_icon;
    gboolean grayscale_idle;
    gdouble thumb_idle_alpha;
    gdouble thumb_current_alpha;
    gdouble thumb_hover_alpha;
    gdouble glass_alpha_top;
    gdouble glass_alpha_bottom;
    gdouble card_glass_alpha;
    gdouble card_shadow_alpha;
    gdouble hover_scale;
    gdouble border_width;
    gdouble scroll_speed;
    gchar *script_path;
    gchar *wallpaper_dir;
    gchar *layer_namespace;
} SkywallConfig;

typedef struct {
    gchar *path;
    gchar *name;
    gboolean is_video;
    gboolean preview_pending;
    gint64 mtime;
    gint64 size;
    gchar *preview_path;
    GdkPixbuf *color_pixbuf;
    GdkPixbuf *gray_pixbuf;
    gdouble scale;
    gdouble alpha;
} WallpaperItem;

typedef struct {
    WallpaperItem *item;
    gdouble x;
    gdouble y;
    gdouble width;
    gdouble height;
} LayoutItem;

typedef struct {
    gdouble x;
    gdouble y;
} SkyPoint;

typedef struct _SkywallState SkywallState;

typedef struct {
    SkywallState *state;
    WallpaperItem *item;
} PreviewTask;

typedef struct {
    SkywallState *state;
    WallpaperItem *item;
    gchar *preview_path;
    GdkPixbuf *color_pixbuf;
    GdkPixbuf *gray_pixbuf;
} PreviewResult;

struct _SkywallState {
    GtkApplication *application;
    GtkWindow *window;
    GtkDrawingArea *canvas;
    SkywallConfig config;
    gchar *config_path;
    gchar *current_path;
    gchar *resolved_wallpaper_dir;
    gchar *cache_dir;
    gchar *metadata_path;
    GPtrArray *items;
    GArray *layout;
    GKeyFile *metadata;
    gboolean metadata_dirty;
    GThreadPool *preview_pool;
    guint animation_source;
    gint hovered_index;
    gint selected_index;
    gdouble scroll_target;
    gdouble scroll_current;
};

typedef struct {
    gchar *config_path;
    gchar *script_override;
    gchar *wallpaper_dir_override;
    gboolean force_fullscreen;
    gboolean force_windowed;
} CliOptions;

static const gchar *image_extensions[] = {".gif", ".jpg", ".jpeg", ".png", ".webp", NULL};
static const gchar *video_extensions[] = {".mkv", ".mov", ".mp4", ".webm", NULL};

static void skywall_state_free(SkywallState *state);
static gint find_current_index(SkywallState *state);
static void metadata_restore_item(SkywallState *state, WallpaperItem *item);
static void metadata_store_item(SkywallState *state, WallpaperItem *item);
static gchar *preview_path_for(const gchar *cache_dir, WallpaperItem *item);

static gboolean str_truthy(const gchar *value) {
    return value != NULL && g_strcmp0(value, "1") == 0;
}

static gint clamp_int(gint value, gint minimum, gint maximum) {
    if (value < minimum) return minimum;
    if (value > maximum) return maximum;
    return value;
}

static gdouble clamp_double(gdouble value, gdouble minimum, gdouble maximum) {
    if (value < minimum) return minimum;
    if (value > maximum) return maximum;
    return value;
}

static void config_init_defaults(SkywallConfig *config) {
    memset(config, 0, sizeof(*config));
    config->fullscreen = TRUE;
    config->width = 1480;
    config->height = 920;
    config->columns = 5;
    config->min_columns = 3;
    config->max_columns = 8;
    config->card_width = 320;
    config->min_card_width = 230;
    config->max_card_width = 380;
    config->aspect_ratio = 1.62;
    config->shape = CARD_SHAPE_PARALLELOGRAM;
    config->slant = 16.0;
    config->stagger_rows = TRUE;
    config->row_offset_ratio = 0.50;
    config->spacing = 18;
    config->row_spacing = 18;
    config->padding = 12;
    config->show_video_icon = TRUE;
    config->grayscale_idle = TRUE;
    config->thumb_idle_alpha = 0.34;
    config->thumb_current_alpha = 0.95;
    config->thumb_hover_alpha = 1.00;
    config->glass_alpha_top = 0.18;
    config->glass_alpha_bottom = 0.18;
    config->card_glass_alpha = 0.08;
    config->card_shadow_alpha = 0.08;
    config->hover_scale = 1.05;
    config->border_width = 1.45;
    config->scroll_speed = 120.0;
    config->script_path = g_strdup("~/.config/hypr/scripts/wallpaper.sh");
    config->wallpaper_dir = g_strdup("");
    config->layer_namespace = g_strdup("skywall");
}

static void config_clear(SkywallConfig *config) {
    g_clear_pointer(&config->script_path, g_free);
    g_clear_pointer(&config->wallpaper_dir, g_free);
    g_clear_pointer(&config->layer_namespace, g_free);
}

static CardShape parse_shape(const gchar *value) {
    if (g_strcmp0(value, "rectangle") == 0) return CARD_SHAPE_RECTANGLE;
    if (g_strcmp0(value, "soft") == 0) return CARD_SHAPE_SOFT;
    return CARD_SHAPE_PARALLELOGRAM;
}

static gchar *expand_path(const gchar *input) {
    if (input == NULL || *input == '\0') {
        return g_strdup("");
    }

    if (g_str_has_prefix(input, "~/")) {
        return g_build_filename(g_get_home_dir(), input + 2, NULL);
    }
    if (g_strcmp0(input, "~") == 0) {
        return g_strdup(g_get_home_dir());
    }
    return g_strdup(input);
}

static void apply_env_entry(SkywallConfig *config, const gchar *key, const gchar *value) {
    if (g_strcmp0(key, "SKYWALL_FULLSCREEN") == 0) {
        config->fullscreen = str_truthy(value);
    } else if (g_strcmp0(key, "SKYWALL_COLUMNS") == 0) {
        config->columns = clamp_int((gint)g_ascii_strtoll(value, NULL, 10), 1, 12);
    } else if (g_strcmp0(key, "SKYWALL_MIN_COLUMNS") == 0) {
        config->min_columns = clamp_int((gint)g_ascii_strtoll(value, NULL, 10), 1, 12);
    } else if (g_strcmp0(key, "SKYWALL_MAX_COLUMNS") == 0) {
        config->max_columns = clamp_int((gint)g_ascii_strtoll(value, NULL, 10), 1, 16);
    } else if (g_strcmp0(key, "SKYWALL_CARD_WIDTH") == 0) {
        config->card_width = clamp_int((gint)g_ascii_strtoll(value, NULL, 10), 100, 520);
    } else if (g_strcmp0(key, "SKYWALL_MIN_CARD_WIDTH") == 0) {
        config->min_card_width = clamp_int((gint)g_ascii_strtoll(value, NULL, 10), 100, 520);
    } else if (g_strcmp0(key, "SKYWALL_MAX_CARD_WIDTH") == 0) {
        config->max_card_width = clamp_int((gint)g_ascii_strtoll(value, NULL, 10), 100, 640);
    } else if (g_strcmp0(key, "SKYWALL_ASPECT_RATIO") == 0) {
        config->aspect_ratio = clamp_double(g_ascii_strtod(value, NULL), 0.7, 3.0);
    } else if (g_strcmp0(key, "SKYWALL_SHAPE") == 0) {
        config->shape = parse_shape(value);
    } else if (g_strcmp0(key, "SKYWALL_SLANT") == 0) {
        config->slant = clamp_double(g_ascii_strtod(value, NULL), 0.0, 80.0);
    } else if (g_strcmp0(key, "SKYWALL_STAGGER_ROWS") == 0) {
        config->stagger_rows = str_truthy(value);
    } else if (g_strcmp0(key, "SKYWALL_ROW_OFFSET_RATIO") == 0) {
        config->row_offset_ratio = clamp_double(g_ascii_strtod(value, NULL), 0.0, 1.0);
    } else if (g_strcmp0(key, "SKYWALL_SPACING") == 0) {
        config->spacing = clamp_int((gint)g_ascii_strtoll(value, NULL, 10), 0, 96);
    } else if (g_strcmp0(key, "SKYWALL_ROW_SPACING") == 0) {
        config->row_spacing = clamp_int((gint)g_ascii_strtoll(value, NULL, 10), 0, 96);
    } else if (g_strcmp0(key, "SKYWALL_PADDING") == 0) {
        config->padding = clamp_int((gint)g_ascii_strtoll(value, NULL, 10), 0, 128);
    } else if (g_strcmp0(key, "SKYWALL_SHOW_VIDEO_ICON") == 0) {
        config->show_video_icon = str_truthy(value);
    } else if (g_strcmp0(key, "SKYWALL_GRAYSCALE_IDLE") == 0) {
        config->grayscale_idle = str_truthy(value);
    } else if (g_strcmp0(key, "SKYWALL_IDLE_ALPHA") == 0) {
        config->thumb_idle_alpha = clamp_double(g_ascii_strtod(value, NULL), 0.02, 1.0);
    } else if (g_strcmp0(key, "SKYWALL_CURRENT_ALPHA") == 0) {
        config->thumb_current_alpha = clamp_double(g_ascii_strtod(value, NULL), 0.02, 1.0);
    } else if (g_strcmp0(key, "SKYWALL_THUMB_IDLE_ALPHA") == 0) {
        config->thumb_idle_alpha = clamp_double(g_ascii_strtod(value, NULL), 0.02, 1.0);
    } else if (g_strcmp0(key, "SKYWALL_THUMB_CURRENT_ALPHA") == 0) {
        config->thumb_current_alpha = clamp_double(g_ascii_strtod(value, NULL), 0.02, 1.0);
    } else if (g_strcmp0(key, "SKYWALL_THUMB_HOVER_ALPHA") == 0) {
        config->thumb_hover_alpha = clamp_double(g_ascii_strtod(value, NULL), 0.02, 1.0);
    } else if (g_strcmp0(key, "SKYWALL_GLASS_ALPHA_TOP") == 0) {
        config->glass_alpha_top = clamp_double(g_ascii_strtod(value, NULL), 0.0, 1.0);
    } else if (g_strcmp0(key, "SKYWALL_GLASS_ALPHA_BOTTOM") == 0) {
        config->glass_alpha_bottom = clamp_double(g_ascii_strtod(value, NULL), 0.0, 1.0);
    } else if (g_strcmp0(key, "SKYWALL_CARD_GLASS_ALPHA") == 0) {
        config->card_glass_alpha = clamp_double(g_ascii_strtod(value, NULL), 0.0, 1.0);
    } else if (g_strcmp0(key, "SKYWALL_CARD_SHADOW_ALPHA") == 0) {
        config->card_shadow_alpha = clamp_double(g_ascii_strtod(value, NULL), 0.0, 1.0);
    } else if (g_strcmp0(key, "SKYWALL_HOVER_SCALE") == 0) {
        config->hover_scale = clamp_double(g_ascii_strtod(value, NULL), 1.0, 1.4);
    } else if (g_strcmp0(key, "SKYWALL_BORDER_WIDTH") == 0) {
        config->border_width = clamp_double(g_ascii_strtod(value, NULL), 0.5, 8.0);
    } else if (g_strcmp0(key, "SKYWALL_SCROLL_SPEED") == 0) {
        config->scroll_speed = clamp_double(g_ascii_strtod(value, NULL), 20.0, 500.0);
    } else if (g_strcmp0(key, "SKYWALL_SCRIPT") == 0) {
        g_free(config->script_path);
        config->script_path = g_strdup(value);
    } else if (g_strcmp0(key, "SKYWALL_WALLPAPER_DIR") == 0) {
        g_free(config->wallpaper_dir);
        config->wallpaper_dir = g_strdup(value);
    } else if (g_strcmp0(key, "SKYWALL_LAYER_NAMESPACE") == 0) {
        g_free(config->layer_namespace);
        config->layer_namespace = g_strdup(value);
    }
}

static void config_finalize_ranges(SkywallConfig *config) {
    config->min_columns = clamp_int(config->min_columns, 1, 12);
    config->max_columns = clamp_int(config->max_columns, config->min_columns, 16);
    config->columns = clamp_int(config->columns, config->min_columns, config->max_columns);
    config->min_card_width = clamp_int(config->min_card_width, 100, 520);
    config->max_card_width = clamp_int(config->max_card_width, config->min_card_width, 640);
    config->card_width = clamp_int(config->card_width, config->min_card_width, config->max_card_width);
}

static void load_config_file(SkywallConfig *config, const gchar *config_path) {
    gchar *contents = NULL;
    if (!g_file_get_contents(config_path, &contents, NULL, NULL) || contents == NULL) {
        return;
    }

    gchar **lines = g_strsplit(contents, "\n", -1);
    for (gint i = 0; lines[i] != NULL; ++i) {
        gchar *line = g_strstrip(lines[i]);
        if (*line == '\0' || *line == '#') {
            continue;
        }
        gchar **parts = g_strsplit(line, "=", 2);
        if (parts[0] != NULL && parts[1] != NULL) {
            apply_env_entry(config, g_strstrip(parts[0]), g_strstrip(parts[1]));
        }
        g_strfreev(parts);
    }
    g_strfreev(lines);
    g_free(contents);
    config_finalize_ranges(config);
}

static void cli_options_clear(CliOptions *options) {
    g_clear_pointer(&options->config_path, g_free);
    g_clear_pointer(&options->script_override, g_free);
    g_clear_pointer(&options->wallpaper_dir_override, g_free);
}

static gboolean parse_cli_options(gint argc, gchar **argv, CliOptions *options) {
    memset(options, 0, sizeof(*options));
    options->config_path = g_strdup("~/.config/skywall/config.env");

    for (gint i = 1; i < argc; ++i) {
        const gchar *arg = argv[i];
        if ((g_strcmp0(arg, "--help") == 0) || (g_strcmp0(arg, "-h") == 0)) {
            g_print("Usage: skywall-bin [--config PATH] [--script PATH] [--wallpaper-dir PATH] [--windowed] [--fullscreen]\n");
            return FALSE;
        } else if (g_strcmp0(arg, "--config") == 0 && i + 1 < argc) {
            g_free(options->config_path);
            options->config_path = g_strdup(argv[++i]);
        } else if (g_strcmp0(arg, "--script") == 0 && i + 1 < argc) {
            options->script_override = g_strdup(argv[++i]);
        } else if (g_strcmp0(arg, "--wallpaper-dir") == 0 && i + 1 < argc) {
            options->wallpaper_dir_override = g_strdup(argv[++i]);
        } else if (g_strcmp0(arg, "--windowed") == 0) {
            options->force_windowed = TRUE;
        } else if (g_strcmp0(arg, "--fullscreen") == 0) {
            options->force_fullscreen = TRUE;
        }
    }
    return TRUE;
}

static gchar *query_wallpaper_dir(const gchar *script_path) {
    gchar *stdout_text = NULL;
    gchar *argv[] = {(gchar *)script_path, (gchar *)"print-dir", NULL};
    gint status = 0;
    if (!g_spawn_sync(NULL, argv, NULL, G_SPAWN_DEFAULT, NULL, NULL, &stdout_text, NULL, &status, NULL)) {
        g_clear_pointer(&stdout_text, g_free);
        return NULL;
    }
    if (!g_spawn_check_wait_status(status, NULL)) {
        g_clear_pointer(&stdout_text, g_free);
        return NULL;
    }
    if (stdout_text == NULL) {
        return NULL;
    }

    gchar *stripped = g_strstrip(stdout_text);
    if (*stripped == '\0') {
        g_free(stdout_text);
        return NULL;
    }

    gchar *result = expand_path(stripped);
    g_free(stdout_text);
    return result;
}

static gchar *read_current_wallpaper(void) {
    gchar *current_file = g_build_filename(g_get_home_dir(), ".cache", "current_wallpaper", NULL);
    gchar *contents = NULL;
    if (!g_file_get_contents(current_file, &contents, NULL, NULL) || contents == NULL) {
        g_free(current_file);
        return NULL;
    }
    g_free(current_file);

    gchar *stripped = g_strstrip(contents);
    if (*stripped == '\0') {
        g_free(contents);
        return NULL;
    }

    gchar *result = g_strdup(stripped);
    g_free(contents);
    return result;
}

static gboolean has_extension(const gchar *filename, const gchar *const *extensions) {
    gchar *lower = g_ascii_strdown(filename, -1);
    gboolean matched = FALSE;
    for (gint i = 0; extensions[i] != NULL; ++i) {
        if (g_str_has_suffix(lower, extensions[i])) {
            matched = TRUE;
            break;
        }
    }
    g_free(lower);
    return matched;
}

static gboolean is_supported_image(const gchar *filename) {
    return has_extension(filename, image_extensions);
}

static gboolean is_supported_video(const gchar *filename) {
    return has_extension(filename, video_extensions);
}

static void wallpaper_item_free(gpointer data) {
    WallpaperItem *item = data;
    if (item == NULL) {
        return;
    }
    g_clear_pointer(&item->path, g_free);
    g_clear_pointer(&item->name, g_free);
    g_clear_pointer(&item->preview_path, g_free);
    g_clear_object(&item->color_pixbuf);
    g_clear_object(&item->gray_pixbuf);
    g_free(item);
}

static gint wallpaper_compare(gconstpointer left, gconstpointer right, gpointer user_data) {
    const WallpaperItem *a = *(WallpaperItem * const *)left;
    const WallpaperItem *b = *(WallpaperItem * const *)right;
    const gchar *current_path = user_data;
    gboolean a_current = current_path != NULL && g_strcmp0(a->path, current_path) == 0;
    gboolean b_current = current_path != NULL && g_strcmp0(b->path, current_path) == 0;

    if (a_current != b_current) {
        return a_current ? -1 : 1;
    }
    return g_ascii_strcasecmp(a->name, b->name);
}

static GPtrArray *scan_wallpapers(SkywallState *state, const gchar *directory, const gchar *current_path) {
    GPtrArray *items = g_ptr_array_new_with_free_func(wallpaper_item_free);
    GDir *dir = g_dir_open(directory, 0, NULL);
    if (dir == NULL) {
        return items;
    }

    const gchar *name = NULL;
    while ((name = g_dir_read_name(dir)) != NULL) {
        if (!is_supported_image(name) && !is_supported_video(name)) {
            continue;
        }

        gchar *full_path = g_build_filename(directory, name, NULL);
        if (!g_file_test(full_path, G_FILE_TEST_IS_REGULAR)) {
            g_free(full_path);
            continue;
        }

        GStatBuf st;
        if (g_stat(full_path, &st) != 0) {
            g_free(full_path);
            continue;
        }

        WallpaperItem *item = g_new0(WallpaperItem, 1);
        item->path = full_path;
        item->name = g_strdup(name);
        item->is_video = is_supported_video(name);
        item->mtime = (gint64)st.st_mtime;
        item->size = (gint64)st.st_size;
        item->scale = 1.0;
        item->alpha = 1.0;
        metadata_restore_item(state, item);
        if (item->preview_path == NULL && state->cache_dir != NULL) {
            gchar *candidate_preview = preview_path_for(state->cache_dir, item);
            if (candidate_preview != NULL && g_file_test(candidate_preview, G_FILE_TEST_EXISTS)) {
                item->preview_path = candidate_preview;
                metadata_store_item(state, item);
            } else {
                g_free(candidate_preview);
            }
        }
        g_ptr_array_add(items, item);
    }
    g_dir_close(dir);

    g_ptr_array_sort_with_data(items, wallpaper_compare, (gpointer)current_path);
    return items;
}

static gchar *preview_path_for(const gchar *cache_dir, WallpaperItem *item) {
    GStatBuf st;
    if (g_stat(item->path, &st) != 0) {
        return NULL;
    }

    gchar *seed = g_strdup_printf("%s|%" G_GINT64_FORMAT "|%" G_GINT64_FORMAT,
                                  item->path,
                                  (gint64)st.st_mtime,
                                  (gint64)st.st_size);
    gchar *digest = g_compute_checksum_for_string(G_CHECKSUM_SHA1, seed, -1);
    gchar *preview_path = g_build_filename(cache_dir, digest, NULL);
    gchar *result = g_strconcat(preview_path, ".png", NULL);
    g_free(preview_path);
    g_free(digest);
    g_free(seed);
    return result;
}

static gchar *metadata_group_for_path(const gchar *path) {
    return g_compute_checksum_for_string(G_CHECKSUM_SHA1, path, -1);
}

static void metadata_load(SkywallState *state) {
    if (state->metadata != NULL || state->metadata_path == NULL) {
        return;
    }
    state->metadata = g_key_file_new();
    g_key_file_load_from_file(state->metadata, state->metadata_path, G_KEY_FILE_NONE, NULL);
}

static void metadata_save(SkywallState *state) {
    if (state->metadata == NULL || state->metadata_path == NULL || !state->metadata_dirty) {
        return;
    }

    gsize length = 0;
    gchar *data = g_key_file_to_data(state->metadata, &length, NULL);
    if (data != NULL) {
        g_file_set_contents(state->metadata_path, data, (gssize)length, NULL);
        g_free(data);
        state->metadata_dirty = FALSE;
    }
}

static void metadata_remove_item(SkywallState *state, WallpaperItem *item) {
    if (state->metadata == NULL || item == NULL || item->path == NULL) {
        return;
    }
    gchar *group = metadata_group_for_path(item->path);
    if (g_key_file_remove_group(state->metadata, group, NULL)) {
        state->metadata_dirty = TRUE;
    }
    g_free(group);
}

static void metadata_restore_item(SkywallState *state, WallpaperItem *item) {
    if (state->metadata == NULL || item == NULL) {
        return;
    }

    gchar *group = metadata_group_for_path(item->path);
    if (!g_key_file_has_group(state->metadata, group)) {
        g_free(group);
        return;
    }

    gchar *cached_path = g_key_file_get_string(state->metadata, group, "path", NULL);
    gint64 cached_mtime = g_key_file_get_int64(state->metadata, group, "mtime", NULL);
    gint64 cached_size = g_key_file_get_int64(state->metadata, group, "size", NULL);
    gchar *cached_preview = g_key_file_get_string(state->metadata, group, "preview_path", NULL);

    gboolean valid = cached_path != NULL && g_strcmp0(cached_path, item->path) == 0 &&
                     cached_mtime == item->mtime && cached_size == item->size &&
                     cached_preview != NULL && g_file_test(cached_preview, G_FILE_TEST_EXISTS);
    if (valid) {
        item->preview_path = cached_preview;
        cached_preview = NULL;
    } else {
        metadata_remove_item(state, item);
    }

    g_free(cached_preview);
    g_free(cached_path);
    g_free(group);
}

static void metadata_store_item(SkywallState *state, WallpaperItem *item) {
    if (state->metadata == NULL || item == NULL || item->preview_path == NULL) {
        return;
    }

    gchar *group = metadata_group_for_path(item->path);
    g_key_file_set_string(state->metadata, group, "path", item->path);
    g_key_file_set_int64(state->metadata, group, "mtime", item->mtime);
    g_key_file_set_int64(state->metadata, group, "size", item->size);
    g_key_file_set_string(state->metadata, group, "preview_path", item->preview_path);
    state->metadata_dirty = TRUE;
    g_free(group);
}

static gboolean run_ffmpeg(gchar **argv) {
    gint status = 0;
    return g_spawn_sync(NULL, argv, NULL, G_SPAWN_SEARCH_PATH, NULL, NULL, NULL, NULL, &status, NULL)
        && g_spawn_check_wait_status(status, NULL);
}

static gboolean build_preview_file(WallpaperItem *item, const gchar *cache_dir, gchar **out_path) {
    g_mkdir_with_parents(cache_dir, 0755);
    gchar *preview_path = preview_path_for(cache_dir, item);
    if (preview_path == NULL) {
        return FALSE;
    }

    if (g_file_test(preview_path, G_FILE_TEST_EXISTS)) {
        *out_path = preview_path;
        return TRUE;
    }

    gchar *filter_expr = g_strdup_printf("scale=%d:%d:force_original_aspect_ratio=increase,crop=%d:%d",
                                         THUMB_WIDTH,
                                         THUMB_HEIGHT,
                                         THUMB_WIDTH,
                                         THUMB_HEIGHT);

    gboolean ok = FALSE;
    if (item->is_video) {
        gchar *argv_video[] = {
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-i", item->path,
            "-ss", "00:00:01.000",
            "-frames:v", "1",
            "-vf", filter_expr,
            preview_path,
            NULL,
        };
        ok = run_ffmpeg(argv_video);
    }

    if (!ok) {
        gchar *argv_common[] = {
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-i", item->path,
            "-frames:v", "1",
            "-vf", filter_expr,
            preview_path,
            NULL,
        };
        ok = run_ffmpeg(argv_common);
    }

    g_free(filter_expr);
    if (!ok) {
        g_free(preview_path);
        return FALSE;
    }

    *out_path = preview_path;
    return TRUE;
}

static GdkPixbuf *grayscale_pixbuf(GdkPixbuf *pixbuf) {
    GdkPixbuf *gray = gdk_pixbuf_copy(pixbuf);
    if (gray == NULL) {
        return NULL;
    }
    gdk_pixbuf_saturate_and_pixelate(pixbuf, gray, 0.0f, FALSE);
    return gray;
}

static void rounded_rect(cairo_t *cr, gdouble x, gdouble y, gdouble width, gdouble height, gdouble radius) {
    radius = MIN(radius, MIN(width / 2.0, height / 2.0));
    cairo_new_sub_path(cr);
    cairo_arc(cr, x + width - radius, y + radius, radius, -G_PI_2, 0.0);
    cairo_arc(cr, x + width - radius, y + height - radius, radius, 0.0, G_PI_2);
    cairo_arc(cr, x + radius, y + height - radius, radius, G_PI_2, G_PI);
    cairo_arc(cr, x + radius, y + radius, radius, G_PI, G_PI * 1.5);
    cairo_close_path(cr);
}

static void skew_rect(cairo_t *cr, gdouble x, gdouble y, gdouble width, gdouble height, gdouble slant) {
    cairo_new_path(cr);
    cairo_move_to(cr, x + slant, y);
    cairo_line_to(cr, x + width, y);
    cairo_line_to(cr, x + width - slant, y + height);
    cairo_line_to(cr, x, y + height);
    cairo_close_path(cr);
}

static void shape_path(cairo_t *cr, const SkywallConfig *config, gdouble x, gdouble y, gdouble width, gdouble height) {
    if (config->shape == CARD_SHAPE_RECTANGLE) {
        rounded_rect(cr, x, y, width, height, 10.0);
        return;
    }
    if (config->shape == CARD_SHAPE_SOFT) {
        rounded_rect(cr, x, y, width, height, 14.0);
        return;
    }
    skew_rect(cr, x, y, width, height, config->slant * (width / THUMB_WIDTH));
}

static gdouble fitted_card_width_for_columns(const SkywallConfig *config, gint usable_width, gint columns) {
    gdouble stagger_ratio = 0.0;
    if (config->stagger_rows && columns > 1) {
        stagger_ratio = clamp_double(config->row_offset_ratio, 0.0, 1.0);
    }

    gdouble width_units = MAX((gdouble)columns + stagger_ratio, 1.0);
    gdouble spacing_units = MAX(columns - 1, 0) + stagger_ratio;
    return ((gdouble)usable_width - config->spacing * spacing_units) / width_units;
}

static void compute_responsive_geometry(const SkywallConfig *config, gint width, gint *out_columns, gdouble *out_card_width, gdouble *out_card_height) {
    gint usable_width = MAX(320, width - config->padding * 2);
    gint columns = config->columns;

    while (columns < config->max_columns) {
        gint candidate_columns = columns + 1;
        gdouble next_width = fitted_card_width_for_columns(config, usable_width, candidate_columns);
        if (next_width < config->min_card_width) {
            break;
        }
        columns = candidate_columns;
    }

    while (columns > config->min_columns) {
        gdouble current_width = fitted_card_width_for_columns(config, usable_width, columns);
        if (current_width >= config->min_card_width) {
            break;
        }
        columns--;
    }

    // Reserve room for staggered rows so the last card does not clip on the right edge.
    gdouble card_width = fitted_card_width_for_columns(config, usable_width, columns);
    card_width = clamp_double(card_width, config->min_card_width, config->max_card_width);
    gdouble card_height = MAX(80.0, round(card_width / MAX(config->aspect_ratio, 0.5)));

    *out_columns = columns;
    *out_card_width = card_width;
    *out_card_height = card_height;
}

static gdouble compute_layout(SkywallState *state, gint width, gint height, gdouble scroll_current) {
    g_array_set_size(state->layout, 0);
    if (state->items == NULL || state->items->len == 0) {
        return 0.0;
    }

    gint columns = 1;
    gdouble card_width = 0.0;
    gdouble card_height = 0.0;
    compute_responsive_geometry(&state->config, width, &columns, &card_width, &card_height);

    gdouble step_x = card_width + state->config.spacing;
    gdouble step_y = card_height + state->config.row_spacing;
    gint rows = (gint)ceil((gdouble)state->items->len / columns);
    gdouble total_height = rows * card_height + MAX(rows - 1, 0) * state->config.row_spacing;
    gdouble viewport_height = MAX(1.0, height - state->config.padding * 2);
    gdouble start_y = state->config.padding + MAX((viewport_height - total_height) / 2.0, 0.0) + scroll_current;

    for (gint row = 0; row < rows; ++row) {
        gint start_index = row * columns;
        gint row_count = MIN(columns, (gint)state->items->len - start_index);
        gdouble row_offset = 0.0;
        if (state->config.stagger_rows && (row % 2) == 1 && row_count > 1) {
            row_offset = step_x * state->config.row_offset_ratio;
        }
        gdouble row_width = row_count * card_width + MAX(row_count - 1, 0) * state->config.spacing + row_offset;
        gdouble start_x = (width - row_width) / 2.0 + row_offset;
        gdouble row_y = start_y + row * step_y;

        for (gint col = 0; col < row_count; ++col) {
            LayoutItem item = {
                .item = g_ptr_array_index(state->items, start_index + col),
                .x = start_x + col * step_x,
                .y = row_y,
                .width = card_width,
                .height = card_height,
            };
            g_array_append_val(state->layout, item);
        }
    }
    return total_height;
}

static void vertices_for_item(const SkywallConfig *config, const LayoutItem *layout_item, gdouble scale, SkyPoint *out_points) {
    gdouble width = layout_item->width * scale;
    gdouble height = layout_item->height * scale;
    gdouble x = layout_item->x - (width - layout_item->width) / 2.0;
    gdouble y = layout_item->y - (height - layout_item->height) / 2.0;
    if (config->shape == CARD_SHAPE_RECTANGLE) {
        out_points[0] = (SkyPoint){x, y};
        out_points[1] = (SkyPoint){x + width, y};
        out_points[2] = (SkyPoint){x + width, y + height};
        out_points[3] = (SkyPoint){x, y + height};
        return;
    }
    gdouble slant = config->slant * (config->shape == CARD_SHAPE_SOFT ? 0.45 : 1.0) * (width / THUMB_WIDTH);
    out_points[0] = (SkyPoint){x + slant, y};
    out_points[1] = (SkyPoint){x + width, y};
    out_points[2] = (SkyPoint){x + width - slant, y + height};
    out_points[3] = (SkyPoint){x, y + height};
}

static gboolean point_in_polygon(gdouble px, gdouble py, SkyPoint *vertices, gint count) {
    gboolean inside = FALSE;
    gint last = count - 1;
    for (gint index = 0; index < count; ++index) {
        gdouble x1 = vertices[index].x;
        gdouble y1 = vertices[index].y;
        gdouble x2 = vertices[last].x;
        gdouble y2 = vertices[last].y;
        if (((y1 > py) != (y2 > py)) &&
            (px < (x2 - x1) * (py - y1) / ((y2 - y1) == 0.0 ? 1e-6 : (y2 - y1)) + x1)) {
            inside = !inside;
        }
        last = index;
    }
    return inside;
}

static PreviewResult *preview_result_new(SkywallState *state, WallpaperItem *item) {
    PreviewResult *result = g_new0(PreviewResult, 1);
    result->state = state;
    result->item = item;
    return result;
}

static gboolean preview_result_apply(gpointer data) {
    PreviewResult *result = data;
    result->item->preview_pending = FALSE;
    if (result->preview_path != NULL) {
        g_free(result->item->preview_path);
        result->item->preview_path = result->preview_path;
        result->preview_path = NULL;
    }

    if (result->color_pixbuf != NULL) {
        g_clear_object(&result->item->color_pixbuf);
        result->item->color_pixbuf = result->color_pixbuf;
        result->color_pixbuf = NULL;
    }

    if (result->gray_pixbuf != NULL) {
        g_clear_object(&result->item->gray_pixbuf);
        result->item->gray_pixbuf = result->gray_pixbuf;
        result->gray_pixbuf = NULL;
    }

    if (result->item->preview_path != NULL) {
        metadata_store_item(result->state, result->item);
        metadata_save(result->state);
    }

    if (result->state->canvas != NULL) {
        gtk_widget_queue_draw(GTK_WIDGET(result->state->canvas));
    }

    g_clear_pointer(&result->preview_path, g_free);
    g_clear_object(&result->color_pixbuf);
    g_clear_object(&result->gray_pixbuf);
    g_free(result);
    return G_SOURCE_REMOVE;
}

static void load_pixbufs_for_item(SkywallState *state, WallpaperItem *item, gboolean allow_build) {
    if (item == NULL || item->color_pixbuf != NULL) {
        return;
    }

    if (item->preview_path == NULL && allow_build) {
        gchar *built_preview = NULL;
        if (build_preview_file(item, state->cache_dir, &built_preview)) {
            item->preview_path = built_preview;
            metadata_store_item(state, item);
            metadata_save(state);
        }
    }

    if (item->preview_path == NULL || !g_file_test(item->preview_path, G_FILE_TEST_EXISTS)) {
        return;
    }

    GError *error = NULL;
    item->color_pixbuf = gdk_pixbuf_new_from_file(item->preview_path, &error);
    if (error != NULL) {
        g_clear_error(&error);
        g_clear_object(&item->color_pixbuf);
        return;
    }

    if (state->config.grayscale_idle) {
        item->gray_pixbuf = grayscale_pixbuf(item->color_pixbuf);
    }
}

static void preload_initial_pixbufs(SkywallState *state) {
    if (state->items == NULL || state->items->len == 0) {
        return;
    }

    if (state->selected_index >= 0 && state->selected_index < (gint)state->items->len) {
        load_pixbufs_for_item(state, g_ptr_array_index(state->items, state->selected_index), TRUE);
    }

    guint sync_count = MIN((guint)6, state->items->len);
    for (guint i = 0; i < sync_count; ++i) {
        WallpaperItem *item = g_ptr_array_index(state->items, i);
        load_pixbufs_for_item(state, item, FALSE);
    }
}

static void queue_preview_for_item(SkywallState *state, WallpaperItem *item) {
    if (state->preview_pool == NULL || item == NULL) {
        return;
    }
    if (item->preview_pending || item->color_pixbuf != NULL) {
        return;
    }

    item->preview_pending = TRUE;
    PreviewTask *task = g_new0(PreviewTask, 1);
    task->state = state;
    task->item = item;
    g_thread_pool_push(state->preview_pool, task, NULL);
}

static void queue_visible_previews(SkywallState *state, gint width, gint height) {
    if (state->layout == NULL || state->items == NULL) {
        return;
    }

    const gdouble preload_margin = 220.0;
    for (guint i = 0; i < state->layout->len; ++i) {
        LayoutItem *layout_item = &g_array_index(state->layout, LayoutItem, i);
        if (layout_item->y + layout_item->height < -preload_margin || layout_item->y > height + preload_margin) {
            continue;
        }
        queue_preview_for_item(state, layout_item->item);
    }

    if (state->selected_index >= 0 && state->selected_index < (gint)state->items->len) {
        queue_preview_for_item(state, g_ptr_array_index(state->items, state->selected_index));
    }
    (void)width;
}

static void preview_task_run(gpointer data, gpointer user_data) {
    (void)user_data;
    PreviewTask *task = data;
    PreviewResult *result = preview_result_new(task->state, task->item);

    if (task->item->preview_path != NULL && g_file_test(task->item->preview_path, G_FILE_TEST_EXISTS)) {
        result->preview_path = g_strdup(task->item->preview_path);
    } else if (build_preview_file(task->item, task->state->cache_dir, &result->preview_path)) {
    }

    if (result->preview_path != NULL) {
        GError *error = NULL;
        result->color_pixbuf = gdk_pixbuf_new_from_file(result->preview_path, &error);
        if (error != NULL) {
            g_clear_error(&error);
            g_clear_object(&result->color_pixbuf);
        } else if (result->color_pixbuf != NULL && task->state->config.grayscale_idle) {
            result->gray_pixbuf = grayscale_pixbuf(result->color_pixbuf);
        }
    }

    g_idle_add(preview_result_apply, result);
    g_free(task);
}

static gboolean animate_tick(gpointer data) {
    SkywallState *state = data;
    gboolean changed = FALSE;

    if (fabs(state->scroll_target - state->scroll_current) > 0.5) {
        state->scroll_current += (state->scroll_target - state->scroll_current) * 0.18;
        changed = TRUE;
    } else {
        state->scroll_current = state->scroll_target;
    }

    if (state->items != NULL) {
        for (guint i = 0; i < state->items->len; ++i) {
            WallpaperItem *item = g_ptr_array_index(state->items, i);
            gboolean hovered = ((gint)i == state->hovered_index);
            gboolean selected = ((gint)i == state->selected_index);
            gboolean current = state->current_path != NULL && g_strcmp0(item->path, state->current_path) == 0;
            gdouble target_scale = hovered ? state->config.hover_scale : (selected ? 1.02 : 1.0);
            gdouble target_alpha = hovered ? state->config.thumb_hover_alpha
                                           : ((current || selected) ? state->config.thumb_current_alpha : state->config.thumb_idle_alpha);

            gdouble delta_scale = target_scale - item->scale;
            gdouble delta_alpha = target_alpha - item->alpha;
            if (fabs(delta_scale) > 0.002) {
                item->scale += delta_scale * 0.18;
                changed = TRUE;
            } else {
                item->scale = target_scale;
            }
            if (fabs(delta_alpha) > 0.002) {
                item->alpha += delta_alpha * 0.18;
                changed = TRUE;
            } else {
                item->alpha = target_alpha;
            }
        }
    }

    if (changed && state->canvas != NULL) {
        gtk_widget_queue_draw(GTK_WIDGET(state->canvas));
        return G_SOURCE_CONTINUE;
    }

    state->animation_source = 0;
    return G_SOURCE_REMOVE;
}

static void ensure_animation(SkywallState *state) {
    if (state->animation_source == 0) {
        state->animation_source = g_timeout_add(16, animate_tick, state);
    }
}

static gint find_current_index(SkywallState *state) {
    if (state->items == NULL) {
        return -1;
    }
    for (guint i = 0; i < state->items->len; ++i) {
        WallpaperItem *item = g_ptr_array_index(state->items, i);
        if (state->current_path != NULL && g_strcmp0(item->path, state->current_path) == 0) {
            return (gint)i;
        }
    }
    return state->items->len > 0 ? 0 : -1;
}

static void ensure_selected_visible(SkywallState *state) {
    if (state->canvas == NULL || state->selected_index < 0 || state->selected_index >= (gint)state->layout->len) {
        return;
    }

    LayoutItem *layout_item = &g_array_index(state->layout, LayoutItem, state->selected_index);
    gdouble viewport_top = state->config.padding;
    gdouble viewport_bottom = gtk_widget_get_height(GTK_WIDGET(state->canvas)) - state->config.padding;

    if (layout_item->y < viewport_top) {
        state->scroll_target += viewport_top - layout_item->y;
    } else if (layout_item->y + layout_item->height > viewport_bottom) {
        state->scroll_target -= (layout_item->y + layout_item->height) - viewport_bottom;
    }
}

static gint find_directional_index(SkywallState *state, gint direction_x, gint direction_y) {
    if (state->layout == NULL || state->layout->len == 0 || state->selected_index < 0 || state->selected_index >= (gint)state->layout->len) {
        return -1;
    }

    LayoutItem *current = &g_array_index(state->layout, LayoutItem, state->selected_index);
    gdouble current_center_x = current->x + current->width * 0.5;
    gdouble current_center_y = current->y + current->height * 0.5;
    gint best_index = -1;
    gdouble best_score = G_MAXDOUBLE;

    for (guint i = 0; i < state->layout->len; ++i) {
        if ((gint)i == state->selected_index) {
            continue;
        }
        LayoutItem *candidate = &g_array_index(state->layout, LayoutItem, i);
        gdouble candidate_center_x = candidate->x + candidate->width * 0.5;
        gdouble candidate_center_y = candidate->y + candidate->height * 0.5;
        gdouble delta_x = candidate_center_x - current_center_x;
        gdouble delta_y = candidate_center_y - current_center_y;

        if (direction_x < 0 && delta_x >= -1.0) continue;
        if (direction_x > 0 && delta_x <= 1.0) continue;
        if (direction_y < 0 && delta_y >= -1.0) continue;
        if (direction_y > 0 && delta_y <= 1.0) continue;

        gdouble primary = direction_x != 0 ? fabs(delta_x) : fabs(delta_y);
        gdouble secondary = direction_x != 0 ? fabs(delta_y) : fabs(delta_x);
        gdouble score = primary * primary + secondary * secondary * 0.35;
        if (score < best_score) {
            best_score = score;
            best_index = (gint)i;
        }
    }

    return best_index;
}

static void move_selection(SkywallState *state, gint direction_x, gint direction_y) {
    if (state->canvas == NULL || state->items == NULL || state->items->len == 0) {
        return;
    }

    if (state->selected_index < 0) {
        state->selected_index = find_current_index(state);
    }

    compute_layout(state,
                   gtk_widget_get_width(GTK_WIDGET(state->canvas)),
                   gtk_widget_get_height(GTK_WIDGET(state->canvas)),
                   state->scroll_current);

    gint next_index = find_directional_index(state, direction_x, direction_y);
    if (next_index < 0) {
        return;
    }

    state->selected_index = next_index;
    state->hovered_index = -1;
    ensure_selected_visible(state);
    ensure_animation(state);
    gtk_widget_queue_draw(GTK_WIDGET(state->canvas));
}

static void draw_video_icon(cairo_t *cr, gdouble x, gdouble y) {
    cairo_save(cr);
    cairo_translate(cr, x, y);
    cairo_move_to(cr, 0.0, 0.0);
    cairo_line_to(cr, 0.0, 12.0);
    cairo_line_to(cr, 10.0, 6.0);
    cairo_close_path(cr);
    cairo_set_source_rgba(cr, 1.0, 1.0, 1.0, 0.70);
    cairo_fill(cr);
    cairo_restore(cr);
}

static void draw_item(SkywallState *state, cairo_t *cr, const LayoutItem *layout_item, gboolean hovered) {
    WallpaperItem *item = layout_item->item;
    gboolean current = state->current_path != NULL && g_strcmp0(item->path, state->current_path) == 0;
    gdouble width = layout_item->width * item->scale;
    gdouble height = layout_item->height * item->scale;
    gdouble x = layout_item->x - (width - layout_item->width) / 2.0;
    gdouble y = layout_item->y - (height - layout_item->height) / 2.0;

    if (hovered || current) {
        shape_path(cr, &state->config, x + 2.0, y + 8.0, width, height);
        cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, state->config.card_shadow_alpha * (hovered ? 1.15 : 0.75));
        cairo_fill(cr);
    }

    shape_path(cr, &state->config, x, y, width, height);
    cairo_set_source_rgba(cr, 0.10, 0.13, 0.18, state->config.card_glass_alpha);
    cairo_fill_preserve(cr);
    cairo_clip(cr);

    GdkPixbuf *pixbuf = (hovered || current || !state->config.grayscale_idle)
                            ? item->color_pixbuf
                            : item->gray_pixbuf;
    if (pixbuf != NULL) {
        cairo_save(cr);
        cairo_translate(cr, x, y);
        cairo_scale(cr,
                    width / gdk_pixbuf_get_width(pixbuf),
                    height / gdk_pixbuf_get_height(pixbuf));
        gdk_cairo_set_source_pixbuf(cr, pixbuf, 0.0, 0.0);
        cairo_paint_with_alpha(cr, item->alpha);
        cairo_restore(cr);
    } else {
        cairo_pattern_t *pattern = cairo_pattern_create_linear(x, y, x, y + height);
        cairo_pattern_add_color_stop_rgba(pattern, 0.0, 0.18, 0.19, 0.26, 0.40);
        cairo_pattern_add_color_stop_rgba(pattern, 1.0, 0.10, 0.11, 0.16, 0.24);
        cairo_set_source(cr, pattern);
        cairo_paint(cr);
        cairo_pattern_destroy(pattern);
    }
    cairo_reset_clip(cr);

    if (current) {
        cairo_set_source_rgba(cr, 1.0, 0.80, 0.90, 0.96);
    } else if (hovered) {
        cairo_set_source_rgba(cr, 1.0, 1.0, 1.0, 0.82);
    } else {
        cairo_set_source_rgba(cr, 1.0, 1.0, 1.0, 0.04);
    }
    shape_path(cr, &state->config, x, y, width, height);
    cairo_set_line_width(cr, state->config.border_width);
    cairo_stroke(cr);

    if (item->is_video && state->config.show_video_icon) {
        draw_video_icon(cr, x + width - 22.0, y + 16.0);
    }
}

static void draw_background(SkywallState *state, cairo_t *cr, gint width, gint height) {
    cairo_rectangle(cr, 0.0, 0.0, width, height);
    cairo_set_source_rgba(cr,
                          0.08,
                          0.10,
                          0.14,
                          (state->config.glass_alpha_top + state->config.glass_alpha_bottom) * 0.5);
    cairo_fill(cr);

    cairo_pattern_t *sheen = cairo_pattern_create_linear(0.0, 0.0, 0.0, height * 0.38);
    cairo_pattern_add_color_stop_rgba(sheen, 0.0, 1.0, 1.0, 1.0, 0.030);
    cairo_pattern_add_color_stop_rgba(sheen, 1.0, 1.0, 1.0, 1.0, 0.0);
    cairo_rectangle(cr, 0.0, 0.0, width, height);
    cairo_set_source(cr, sheen);
    cairo_fill(cr);
    cairo_pattern_destroy(sheen);

    (void)state;
}

static gboolean hit_test_index(SkywallState *state, gdouble x, gdouble y, gint *out_index) {
    for (gint i = (gint)state->layout->len - 1; i >= 0; --i) {
        LayoutItem *layout_item = &g_array_index(state->layout, LayoutItem, i);
        SkyPoint vertices[4];
        vertices_for_item(&state->config, layout_item, layout_item->item->scale, vertices);
        if (point_in_polygon(x, y, vertices, 4)) {
            *out_index = i;
            return TRUE;
        }
    }
    return FALSE;
}

static gboolean on_scroll(GtkEventControllerScroll *controller, gdouble dx, gdouble dy, gpointer user_data) {
    (void)controller;
    (void)dx;
    SkywallState *state = user_data;
    if (state->canvas == NULL) {
        return TRUE;
    }

    gdouble total_height = compute_layout(state,
                                          gtk_widget_get_width(GTK_WIDGET(state->canvas)),
                                          gtk_widget_get_height(GTK_WIDGET(state->canvas)),
                                          state->scroll_current);
    gdouble viewport_height = MAX(1.0, gtk_widget_get_height(GTK_WIDGET(state->canvas)) - state->config.padding * 2);
    gdouble max_scroll = MAX(0.0, total_height - viewport_height);
    if (max_scroll <= 0.0) {
        return TRUE;
    }

    state->scroll_target -= dy * state->config.scroll_speed;
    state->scroll_target = MAX(-max_scroll, MIN(0.0, state->scroll_target));
    ensure_animation(state);
    return TRUE;
}

static void on_motion(GtkEventControllerMotion *controller, gdouble x, gdouble y, gpointer user_data) {
    (void)controller;
    SkywallState *state = user_data;
    gint hovered = -1;
    if (hit_test_index(state, x, y, &hovered)) {
        if (hovered != state->hovered_index) {
            state->hovered_index = hovered;
            state->selected_index = hovered;
            ensure_animation(state);
        }
    } else if (state->hovered_index != -1) {
        state->hovered_index = -1;
        ensure_animation(state);
    }
}

static void on_leave(GtkEventControllerMotion *controller, gpointer user_data) {
    (void)controller;
    SkywallState *state = user_data;
    if (state->hovered_index != -1) {
        state->hovered_index = -1;
        ensure_animation(state);
    }
}

static void apply_wallpaper(SkywallState *state, WallpaperItem *item, gdouble rel_x, gdouble rel_y) {
    gchar *rel_x_text = g_strdup_printf("%.3f", rel_x);
    gchar *rel_y_text = g_strdup_printf("%.3f", rel_y);
    gchar *argv[] = {
        state->config.script_path,
        (gchar *)"pick",
        item->path,
        rel_x_text,
        rel_y_text,
        NULL,
    };
    g_spawn_async(NULL, argv, NULL, G_SPAWN_DEFAULT, NULL, NULL, NULL, NULL);
    g_free(rel_x_text);
    g_free(rel_y_text);
    g_application_quit(G_APPLICATION(state->application));
}

static void on_click(GtkGestureClick *gesture, gint n_press, gdouble x, gdouble y, gpointer user_data) {
    (void)gesture;
    (void)n_press;
    SkywallState *state = user_data;
    gint index = -1;
    if (!hit_test_index(state, x, y, &index)) {
        return;
    }

    state->selected_index = index;
    LayoutItem *layout_item = &g_array_index(state->layout, LayoutItem, index);
    gdouble rel_x = clamp_double(x / MAX(1.0, gtk_widget_get_width(GTK_WIDGET(state->canvas))), 0.0, 1.0);
    gdouble rel_y = clamp_double(y / MAX(1.0, gtk_widget_get_height(GTK_WIDGET(state->canvas))), 0.0, 1.0);
    apply_wallpaper(state, layout_item->item, rel_x, rel_y);
}

static gboolean on_key_pressed(GtkEventControllerKey *controller, guint keyval, guint keycode, GdkModifierType state_flags, gpointer user_data) {
    (void)controller;
    (void)keycode;
    (void)state_flags;
    SkywallState *state = user_data;
    if (keyval == GDK_KEY_Escape) {
        g_application_quit(G_APPLICATION(state->application));
        return TRUE;
    }

    if (keyval == GDK_KEY_Left) {
        move_selection(state, -1, 0);
        return TRUE;
    }
    if (keyval == GDK_KEY_Right) {
        move_selection(state, 1, 0);
        return TRUE;
    }
    if (keyval == GDK_KEY_Up) {
        move_selection(state, 0, -1);
        return TRUE;
    }
    if (keyval == GDK_KEY_Down) {
        move_selection(state, 0, 1);
        return TRUE;
    }
    if (keyval == GDK_KEY_Return || keyval == GDK_KEY_KP_Enter || keyval == GDK_KEY_space) {
        if (state->selected_index >= 0 && state->selected_index < (gint)state->layout->len) {
            LayoutItem *layout_item = &g_array_index(state->layout, LayoutItem, state->selected_index);
            gdouble rel_x = clamp_double((layout_item->x + layout_item->width * 0.5) / MAX(1.0, gtk_widget_get_width(GTK_WIDGET(state->canvas))), 0.0, 1.0);
            gdouble rel_y = clamp_double((layout_item->y + layout_item->height * 0.5) / MAX(1.0, gtk_widget_get_height(GTK_WIDGET(state->canvas))), 0.0, 1.0);
            apply_wallpaper(state, layout_item->item, rel_x, rel_y);
            return TRUE;
        }
    }
    return FALSE;
}

static void draw_cb(GtkDrawingArea *area, cairo_t *cr, gint width, gint height, gpointer user_data) {
    (void)area;
    SkywallState *state = user_data;
    draw_background(state, cr, width, height);
    gdouble total_height = compute_layout(state, width, height, state->scroll_current);
    queue_visible_previews(state, width, height);
    gdouble viewport_height = MAX(1.0, height - state->config.padding * 2);
    gdouble max_scroll = MAX(0.0, total_height - viewport_height);
    state->scroll_target = MAX(-max_scroll, MIN(0.0, state->scroll_target));

    for (guint i = 0; i < state->layout->len; ++i) {
        if ((gint)i == state->hovered_index || ((gint)i == state->selected_index && state->hovered_index != state->selected_index)) {
            continue;
        }
        LayoutItem *layout_item = &g_array_index(state->layout, LayoutItem, i);
        if (layout_item->y + layout_item->height < -80.0 || layout_item->y > height + 80.0) {
            continue;
        }
        draw_item(state, cr, layout_item, FALSE);
    }

    if (state->hovered_index >= 0 && state->hovered_index < (gint)state->layout->len) {
        LayoutItem *layout_item = &g_array_index(state->layout, LayoutItem, state->hovered_index);
        draw_item(state, cr, layout_item, TRUE);
    } else if (state->selected_index >= 0 && state->selected_index < (gint)state->layout->len) {
        LayoutItem *layout_item = &g_array_index(state->layout, LayoutItem, state->selected_index);
        draw_item(state, cr, layout_item, TRUE);
    }
}

static void install_css(void) {
    GtkCssProvider *provider = gtk_css_provider_new();
    gtk_css_provider_load_from_string(
        provider,
        "window.skywall-window, box.skywall-root, drawingarea.skywall-canvas { background: transparent; }"
        "label.skywall-empty { color: rgba(235,239,255,0.92); font-size: 22px; }");
    GdkDisplay *display = gdk_display_get_default();
    if (display != NULL) {
        gtk_style_context_add_provider_for_display(display,
                                                   GTK_STYLE_PROVIDER(provider),
                                                   GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
    g_object_unref(provider);
}

static void prime_previews(SkywallState *state) {
    if (state->preview_pool == NULL || state->items == NULL) {
        return;
    }
    if (state->selected_index >= 0 && state->selected_index < (gint)state->items->len) {
        queue_preview_for_item(state, g_ptr_array_index(state->items, state->selected_index));
    }
    guint initial_count = MIN((guint)8, state->items->len);
    for (guint i = 0; i < initial_count; ++i) {
        queue_preview_for_item(state, g_ptr_array_index(state->items, i));
    }
}

static void ensure_content_loaded(SkywallState *state) {
    if (state->items != NULL) {
        return;
    }

    gchar *script_path = expand_path(state->config.script_path);
    g_free(state->config.script_path);
    state->config.script_path = script_path;

    if (state->config.wallpaper_dir != NULL && *state->config.wallpaper_dir != '\0') {
        state->resolved_wallpaper_dir = expand_path(state->config.wallpaper_dir);
    } else {
        state->resolved_wallpaper_dir = query_wallpaper_dir(state->config.script_path);
        if (state->resolved_wallpaper_dir == NULL) {
            state->resolved_wallpaper_dir = g_build_filename(g_get_home_dir(), "meus-dotfiles", "wallpapers", NULL);
        }
    }

    state->current_path = read_current_wallpaper();
    state->cache_dir = g_build_filename(g_get_home_dir(), ".cache", "skywall", "previews", NULL);
    g_mkdir_with_parents(state->cache_dir, 0755);
    state->metadata_path = g_build_filename(g_get_home_dir(), ".cache", "skywall", "metadata.ini", NULL);
    metadata_load(state);
    state->items = scan_wallpapers(state, state->resolved_wallpaper_dir, state->current_path);
    metadata_save(state);
    state->selected_index = find_current_index(state);
    state->layout = g_array_new(FALSE, FALSE, sizeof(LayoutItem));
    if (state->preview_pool == NULL) {
        state->preview_pool = g_thread_pool_new(preview_task_run,
                                                NULL,
                                                MAX(2, MIN(3, g_get_num_processors())),
                                                FALSE,
                                                NULL);
    }
}

static void on_activate(GApplication *application, gpointer user_data) {
    SkywallState *state = user_data;
    if (state->window != NULL) {
        gtk_window_present(state->window);
        if (state->canvas != NULL) {
            gtk_widget_grab_focus(GTK_WIDGET(state->canvas));
        }
        return;
    }

    ensure_content_loaded(state);
    preload_initial_pixbufs(state);
    install_css();

    state->window = GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
    gtk_window_set_title(state->window, "Skywall");
    gtk_window_set_decorated(state->window, FALSE);
    gtk_widget_add_css_class(GTK_WIDGET(state->window), "skywall-window");

    if (state->config.fullscreen) {
        gtk_layer_init_for_window(state->window);
        gtk_layer_set_layer(state->window, GTK_LAYER_SHELL_LAYER_OVERLAY);
        gtk_layer_set_namespace(state->window, state->config.layer_namespace);
        gtk_layer_set_keyboard_mode(state->window, GTK_LAYER_SHELL_KEYBOARD_MODE_ON_DEMAND);
        gtk_layer_set_exclusive_zone(state->window, -1);
        gtk_layer_set_anchor(state->window, GTK_LAYER_SHELL_EDGE_TOP, TRUE);
        gtk_layer_set_anchor(state->window, GTK_LAYER_SHELL_EDGE_BOTTOM, TRUE);
        gtk_layer_set_anchor(state->window, GTK_LAYER_SHELL_EDGE_LEFT, TRUE);
        gtk_layer_set_anchor(state->window, GTK_LAYER_SHELL_EDGE_RIGHT, TRUE);
        gtk_layer_set_margin(state->window, GTK_LAYER_SHELL_EDGE_TOP, 0);
        gtk_layer_set_margin(state->window, GTK_LAYER_SHELL_EDGE_BOTTOM, 0);
        gtk_layer_set_margin(state->window, GTK_LAYER_SHELL_EDGE_LEFT, 0);
        gtk_layer_set_margin(state->window, GTK_LAYER_SHELL_EDGE_RIGHT, 0);
    } else {
        gtk_window_set_default_size(state->window, state->config.width, state->config.height);
    }

    GtkWidget *root = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_widget_add_css_class(root, "skywall-root");
    gtk_window_set_child(state->window, root);

    if (state->items == NULL || state->items->len == 0) {
        gchar *label_text = g_strdup_printf("No supported wallpapers found in\n%s",
                                            state->resolved_wallpaper_dir != NULL ? state->resolved_wallpaper_dir : "(unknown)");
        GtkWidget *label = gtk_label_new(label_text);
        g_free(label_text);
        gtk_widget_add_css_class(label, "skywall-empty");
        gtk_widget_set_halign(label, GTK_ALIGN_CENTER);
        gtk_widget_set_valign(label, GTK_ALIGN_CENTER);
        gtk_box_append(GTK_BOX(root), label);
        gtk_window_present(state->window);
        return;
    }

    state->canvas = GTK_DRAWING_AREA(gtk_drawing_area_new());
    gtk_widget_add_css_class(GTK_WIDGET(state->canvas), "skywall-canvas");
    gtk_widget_set_hexpand(GTK_WIDGET(state->canvas), TRUE);
    gtk_widget_set_vexpand(GTK_WIDGET(state->canvas), TRUE);
    gtk_widget_set_focusable(GTK_WIDGET(state->canvas), TRUE);
    gtk_drawing_area_set_draw_func(state->canvas, draw_cb, state, NULL);

    GtkEventController *motion = gtk_event_controller_motion_new();
    g_signal_connect(motion, "motion", G_CALLBACK(on_motion), state);
    g_signal_connect(motion, "leave", G_CALLBACK(on_leave), state);
    gtk_widget_add_controller(GTK_WIDGET(state->canvas), motion);

    GtkGesture *click = GTK_GESTURE(gtk_gesture_click_new());
    gtk_gesture_single_set_button(GTK_GESTURE_SINGLE(click), GDK_BUTTON_PRIMARY);
    g_signal_connect(click, "released", G_CALLBACK(on_click), state);
    gtk_widget_add_controller(GTK_WIDGET(state->canvas), GTK_EVENT_CONTROLLER(click));

    GtkEventController *scroll = gtk_event_controller_scroll_new(GTK_EVENT_CONTROLLER_SCROLL_VERTICAL);
    g_signal_connect(scroll, "scroll", G_CALLBACK(on_scroll), state);
    gtk_widget_add_controller(GTK_WIDGET(state->canvas), scroll);

    GtkEventController *keys = gtk_event_controller_key_new();
    g_signal_connect(keys, "key-pressed", G_CALLBACK(on_key_pressed), state);
    gtk_widget_add_controller(GTK_WIDGET(state->canvas), keys);

    gtk_box_append(GTK_BOX(root), GTK_WIDGET(state->canvas));
    gtk_window_present(state->window);
    gtk_widget_grab_focus(GTK_WIDGET(state->canvas));
    prime_previews(state);
}

static void on_shutdown(GApplication *application, gpointer user_data) {
    (void)application;
    SkywallState *state = user_data;
    if (state->animation_source != 0) {
        g_source_remove(state->animation_source);
        state->animation_source = 0;
    }
}

static SkywallState *skywall_state_new(const CliOptions *options) {
    SkywallState *state = g_new0(SkywallState, 1);
    config_init_defaults(&state->config);
    state->config_path = expand_path(options->config_path);
    load_config_file(&state->config, state->config_path);

    if (options->script_override != NULL) {
        g_free(state->config.script_path);
        state->config.script_path = g_strdup(options->script_override);
    }
    if (options->wallpaper_dir_override != NULL) {
        g_free(state->config.wallpaper_dir);
        state->config.wallpaper_dir = g_strdup(options->wallpaper_dir_override);
    }
    if (options->force_windowed) {
        state->config.fullscreen = FALSE;
    }
    if (options->force_fullscreen) {
        state->config.fullscreen = TRUE;
    }

    state->hovered_index = -1;
    state->selected_index = -1;
    state->scroll_target = 0.0;
    state->scroll_current = 0.0;
    return state;
}

static void skywall_state_free(SkywallState *state) {
    if (state == NULL) {
        return;
    }
    if (state->preview_pool != NULL) {
        g_thread_pool_free(state->preview_pool, FALSE, TRUE);
    }
    g_clear_object(&state->application);
    g_clear_pointer(&state->items, g_ptr_array_unref);
    g_clear_pointer(&state->layout, g_array_unref);
    g_clear_pointer(&state->config_path, g_free);
    g_clear_pointer(&state->current_path, g_free);
    g_clear_pointer(&state->resolved_wallpaper_dir, g_free);
    g_clear_pointer(&state->cache_dir, g_free);
    metadata_save(state);
    g_clear_pointer(&state->metadata_path, g_free);
    g_clear_pointer(&state->metadata, g_key_file_unref);
    config_clear(&state->config);
    g_free(state);
}

int main(int argc, char **argv) {
    CliOptions options;
    if (!parse_cli_options(argc, argv, &options)) {
        cli_options_clear(&options);
        return 0;
    }

    SkywallState *state = skywall_state_new(&options);
    cli_options_clear(&options);

    state->application = gtk_application_new(APP_ID, G_APPLICATION_DEFAULT_FLAGS);
    g_signal_connect(state->application, "activate", G_CALLBACK(on_activate), state);
    g_signal_connect(state->application, "shutdown", G_CALLBACK(on_shutdown), state);

    char *app_argv[] = {argv[0], NULL};
    int status = g_application_run(G_APPLICATION(state->application), 1, app_argv);
    skywall_state_free(state);
    return status;
}
