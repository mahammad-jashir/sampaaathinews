<?php
/**
 * Programmatic ACF (Advanced Custom Fields) registrations for Headless News elements
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

add_action( 'acf/init', 'sampathi_news_register_acf_field_groups' );

function sampathi_news_register_acf_field_groups() {
    if ( ! function_exists( 'acf_add_local_field_group' ) ) {
        return; // ACF not active
    }

    // 1. Article Meta Fields
    acf_add_local_field_group([
        'key' => 'group_sampathi_article_meta',
        'title' => 'Article Metadata',
        'fields' => [
            [
                'key' => 'field_sampathi_subtitle',
                'label' => 'Subtitle / Secondary Headline (ಉಪಶೀರ್ಷಿಕೆ)',
                'name' => 'sampathi_subtitle',
                'type' => 'text',
            ],
            [
                'key' => 'field_sampathi_reading_time',
                'label' => 'Estimated Reading Time (Minutes)',
                'name' => 'sampathi_reading_time',
                'type' => 'number',
                'default_value' => 3,
            ],
            [
                'key' => 'field_sampathi_reporter_link',
                'label' => 'Assign Reporter (ವರದಿಗಾರರು)',
                'name' => 'sampathi_reporter_id',
                'type' => 'post_object',
                'post_type' => ['reporter'],
                'allow_null' => 1,
            ],
            [
                'key' => 'field_sampathi_district_link',
                'label' => 'Target District (ಜಿಲ್ಲೆ)',
                'name' => 'sampathi_district_id',
                'type' => 'post_object',
                'post_type' => ['district'],
                'allow_null' => 1,
            ]
        ],
        'location' => [
            [
                [
                    'param' => 'post_type',
                    'operator' => '==',
                    'value' => 'post',
                ]
            ]
        ]
    ]);

    // 2. Advertisement Booking Meta Fields
    acf_add_local_field_group([
        'key' => 'group_sampathi_advertisement_booking',
        'title' => 'Advertisement Booking Settings',
        'fields' => [
            [
                'key' => 'field_ad_business_name',
                'label' => 'Business / Sponsor Name',
                'name' => 'sampathi_ad_business_name',
                'type' => 'text',
                'required' => 1,
            ],
            [
                'key' => 'field_ad_banner_image',
                'label' => 'Banner Media Image / Visual',
                'name' => 'sampathi_ad_banner_image',
                'type' => 'url',
                'required' => 1,
            ],
            [
                'key' => 'field_ad_landing_url',
                'label' => 'Destination URL / Landing Page',
                'name' => 'sampathi_ad_landing_url',
                'type' => 'url',
            ],
            [
                'key' => 'field_ad_position',
                'label' => 'Position Slot',
                'name' => 'sampathi_ad_position',
                'type' => 'select',
                'choices' => [
                    'header_banner' => 'Header Banner (970x90)',
                    'homepage_banner' => 'Homepage Center Hero (728x90)',
                    'sidebar_banner' => 'Sidebar Box (300x250)',
                    'article_banner' => 'Article In-Feed Inline',
                ],
                'default_value' => 'homepage_banner',
            ],
            [
                'key' => 'field_ad_package',
                'label' => 'Package Plan',
                'name' => 'sampathi_ad_package',
                'type' => 'select',
                'choices' => [
                    'bronze' => 'Bronze (7 Days)',
                    'silver' => 'Silver (15 Days)',
                    'gold' => 'Gold (30 Days)',
                    'platinum' => 'Platinum (90 Days)',
                ],
                'default_value' => 'bronze',
            ],
            [
                'key' => 'field_ad_start_date',
                'label' => 'Schedule Start Time (ISO Format)',
                'name' => 'sampathi_ad_start_date',
                'type' => 'text',
                'placeholder' => '2026-08-10T09:00:00Z',
                'required' => 1,
            ],
            [
                'key' => 'field_ad_end_date',
                'label' => 'Schedule End Time (ISO Format)',
                'name' => 'sampathi_ad_end_date',
                'type' => 'text',
                'placeholder' => '2026-08-20T23:59:59Z',
                'required' => 1,
            ],
            [
                'key' => 'field_ad_priority',
                'label' => 'Load Priority Weight',
                'name' => 'sampathi_ad_priority',
                'type' => 'number',
                'default_value' => 1,
                'instructions' => 'Higher priority loads first in rotation.',
            ],
            [
                'key' => 'field_ad_status',
                'label' => 'Scheduling Status',
                'name' => 'sampathi_ad_status',
                'type' => 'select',
                'choices' => [
                    'scheduled' => 'Scheduled',
                    'active' => 'Active / Running',
                    'expired' => 'Expired',
                ],
                'default_value' => 'scheduled',
            ],
            [
                'key' => 'field_ad_category',
                'label' => 'Target Category (Optional)',
                'name' => 'sampathi_ad_category',
                'type' => 'taxonomy',
                'taxonomy' => 'category',
                'field_type' => 'select',
                'allow_null' => 1,
            ],
            [
                'key' => 'field_ad_district',
                'label' => 'Target District (Optional)',
                'name' => 'sampathi_ad_district',
                'type' => 'post_object',
                'post_type' => ['district'],
                'allow_null' => 1,
            ]
        ],
        'location' => [
            [
                [
                    'param' => 'post_type',
                    'operator' => '==',
                    'value' => 'advertisement',
                ]
            ]
        ]
    ]);
}
