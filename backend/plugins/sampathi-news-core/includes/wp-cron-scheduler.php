<?php
/**
 * Automated Advertisement Scheduler using WordPress WP Cron
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Register Activation and Deactivation Hooks
register_activation_hook( SAMPATHI_NEWS_CORE_PATH . 'sampathi-news-core.php', 'sampathi_news_scheduler_activate' );
register_deactivation_hook( SAMPATHI_NEWS_CORE_PATH . 'sampathi-news-core.php', 'sampathi_news_scheduler_deactivate' );

function sampathi_news_scheduler_activate() {
    if ( ! wp_next_scheduled( 'sampathi_news_hourly_ads_check' ) ) {
        wp_schedule_event( time(), 'hourly', 'sampathi_news_hourly_ads_check' );
    }
}

function sampathi_news_scheduler_deactivate() {
    $timestamp = wp_next_scheduled( 'sampathi_news_hourly_ads_check' );
    if ( $timestamp ) {
        wp_unschedule_event( $timestamp, 'sampathi_news_hourly_ads_check' );
    }
}

// Hook Action to our Cron
add_action( 'sampathi_news_hourly_ads_check', 'sampathi_news_process_ads_scheduler' );

function sampathi_news_process_ads_scheduler() {
    $now = current_time( 'timestamp', true ); // UTC timestamp

    // Fetch all advertisements
    $args = [
        'post_type' => 'advertisement',
        'post_status' => 'publish',
        'posts_per_page' => -1,
    ];

    $query = new WP_Query( $args );

    if ( $query->have_posts() ) {
        while ( $query->have_posts() ) {
            $query->the_post();
            $id = get_the_ID();

            $start_date_str = get_post_meta($id, 'sampathi_ad_start_date', true);
            $end_date_str = get_post_meta($id, 'sampathi_ad_end_date', true);
            $current_status = get_post_meta($id, 'sampathi_ad_status', true);

            if ( empty($start_date_str) || empty($end_date_str) ) {
                continue; // Missing scheduler dates
            }

            try {
                $start_time = strtotime($start_date_str);
                $end_time = strtotime($end_date_str);

                // 1. Transition to active
                if ( $current_status === 'scheduled' && $now >= $start_time && $now < $end_time ) {
                    update_post_meta($id, 'sampathi_ad_status', 'active');
                }
                
                // 2. Transition to expired
                if ( $current_status === 'active' && $now >= $end_time ) {
                    update_post_meta($id, 'sampathi_ad_status', 'expired');
                    
                    // Trigger email notification hook for expired ad renewal
                    do_action('sampathi_ad_expired_notification', $id);
                }
            } catch (\Exception $e) {
                error_log("Sampathi News Ad Cron Error for Ad ID $id: " . $e->getMessage());
            }
        }
        wp_reset_postdata();
    }
}

// Optional: Email notification logic hook
add_action( 'sampathi_ad_expired_notification', 'sampathi_news_send_renewal_email' );
function sampathi_news_send_renewal_email( $ad_id ) {
    $business_name = get_post_meta($ad_id, 'sampathi_ad_business_name', true);
    $admin_email = get_option('admin_email');
    
    $subject = "Sampathi News - Advertisement Expired: $business_name";
    $message = "The advertisement booking for '$business_name' (ID: $ad_id) has reached its scheduled end time and was automatically moved to Expired.\n\nPlease contact client for renewal.";
    
    wp_mail( $admin_email, $subject, $message );
}
