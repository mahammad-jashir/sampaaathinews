<?php
/**
 * Database schema and tracking insertion for Advertisement Analytics
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

register_activation_hook( SAMPATHI_NEWS_CORE_PATH . 'sampathi-news-core.php', 'sampathi_news_create_analytics_table' );

function sampathi_news_create_analytics_table() {
    global $wpdb;
    $table_name = $wpdb->prefix . 'sampathi_ad_analytics';
    $charset_collate = $wpdb->get_charset_collate();

    $sql = "CREATE TABLE $table_name (
        id bigint(20) NOT NULL AUTO_INCREMENT,
        ad_id bigint(20) NOT NULL,
        action varchar(20) NOT NULL, -- 'impression' or 'click'
        timestamp datetime DEFAULT CURRENT_TIMESTAMP NOT NULL,
        device varchar(50) DEFAULT '' NOT NULL,
        browser varchar(50) DEFAULT '' NOT NULL,
        location varchar(100) DEFAULT '' NOT NULL,
        ip_hash varchar(64) DEFAULT '' NOT NULL,
        PRIMARY KEY  (id),
        KEY ad_id (ad_id),
        KEY action (action)
    ) $charset_collate;";

    require_once ABSPATH . 'wp-admin/includes/upgrade.php';
    dbDelta( $sql );
}

/**
 * Handles incoming API request to log click/impression
 */
function sampathi_news_track_ad_activity( $request ) {
    global $wpdb;
    $params = $request->get_json_params();

    $ad_id = isset($params['ad_id']) ? intval($params['ad_id']) : 0;
    $action = isset($params['action']) ? sanitize_text_field($params['action']) : '';

    if ( $ad_id <= 0 || !in_array($action, ['impression', 'click']) ) {
        return new WP_Error( 'bad_input', 'Invalid parameters', [ 'status' => 400 ] );
    }

    $table_name = $wpdb->prefix . 'sampathi_ad_analytics';

    // Parse user agent
    $user_agent = isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : '';
    $device = 'desktop';
    if ( wp_is_mobile() ) {
        $device = 'mobile';
    }

    $browser = 'unknown';
    if ( preg_match('/MSIE/i', $user_agent) && !preg_match('/Opera/i', $user_agent) ) {
        $browser = 'MSIE';
    } elseif ( preg_match('/Firefox/i', $user_agent) ) {
        $browser = 'Firefox';
    } elseif ( preg_match('/Chrome/i', $user_agent) ) {
        $browser = 'Chrome';
    } elseif ( preg_match('/Safari/i', $user_agent) ) {
        $browser = 'Safari';
    } elseif ( preg_match('/Opera/i', $user_agent) ) {
        $browser = 'Opera';
    }

    // IP Hashing for privacy compliance
    $ip = isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : '';
    $ip_hash = hash('sha256', $ip);

    // Simple location estimation (can hook into GeoIP plugin)
    $location = 'Karnataka, IN';

    $result = $wpdb->insert(
        $table_name,
        [
            'ad_id' => $ad_id,
            'action' => $action,
            'timestamp' => current_time('mysql', 1),
            'device' => $device,
            'browser' => $browser,
            'location' => $location,
            'ip_hash' => $ip_hash,
        ],
        [ '%d', '%s', '%s', '%s', '%s', '%s', '%s' ]
    );

    if ( $result === false ) {
        return new WP_REST_Response([ 'success' => false, 'error' => $wpdb->last_error ], 500);
    }

    return new WP_REST_Response([ 'success' => true ], 200);
}
