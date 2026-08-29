<?php
/**
 * Plugin Name: Sampathi News Core Integrator
 * Description: Headless CMS Custom CPTs, REST API endpoints, Automated Ads Scheduler, and Ads Analytics for Sampathi News.
 * Version: 1.0.0
 * Author: Principal Architect
 * Text Domain: sampathi-news-core
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit; // Exit if accessed directly.
}

// Define Constants
define( 'SAMPATHI_NEWS_CORE_PATH', plugin_dir_path( __FILE__ ) );
define( 'SAMPATHI_NEWS_CORE_URL', plugin_dir_url( __FILE__ ) );

// Include required files
require_once SAMPATHI_NEWS_CORE_PATH . 'includes/acf-fields-bootstrap.php';
require_once SAMPATHI_NEWS_CORE_PATH . 'includes/wp-cron-scheduler.php';
require_once SAMPATHI_NEWS_CORE_PATH . 'includes/ads-analytics-db.php';
require_once SAMPATHI_NEWS_CORE_PATH . 'admin/ads-dashboard.php';
require_once SAMPATHI_NEWS_CORE_PATH . 'admin/publish-news-page.php';

// --- CORS: allow the Flutter web app (a different origin, e.g.
// localhost:PORT) to call this REST API with our custom X-Sampathi-Token
// header. WordPress's default CORS headers only allow a small built-in set
// of headers, so any custom header (like ours) fails the browser's
// preflight OPTIONS check unless we explicitly allow it here.
add_action( 'rest_api_init', function () {
    remove_filter( 'rest_pre_serve_request', 'rest_send_cors_headers' );

    add_filter( 'rest_pre_serve_request', function ( $value ) {
        $origin = get_http_origin();
        header( 'Access-Control-Allow-Origin: ' . ( $origin ? esc_url_raw( $origin ) : '*' ) );
        header( 'Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE' );
        header( 'Access-Control-Allow-Credentials: true' );
        header( 'Access-Control-Allow-Headers: Content-Type, X-WP-Nonce, X-Sampathi-Token, Authorization' );
        return $value;
    } );
}, 15 );

// Explicitly answer the preflight OPTIONS request itself with a 200 and no
// body, before WordPress tries to route it anywhere — some setups otherwise
// return a 404/redirect for OPTIONS, which also fails the browser's check.
add_action( 'init', function () {
    if ( isset( $_SERVER['REQUEST_METHOD'] ) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS'
        && isset( $_SERVER['REQUEST_URI'] ) && strpos( $_SERVER['REQUEST_URI'], '/wp-json/sampathi/' ) !== false
    ) {
        $origin = get_http_origin();
        header( 'Access-Control-Allow-Origin: ' . ( $origin ? esc_url_raw( $origin ) : '*' ) );
        header( 'Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE' );
        header( 'Access-Control-Allow-Credentials: true' );
        header( 'Access-Control-Allow-Headers: Content-Type, X-WP-Nonce, X-Sampathi-Token, Authorization' );
        status_header( 200 );
        exit;
    }
} );

// Register Custom Post Types and Taxonomies
add_action( 'init', 'sampathi_news_register_cpts' );
function sampathi_news_register_cpts() {
    // 1. Districts Custom Post Type / Custom Taxonomy
    // (We will use a Custom Post Type so we can attach metadata, custom layout parameters, or specific localized ads, or register it as a taxonomy)
    register_post_type( 'district', [
        'labels' => [
            'name' => 'Districts',
            'singular_name' => 'District',
            'add_new_item' => 'Add New District',
            'edit_item' => 'Edit District',
        ],
        'public' => true,
        'has_archive' => true,
        'show_in_rest' => true,
        'supports' => [ 'title', 'slug', 'editor', 'thumbnail' ],
        'menu_icon' => 'dashicons-location-alt',
    ]);

    // 2. Reporters Custom Post Type
    register_post_type( 'reporter', [
        'labels' => [
            'name' => 'Reporters',
            'singular_name' => 'Reporter',
            'add_new_item' => 'Add New Reporter',
        ],
        'public' => true,
        'show_in_rest' => true,
        'supports' => [ 'title', 'editor', 'thumbnail' ],
        'menu_icon' => 'dashicons-admin-users',
    ]);

    // 3. Advertisements Custom Post Type
    register_post_type( 'advertisement', [
        'labels' => [
            'name' => 'Advertisements',
            'singular_name' => 'Advertisement',
            'add_new_item' => 'Book New Advertisement',
            'edit_item' => 'Edit Advertisement',
        ],
        'public' => true,
        'show_in_rest' => true,
        'supports' => [ 'title', 'custom-fields' ],
        'menu_icon' => 'dashicons-megaphone',
    ]);
}

// Register Headless Custom REST API routes
add_action( 'rest_api_init', 'sampathi_news_register_api_endpoints' );
function sampathi_news_register_api_endpoints() {
    
    // Get list of optimized news articles
    register_rest_route( 'sampathi/v1', '/news', [
        'methods' => 'GET',
        'callback' => 'sampathi_news_get_all_news',
        'permission_callback' => '__return_true',
    ]);

    // Get specific news article detail
    register_rest_route( 'sampathi/v1', '/news/(?P<id>\d+)', [
        'methods' => 'GET',
        'callback' => 'sampathi_news_get_news_detail',
        'permission_callback' => '__return_true',
    ]);

    // Get active advertisements matching criteria
    register_rest_route( 'sampathi/v1', '/ads', [
        'methods' => 'GET',
        'callback' => 'sampathi_news_get_active_ads',
        'permission_callback' => '__return_true',
    ]);

    // Track advertisement clicks / impressions
    register_rest_route( 'sampathi/v1', '/ads/track', [
        'methods' => 'POST',
        'callback' => 'sampathi_news_track_ad_activity',
        'permission_callback' => '__return_true',
    ]);

    // Get standard category listing
    register_rest_route( 'sampathi/v1', '/categories', [
        'methods' => 'GET',
        'callback' => 'sampathi_news_get_categories',
        'permission_callback' => '__return_true',
    ]);

    // Get district listing
    register_rest_route( 'sampathi/v1', '/districts', [
        'methods' => 'GET',
        'callback' => 'sampathi_news_get_districts',
        'permission_callback' => '__return_true',
    ]);

    // Admin login from the Flutter app: verifies a real WordPress user's
    // username + password (sent in the JSON body, never as a header) and
    // returns a custom token. This deliberately avoids the "Authorization"
    // header, which some local dev servers (e.g. Local by Flywheel's Nginx)
    // strip before PHP ever sees it.
    register_rest_route( 'sampathi/v1', '/auth/login', [
        'methods' => 'POST',
        'callback' => 'sampathi_news_admin_login',
        'permission_callback' => '__return_true',
    ]);

    // Streams an image from the Media Library back with an explicit
    // Access-Control-Allow-Origin header. Plain static file URLs
    // (/wp-content/uploads/...) are served directly by Nginx, bypassing
    // WordPress/PHP entirely — so no CORS header can be attached to them
    // without editing server config. A REST route, however, always goes
    // through PHP, so we can add the header here. This lets the Flutter
    // app keep using its normal (fast) CanvasKit renderer, which requires
    // CORS to read cross-origin image bytes.
    register_rest_route( 'sampathi/v1', '/image-proxy', [
        'methods' => 'GET',
        'callback' => 'sampathi_news_image_proxy',
        'permission_callback' => '__return_true', // images are public content
    ]);

    // Returns the logged-in user's profile (name, email, phone, avatar) for
    // the Flutter app's reader-facing Profile tab. Requires login — the
    // Profile tab itself is viewable without logging in, but this endpoint
    // is only called once a token exists (i.e. after logging in).
    register_rest_route( 'sampathi/v1', '/auth/me', [
        'methods' => 'GET',
        'callback' => 'sampathi_news_get_profile',
        'permission_callback' => function ( $request ) {
            sampathi_authenticate_via_token( $request );
            return is_user_logged_in();
        },
    ]);

    // Updates the logged-in user's display name, phone, and/or avatar.
    register_rest_route( 'sampathi/v1', '/auth/update-profile', [
        'methods' => 'POST',
        'callback' => 'sampathi_news_update_profile',
        'permission_callback' => function ( $request ) {
            sampathi_authenticate_via_token( $request );
            return is_user_logged_in();
        },
    ]);

    // Create a new Category, from the Flutter admin app's Publish News page.
    register_rest_route( 'sampathi/v1', '/categories/add', [
        'methods' => 'POST',
        'callback' => 'sampathi_news_create_category',
        'permission_callback' => function ( $request ) {
            sampathi_authenticate_via_token( $request );
            return current_user_can( 'manage_categories' );
        },
    ]);

    // Create a new District, from the Flutter admin app's Publish News page.
    register_rest_route( 'sampathi/v1', '/districts/add', [
        'methods' => 'POST',
        'callback' => 'sampathi_news_create_district',
        'permission_callback' => function ( $request ) {
            sampathi_authenticate_via_token( $request );
            return current_user_can( 'publish_posts' );
        },
    ]);

    // Create a news article — accepts EITHER a logged-in WP session + nonce
    // (from the wp-admin "Publish News" page) OR the custom token from the
    // Flutter admin app (see sampathi_authenticate_via_token below).
    register_rest_route( 'sampathi/v1', '/news/add', [
        'methods' => 'POST',
        'callback' => 'sampathi_news_create_news_article',
        'permission_callback' => function ( $request ) {
            sampathi_authenticate_via_token( $request );
            return current_user_can( 'publish_posts' );
        },
    ]);

    // Book a new advertisement — same dual-auth pattern as /news/add.
    register_rest_route( 'sampathi/v1', '/ads/add', [
        'methods' => 'POST',
        'callback' => 'sampathi_news_create_ad',
        'permission_callback' => function ( $request ) {
            sampathi_authenticate_via_token( $request );
            return current_user_can( 'publish_posts' );
        },
    ]);

    // Upload an image into the WordPress Media Library from the Flutter
    // admin app. The core /wp/v2/media endpoint only recognizes WordPress's
    // own auth methods (cookie+nonce, Application Passwords) — this proxy
    // additionally accepts our custom X-Sampathi-Token header, giving the
    // Flutter app the same "upload a file" ability the wp-admin pages have.
    register_rest_route( 'sampathi/v1', '/media/upload', [
        'methods' => 'POST',
        'callback' => 'sampathi_news_upload_media',
        'permission_callback' => function ( $request ) {
            sampathi_authenticate_via_token( $request );
            return current_user_can( 'upload_files' );
        },
    ]);

    // Full advertisement campaign list (any status: active, scheduled,
    // expired) for the Flutter admin "Ad Dashboard" page's campaigns table —
    // mirrors what the wp-admin Ad Dashboard page already shows.
    register_rest_route( 'sampathi/v1', '/ads/all', [
        'methods' => 'GET',
        'callback' => 'sampathi_news_get_all_ads',
        'permission_callback' => function ( $request ) {
            sampathi_authenticate_via_token( $request );
            return current_user_can( 'publish_posts' );
        },
    ]);

    // Manually change a campaign's status (scheduled / active / inactive) —
    // used by both the Flutter and wp-admin campaigns tables' status editor.
    register_rest_route( 'sampathi/v1', '/ads/update-status', [
        'methods' => 'POST',
        'callback' => 'sampathi_news_update_ad_status',
        'permission_callback' => function ( $request ) {
            sampathi_authenticate_via_token( $request );
            return current_user_can( 'publish_posts' );
        },
    ]);
}

// If the request carries our custom X-Sampathi-Token header, look up which
// user it belongs to and set them as the current user for this request —
// this is what makes current_user_can() return true for Flutter's requests.
function sampathi_authenticate_via_token( $request ) {
    $token = $request->get_header( 'x_sampathi_token' );
    if ( empty( $token ) ) {
        return;
    }

    $users = get_users( [
        'meta_key'   => 'sampathi_admin_token',
        'meta_value' => sanitize_text_field( $token ),
        'number'     => 1,
    ] );

    if ( empty( $users ) ) {
        return;
    }

    $user = $users[0];
    $expires = (int) get_user_meta( $user->ID, 'sampathi_admin_token_expires', true );
    if ( $expires && $expires < time() ) {
        return; // Token expired — leave the user unauthenticated.
    }

    wp_set_current_user( $user->ID );
}

function sampathi_news_admin_login( $request ) {
    $params = $request->get_json_params();
    $username = sanitize_text_field( $params['username'] ?? '' );
    $password = $params['password'] ?? '';

    if ( empty( $username ) || empty( $password ) ) {
        return new WP_Error( 'missing_credentials', 'Username and password are required.', [ 'status' => 400 ] );
    }

    $user = wp_authenticate( $username, $password );

    if ( is_wp_error( $user ) ) {
        return new WP_Error( 'invalid_login', 'Invalid username or password.', [ 'status' => 401 ] );
    }

    if ( ! user_can( $user, 'publish_posts' ) ) {
        return new WP_Error( 'insufficient_permission', 'This user is not allowed to publish content.', [ 'status' => 403 ] );
    }

    $token = wp_generate_password( 40, false );
    update_user_meta( $user->ID, 'sampathi_admin_token', $token );
    update_user_meta( $user->ID, 'sampathi_admin_token_expires', time() + ( 30 * DAY_IN_SECONDS ) );

    return rest_ensure_response( [
        'success' => true,
        'token'   => $token,
        'user'    => [
            'id'   => $user->ID,
            'name' => $user->display_name,
        ],
    ] );
}

// Allow Application Passwords over plain HTTP for LOCAL DEV ONLY.
// WordPress core normally requires HTTPS for app passwords for good reason.
// REMOVE this filter once your live site is on HTTPS (which it should be).
add_filter( 'wp_is_application_passwords_available', '__return_true' );

// REST Callbacks

function sampathi_news_get_all_news( $request ) {
    $cat_id = $request->get_param('category');
    $dist_id = $request->get_param('district');
    $search = $request->get_param('search');

    $args = [
        'post_type' => 'post',
        'post_status' => 'publish',
        'posts_per_page' => 10,
    ];

    if ( !empty($cat_id) ) {
        $args['cat'] = intval($cat_id);
    }

    if ( !empty($search) ) {
        $args['s'] = sanitize_text_field($search);
    }

    if ( !empty($dist_id) ) {
        $args['meta_query'] = [
            [
                'key' => 'sampathi_district_id',
                'value' => intval($dist_id),
                'compare' => '='
            ]
        ];
    }

    $query = new WP_Query( $args );
    $posts = [];

    if ( $query->have_posts() ) {
        while ( $query->have_posts() ) {
            $query->the_post();
            $posts[] = sampathi_news_format_post_object( get_post() );
        }
        wp_reset_postdata();
    }

    return new WP_REST_Response( $posts, 200 );
}

function sampathi_news_get_news_detail( $request ) {
    $id = intval($request['id']);
    $post = get_post($id);

    if ( !$post || $post->post_status !== 'publish' ) {
        return new WP_Error( 'no_post', 'Article not found', [ 'status' => 404 ] );
    }

    // Increment view count metadata
    $views = (int) get_post_meta($id, 'sampathi_view_count', true);
    update_post_meta($id, 'sampathi_view_count', $views + 1);

    return new WP_REST_Response( sampathi_news_format_post_object($post, true), 200 );
}

function sampathi_news_get_active_ads( $request ) {
    $position = sanitize_text_field($request->get_param('position'));
    $cat_id = $request->get_param('category');
    $dist_id = $request->get_param('district');

    $args = [
        'post_type' => 'advertisement',
        'post_status' => 'publish',
        'posts_per_page' => -1,
        'meta_query' => [
            'relation' => 'AND',
            [
                'key' => 'sampathi_ad_status',
                'value' => 'active',
                'compare' => '='
            ]
        ]
    ];

    if ( !empty($position) ) {
        $args['meta_query'][] = [
            'key' => 'sampathi_ad_position',
            'value' => $position,
            'compare' => '='
        ];
    }

    $query = new WP_Query( $args );
    $ads = [];

    if ( $query->have_posts() ) {
        while ( $query->have_posts() ) {
            $query->the_post();
            $id = get_the_ID();

            // Client-side targeted constraints checks
            $ad_cat = get_post_meta($id, 'sampathi_ad_category', true);
            $ad_dist = get_post_meta($id, 'sampathi_ad_district', true);

            if ( !empty($cat_id) && !empty($ad_cat) && intval($ad_cat) !== intval($cat_id) ) continue;
            if ( !empty($dist_id) && !empty($ad_dist) && intval($ad_dist) !== intval($dist_id) ) continue;

            $ads[] = [
                'id' => $id,
                'business_name' => get_post_meta($id, 'sampathi_ad_business_name', true),
                'title' => get_the_title(),
                'image_url' => get_post_meta($id, 'sampathi_ad_banner_image', true),
                'landing_url' => get_post_meta($id, 'sampathi_ad_landing_url', true),
                'position' => get_post_meta($id, 'sampathi_ad_position', true),
                'package' => get_post_meta($id, 'sampathi_ad_package', true),
                'start_date' => get_post_meta($id, 'sampathi_ad_start_date', true),
                'end_date' => get_post_meta($id, 'sampathi_ad_end_date', true),
                'status' => get_post_meta($id, 'sampathi_ad_status', true),
                'priority' => (int) get_post_meta($id, 'sampathi_ad_priority', true),
                'category_id' => $ad_cat ? (int)$ad_cat : null,
                'district_id' => $ad_dist ? (int)$ad_dist : null,
            ];
        }
        wp_reset_postdata();
    }

    // Sort by priority (descending order)
    usort($ads, function($a, $b) {
        return $b['priority'] - $a['priority'];
    });

    return new WP_REST_Response( $ads, 200 );
}

function sampathi_news_get_categories() {
    $terms = get_terms([
        'taxonomy' => 'category',
        'hide_empty' => false,
    ]);

    $data = [];
    foreach ( $terms as $term ) {
        $data[] = [
            'id' => $term->term_id,
            'name' => $term->name,
            'slug' => $term->slug,
        ];
    }
    return new WP_REST_Response($data, 200);
}

function sampathi_news_get_districts() {
    $query = new WP_Query([
        'post_type' => 'district',
        'posts_per_page' => -1,
        'post_status' => 'publish'
    ]);

    $districts = [];
    if ( $query->have_posts() ) {
        while ( $query->have_posts() ) {
            $query->the_post();
            $districts[] = [
                'id' => get_the_ID(),
                'name' => get_the_title(),
                'slug' => get_post_field('post_name', get_the_ID()),
            ];
        }
        wp_reset_postdata();
    }
    return new WP_REST_Response($districts, 200);
}

// Helpers

function sampathi_news_format_post_object( $post, $include_full_content = false ) {
    $id = $post->ID;
    
    // Parse categories
    $categories = wp_get_post_categories($id, [ 'fields' => 'all' ]);
    $categories_data = array_map(function($c) {
        return [ 'id' => $c->term_id, 'name' => $c->name, 'slug' => $c->slug ];
    }, $categories);

    // Reporter link
    $reporter_id = get_post_meta($id, 'sampathi_reporter_id', true);
    $reporter = [
        'id' => 0,
        'name' => get_the_author_meta('display_name', $post->post_author),
        'photo_url' => get_avatar_url($post->post_author),
        'bio' => get_the_author_meta('description', $post->post_author),
        'designation' => 'ವರದಿಗಾರರು (Reporter)'
    ];

    if ( !empty($reporter_id) ) {
        $rep_post = get_post($reporter_id);
        if ( $rep_post ) {
            $reporter = [
                'id' => $rep_post->ID,
                'name' => $rep_post->post_title,
                'photo_url' => get_the_post_thumbnail_url($rep_post->ID, 'thumbnail') ?: $reporter['photo_url'],
                'bio' => $rep_post->post_content,
                'designation' => get_post_meta($rep_post->ID, 'sampathi_reporter_title', true) ?: 'ವರದಿಗಾರರು'
            ];
        }
    }

    // Districts links
    $district_id = get_post_meta($id, 'sampathi_district_id', true);
    $districts_data = [];
    if ( !empty($district_id) ) {
        $dist_post = get_post($district_id);
        if ( $dist_post ) {
            $districts_data[] = [
                'id' => $dist_post->ID,
                'name' => $dist_post->post_title,
                'slug' => $dist_post->post_name,
            ];
        }
    }

    return [
        'id' => $id,
        'title' => get_the_title($post),
        'subtitle' => get_post_meta($id, 'sampathi_subtitle', true),
        'excerpt' => get_the_excerpt($post),
        'content' => $include_full_content ? apply_filters('the_content', $post->post_content) : '',
        'featured_image_url' => get_the_post_thumbnail_url($id, 'large') ?: 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800',
        'date_published' => get_the_date('c', $post),
        'date_modified' => get_the_modified_date('c', $post),
        'reading_time' => (int) get_post_meta($id, 'sampathi_reading_time', true) ?: 3,
        'view_count' => (int) get_post_meta($id, 'sampathi_view_count', true) ?: 0,
        'categories_data' => $categories_data,
        'districts_data' => $districts_data,
        'reporter' => $reporter,
        'share_url' => home_url("/article/$id"),
    ];
}

// Sets a meta field via ACF's update_field() when ACF is active, otherwise
// falls back to WordPress core's update_post_meta() using the same meta key.
// This prevents a fatal error (and a half-created, invisible post) if the
// Advanced Custom Fields plugin isn't installed/active.
function sampathi_safe_update_field( $selector, $value, $post_id ) {
    if ( function_exists( 'update_field' ) ) {
        update_field( $selector, $value, $post_id );
    } else {
        update_post_meta( $post_id, $selector, $value );
    }
}

// Create a new news article from the Flutter admin publish form.
function sampathi_news_create_news_article( $request ) {
    $params = $request->get_json_params();

    if ( empty( $params['title'] ) || empty( $params['content'] ) ) {
        return new WP_Error( 'missing_fields', 'Title and content are required.', [ 'status' => 400 ] );
    }

    $post_id = wp_insert_post( [
        'post_title'   => sanitize_text_field( $params['title'] ),
        'post_content' => wp_kses_post( $params['content'] ),
        'post_excerpt' => sanitize_text_field( $params['excerpt'] ?? '' ),
        'post_status'  => 'publish',
        'post_type'    => 'post',
        'post_category'=> ! empty( $params['category_id'] ) ? [ intval( $params['category_id'] ) ] : [],
    ], true );

    if ( is_wp_error( $post_id ) ) {
        return $post_id;
    }

    // ACF / custom meta fields (same field names as acf-fields-bootstrap.php)
    if ( ! empty( $params['subtitle'] ) ) {
        sampathi_safe_update_field( 'sampathi_subtitle', sanitize_text_field( $params['subtitle'] ), $post_id );
    }
    if ( ! empty( $params['district_id'] ) ) {
        sampathi_safe_update_field( 'sampathi_district_id', intval( $params['district_id'] ), $post_id );
    }
    if ( ! empty( $params['reading_time'] ) ) {
        sampathi_safe_update_field( 'sampathi_reading_time', intval( $params['reading_time'] ), $post_id );
    }

    // Featured image: download the image at the given URL into the WP Media Library
    if ( ! empty( $params['featured_image_url'] ) ) {
        require_once ABSPATH . 'wp-admin/includes/media.php';
        require_once ABSPATH . 'wp-admin/includes/file.php';
        require_once ABSPATH . 'wp-admin/includes/image.php';

        $image_id = media_sideload_image( esc_url_raw( $params['featured_image_url'] ), $post_id, null, 'id' );
        if ( ! is_wp_error( $image_id ) ) {
            set_post_thumbnail( $post_id, $image_id );
        }
    }

    return rest_ensure_response( [
        'success' => true,
        'id'      => $post_id,
        'link'    => get_permalink( $post_id ),
    ] );
}

// Book a new advertisement campaign from the WP admin "Ad Dashboard" page.
function sampathi_news_create_ad( $request ) {
    $params = $request->get_json_params();

    if ( empty( $params['business_name'] ) || empty( $params['position'] ) ) {
        return new WP_Error( 'missing_fields', 'Business name and position are required.', [ 'status' => 400 ] );
    }

    $duration_days = ! empty( $params['duration_days'] ) ? intval( $params['duration_days'] ) : 7;
    $fast_forward   = ! empty( $params['fast_forward'] ); // treat days as seconds, for quick local testing

    // Admin can pick a custom start date/time (the "time period") for the
    // campaign; if omitted, it starts immediately, same as before.
    $now = current_time( 'timestamp' );
    $start = ! empty( $params['start_date'] ) ? strtotime( $params['start_date'] ) : $now;
    if ( ! $start ) {
        $start = $now;
    }

    $end = $fast_forward
        ? $start + $duration_days // seconds instead of days
        : strtotime( "+{$duration_days} days", $start );

    $post_id = wp_insert_post( [
        'post_title'  => sanitize_text_field( $params['business_name'] ) . ' - ' . sanitize_text_field( $params['heading'] ?? 'Ad Campaign' ),
        'post_type'   => 'advertisement',
        'post_status' => 'publish',
    ], true );

    if ( is_wp_error( $post_id ) ) {
        return $post_id;
    }

    // A future start date means the campaign hasn't begun yet — the hourly
    // cron scheduler (wp-cron-scheduler.php) will flip it to 'active'
    // automatically once its start time is reached.
    $status = ( $start > $now ) ? 'scheduled' : 'active';

    sampathi_safe_update_field( 'sampathi_ad_business_name', sanitize_text_field( $params['business_name'] ), $post_id );
    sampathi_safe_update_field( 'sampathi_ad_banner_image', esc_url_raw( $params['banner_image'] ?? '' ), $post_id );
    sampathi_safe_update_field( 'sampathi_ad_landing_url', esc_url_raw( $params['landing_url'] ?? '' ), $post_id );
    sampathi_safe_update_field( 'sampathi_ad_position', sanitize_text_field( $params['position'] ), $post_id );
    sampathi_safe_update_field( 'sampathi_ad_package', sanitize_text_field( $params['package'] ?? 'standard' ), $post_id );
    sampathi_safe_update_field( 'sampathi_ad_start_date', date( 'Y-m-d H:i:s', $start ), $post_id );
    sampathi_safe_update_field( 'sampathi_ad_end_date', date( 'Y-m-d H:i:s', $end ), $post_id );
    sampathi_safe_update_field( 'sampathi_ad_priority', 1, $post_id );
    sampathi_safe_update_field( 'sampathi_ad_status', $status, $post_id );

    return rest_ensure_response( [
        'success'    => true,
        'id'         => $post_id,
        'status'     => $status,
        'start_date' => date( 'Y-m-d H:i:s', $start ),
        'end_date'   => date( 'Y-m-d H:i:s', $end ),
    ] );
}

// Manually change a campaign's status (scheduled / active / inactive).
// 'inactive' is a manual pause the automated cron scheduler leaves alone —
// it only ever auto-transitions scheduled->active->expired on its own.
function sampathi_news_update_ad_status( $request ) {
    $params = $request->get_json_params();
    $id     = intval( $params['id'] ?? 0 );
    $status = sanitize_text_field( $params['status'] ?? '' );

    $allowed_statuses = [ 'scheduled', 'active', 'inactive', 'expired' ];
    if ( ! $id || ! in_array( $status, $allowed_statuses, true ) ) {
        return new WP_Error( 'invalid_request', 'A valid ad id and status are required.', [ 'status' => 400 ] );
    }

    $post = get_post( $id );
    if ( ! $post || $post->post_type !== 'advertisement' ) {
        return new WP_Error( 'not_found', 'Advertisement not found.', [ 'status' => 404 ] );
    }

    sampathi_safe_update_field( 'sampathi_ad_status', $status, $id );

    return rest_ensure_response( [ 'success' => true, 'id' => $id, 'status' => $status ] );
}

// Uploads a file into the WordPress Media Library and returns its URL.
// Used by the Flutter admin app's "Switch to File Upload" option, for both
// the Publish News and Ad Dashboard image fields.
function sampathi_news_upload_media( $request ) {
    if ( empty( $_FILES['file'] ) ) {
        return new WP_Error( 'no_file', 'No file was uploaded.', [ 'status' => 400 ] );
    }

    require_once ABSPATH . 'wp-admin/includes/file.php';
    require_once ABSPATH . 'wp-admin/includes/media.php';
    require_once ABSPATH . 'wp-admin/includes/image.php';

    // Always assign a safe, ASCII, unique filename — never trust the
    // original filename from the client (avoids the broken-URL issue that
    // happens when non-ASCII filenames get mangled by header/sanitization).
    $original_name = $_FILES['file']['name'];
    $ext = pathinfo( $original_name, PATHINFO_EXTENSION );
    $ext = $ext ? '.' . sanitize_file_name( $ext ) : '.jpg';
    $_FILES['file']['name'] = 'sampathi-upload-' . time() . '-' . wp_generate_password( 6, false ) . $ext;

    $attachment_id = media_handle_upload( 'file', 0 );

    if ( is_wp_error( $attachment_id ) ) {
        return $attachment_id;
    }

    return rest_ensure_response( [
        'success'    => true,
        'id'         => $attachment_id,
        'source_url' => wp_get_attachment_url( $attachment_id ),
    ] );
}

// Returns every advertisement campaign regardless of status (active,
// scheduled, expired) — powers the Flutter admin app's campaigns list,
// mirroring the table already shown on the wp-admin Ad Dashboard page.
function sampathi_news_get_all_ads( $request ) {
    $ad_query = new WP_Query( [
        'post_type'      => 'advertisement',
        'posts_per_page' => 50,
        'post_status'    => 'publish',
        'orderby'        => 'date',
        'order'          => 'DESC',
    ] );

    $ads = [];
    foreach ( $ad_query->posts as $post ) {
        $id = $post->ID;
        $ads[] = [
            'id'            => $id,
            'business_name' => get_post_meta( $id, 'sampathi_ad_business_name', true ),
            'position'      => get_post_meta( $id, 'sampathi_ad_position', true ),
            'start_date'    => get_post_meta( $id, 'sampathi_ad_start_date', true ),
            'end_date'      => get_post_meta( $id, 'sampathi_ad_end_date', true ),
            'status'        => get_post_meta( $id, 'sampathi_ad_status', true ) ?: 'expired',
        ];
    }

    return rest_ensure_response( $ads );
}

// Streams an uploaded image back with a CORS header attached, so Flutter's
// CanvasKit renderer (which fetches image bytes via JS fetch(), subject to
// CORS) can load it even though it lives on a different origin. Only ever
// serves files that are genuinely inside this site's own uploads folder —
// rejects anything else to prevent this being used as an open proxy.
function sampathi_news_image_proxy( $request ) {
    $url = $request->get_param( 'url' );
    if ( empty( $url ) ) {
        return new WP_Error( 'missing_url', 'A url parameter is required.', [ 'status' => 400 ] );
    }

    $upload_dir = wp_get_upload_dir();
    $base_url   = $upload_dir['baseurl'];
    $base_dir   = $upload_dir['basedir'];

    // Reject anything that isn't actually one of our own uploaded files.
    if ( strpos( $url, $base_url ) !== 0 ) {
        return new WP_Error( 'invalid_url', 'Only this site\'s own uploaded images can be proxied.', [ 'status' => 403 ] );
    }

    $relative_path = str_replace( $base_url, '', $url );
    $file_path     = $base_dir . $relative_path;
    $real_base     = realpath( $base_dir );
    $real_file     = realpath( $file_path );

    // realpath() + strpos guards against ../ path traversal tricks.
    if ( ! $real_file || strpos( $real_file, $real_base ) !== 0 || ! file_exists( $real_file ) ) {
        return new WP_Error( 'not_found', 'Image not found.', [ 'status' => 404 ] );
    }

    $filetype = wp_check_filetype( $real_file );
    $mime     = $filetype['type'] ?: 'application/octet-stream';

    header( 'Content-Type: ' . $mime );
    header( 'Content-Length: ' . filesize( $real_file ) );
    header( 'Access-Control-Allow-Origin: *' );
    header( 'Cache-Control: public, max-age=31536000, immutable' );

    readfile( $real_file );
    exit;
}

// Returns the currently logged-in user's profile for the Flutter app's
// reader-facing Profile tab (name, email, phone, avatar).
function sampathi_news_get_profile( $request ) {
    $user = wp_get_current_user();

    return rest_ensure_response( [
        'name'       => $user->display_name,
        'email'      => $user->user_email,
        'phone'      => get_user_meta( $user->ID, 'sampathi_phone', true ),
        'avatar_url' => get_user_meta( $user->ID, 'sampathi_avatar_url', true ),
    ] );
}

// Updates the logged-in user's display name, phone, and/or avatar URL.
// Any field left out of the request body is left unchanged.
function sampathi_news_update_profile( $request ) {
    $params = $request->get_json_params();
    $user_id = get_current_user_id();

    if ( isset( $params['name'] ) && trim( $params['name'] ) !== '' ) {
        wp_update_user( [ 'ID' => $user_id, 'display_name' => sanitize_text_field( $params['name'] ) ] );
    }
    if ( isset( $params['phone'] ) ) {
        update_user_meta( $user_id, 'sampathi_phone', sanitize_text_field( $params['phone'] ) );
    }
    if ( isset( $params['avatar_url'] ) ) {
        update_user_meta( $user_id, 'sampathi_avatar_url', esc_url_raw( $params['avatar_url'] ) );
    }

    return sampathi_news_get_profile( $request );
}

// Creates a new Category (WordPress's built-in taxonomy) from the Flutter
// admin app's Publish News page.
function sampathi_news_create_category( $request ) {
    $params = $request->get_json_params();
    $name = sanitize_text_field( $params['name'] ?? '' );

    if ( empty( $name ) ) {
        return new WP_Error( 'missing_name', 'Category name is required.', [ 'status' => 400 ] );
    }

    $existing = get_term_by( 'name', $name, 'category' );
    if ( $existing ) {
        return rest_ensure_response( [ 'success' => true, 'id' => $existing->term_id, 'name' => $existing->name, 'already_existed' => true ] );
    }

    $result = wp_insert_term( $name, 'category' );
    if ( is_wp_error( $result ) ) {
        return $result;
    }

    return rest_ensure_response( [ 'success' => true, 'id' => $result['term_id'], 'name' => $name ] );
}

// Creates a new District (custom post type) from the Flutter admin app's
// Publish News page.
function sampathi_news_create_district( $request ) {
    $params = $request->get_json_params();
    $name = sanitize_text_field( $params['name'] ?? '' );

    if ( empty( $name ) ) {
        return new WP_Error( 'missing_name', 'District name is required.', [ 'status' => 400 ] );
    }

    // Avoid creating duplicates if one with this exact title already exists.
    $existing = get_page_by_title( $name, OBJECT, 'district' );
    if ( $existing ) {
        return rest_ensure_response( [ 'success' => true, 'id' => $existing->ID, 'name' => $name, 'already_existed' => true ] );
    }

    $post_id = wp_insert_post( [
        'post_title'  => $name,
        'post_type'   => 'district',
        'post_status' => 'publish',
    ], true );

    if ( is_wp_error( $post_id ) ) {
        return $post_id;
    }

    return rest_ensure_response( [ 'success' => true, 'id' => $post_id, 'name' => $name ] );
}
