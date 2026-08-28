<?php
/**
 * Renders the custom WordPress Admin Dashboard for Advertisement metrics and analytics reporting.
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

add_action( 'admin_menu', 'sampathi_news_register_admin_dashboard' );
add_action( 'admin_enqueue_scripts', 'sampathi_news_enqueue_ads_dashboard_assets' );

function sampathi_news_enqueue_ads_dashboard_assets( $hook ) {
    if ( $hook !== 'toplevel_page_sampathi-ad-dashboard' ) {
        return;
    }
    wp_enqueue_style(
        'sampathi-admin-styles',
        SAMPATHI_NEWS_CORE_URL . 'admin/assets/admin-styles.css',
        [],
        '1.0.0'
    );
}

function sampathi_news_register_admin_dashboard() {
    add_menu_page(
        'Ad Analytics',
        'Ad Dashboard',
        'manage_options',
        'sampathi-ad-dashboard',
        'sampathi_news_render_ad_dashboard',
        'dashicons-chart-bar',
        6
    );
}

function sampathi_news_render_ad_dashboard() {
    global $wpdb;
    $analytics_table = $wpdb->prefix . 'sampathi_ad_analytics';

    // 1. Fetch Ad counts by Status
    $running_ads = $wpdb->get_var("SELECT COUNT(*) FROM {$wpdb->postmeta} WHERE meta_key='sampathi_ad_status' AND meta_value='active'");
    $scheduled_ads = $wpdb->get_var("SELECT COUNT(*) FROM {$wpdb->postmeta} WHERE meta_key='sampathi_ad_status' AND meta_value='scheduled'");
    $expired_ads = $wpdb->get_var("SELECT COUNT(*) FROM {$wpdb->postmeta} WHERE meta_key='sampathi_ad_status' AND meta_value='expired'");

    // 2. Fetch Performance Indicators
    $total_impressions = 0;
    $total_clicks = 0;
    $table_exists = $wpdb->get_var("SHOW TABLES LIKE '$analytics_table'");

    if ( $table_exists ) {
        $total_impressions = $wpdb->get_var($wpdb->prepare("SELECT COUNT(*) FROM $analytics_table WHERE action = %s", 'impression'));
        $total_clicks = $wpdb->get_var($wpdb->prepare("SELECT COUNT(*) FROM $analytics_table WHERE action = %s", 'click'));
    }

    $ctr = $total_impressions > 0 ? round(($total_clicks / $total_impressions) * 100, 2) : 0.0;

    // 3. Render Dashboard Page HTML
    ?>
    <div class="wrap">
        <h1 style="font-weight: bold; margin-bottom: 24px;">ಸಂಪಾತಿ ಜಾಹೀರಾತು ಡ್ಯಾಶ್‌ಬೋರ್ಡ್ (Ad Dashboard)</h1>
        
        <!-- Metrics Row -->
        <div style="display: flex; gap: 16px; margin-bottom: 32px;">
            <!-- Box 1 -->
            <div style="flex: 1; background: #fff; padding: 20px; border-radius: 8px; border: 1px solid #ccd0d4; box-shadow: 0 1px 1px rgba(0,0,0,.04);">
                <div style="font-size: 14px; color: #646970;">ಚಾಲನೆಯಲ್ಲಿರುವ ಜಾಹೀರಾತುಗಳು (Active Ads)</div>
                <div style="font-size: 28px; font-weight: bold; color: #22C55E; margin-top: 8px;"><?php echo esc_html($running_ads); ?></div>
            </div>
            <!-- Box 2 -->
            <div style="flex: 1; background: #fff; padding: 20px; border-radius: 8px; border: 1px solid #ccd0d4; box-shadow: 0 1px 1px rgba(0,0,0,.04);">
                <div style="font-size: 14px; color: #646970;">ನಿಗದಿತ ಜಾಹೀರಾತುಗಳು (Scheduled Ads)</div>
                <div style="font-size: 28px; font-weight: bold; color: #F59E0B; margin-top: 8px;"><?php echo esc_html($scheduled_ads); ?></div>
            </div>
            <!-- Box 3 -->
            <div style="flex: 1; background: #fff; padding: 20px; border-radius: 8px; border: 1px solid #ccd0d4; box-shadow: 0 1px 1px rgba(0,0,0,.04);">
                <div style="font-size: 14px; color: #646970;">ಅವಧಿ ಮುಗಿದ ಜಾಹೀರಾತುಗಳು (Expired Ads)</div>
                <div style="font-size: 28px; font-weight: bold; color: #EF4444; margin-top: 8px;"><?php echo esc_html($expired_ads); ?></div>
            </div>
        </div>

        <!-- Analytics Performance Row -->
        <div style="background: #fff; padding: 24px; border-radius: 8px; border: 1px solid #ccd0d4; box-shadow: 0 1px 1px rgba(0,0,0,.04); margin-bottom: 32px;">
            <h2 style="margin-top: 0; font-weight: bold;">ಜಾಹೀರಾತು ಕಾರ್ಯಕ್ಷಮತೆ ವರದಿ (Performance Analytics)</h2>
            <hr style="border-top: 1px solid #f0f0f1; margin: 16px 0;">
            <div style="display: flex; justify-content: space-around; text-align: center; padding: 12px 0;">
                <div>
                    <div style="color: #646970; font-size: 14px;">ಒಟ್ಟು ವೀಕ್ಷಣೆಗಳು (Total Impressions)</div>
                    <div style="font-size: 24px; font-weight: bold; margin-top: 8px;"><?php echo number_format($total_impressions); ?></div>
                </div>
                <div>
                    <div style="color: #646970; font-size: 14px;">ಒಟ್ಟು ಕ್ಲಿಕ್‌ಗಳು (Total Clicks)</div>
                    <div style="font-size: 24px; font-weight: bold; margin-top: 8px;"><?php echo number_format($total_clicks); ?></div>
                </div>
                <div>
                    <div style="color: #646970; font-size: 14px;">ಕ್ಲಿಕ್ ದರ (CTR %)</div>
                    <div style="font-size: 24px; font-weight: bold; color: #438AFE; margin-top: 8px;"><?php echo esc_html($ctr); ?>%</div>
                </div>
            </div>
        </div>

        <!-- Booking Form + Campaigns List Row -->
        <div style="display: flex; gap: 24px; align-items: flex-start;">
            <!-- Book New Ad Form -->
            <div style="flex: 1; background: #fff; padding: 24px; border-radius: 8px; border: 1px solid #ccd0d4; box-shadow: 0 1px 1px rgba(0,0,0,.04);">
                <h2 style="margin-top: 0; font-weight: bold;">ಹೊಸ ಜಾಹೀರಾತು ಬುಕಿಂಗ್ (Book New Ad)</h2>
                <hr style="border-top: 1px solid #f0f0f1; margin: 16px 0;">

                <div id="sampathi-ad-status" style="display:none; margin-bottom: 16px; padding: 10px 14px; border-radius: 6px; font-weight: 600; font-size: 13px;"></div>

                <form id="ad-booking-form" onsubmit="sampathiBookAd(event)">
                    <div style="margin-bottom: 16px;">
                        <label style="display:block; margin-bottom: 6px; font-weight: 600;">Sponsor Business Name (ಕಂಪನಿ ಹೆಸರು):</label>
                        <input type="text" id="ad-business" required placeholder="e.g., Sampanna Jewellers" style="width:100%; padding:8px; border-radius:4px; border:1px solid #cbd5e1;">
                    </div>
                    <div style="margin-bottom: 16px;">
                        <label style="display:block; margin-bottom: 6px; font-weight: 600;">Advertisement Heading (ಜಾಹೀರಾತು ಶೀರ್ಷಿಕೆ):</label>
                        <input type="text" id="ad-heading" placeholder="e.g., Gold Discount Sale 2026" style="width:100%; padding:8px; border-radius:4px; border:1px solid #cbd5e1;">
                    </div>
                    <div style="margin-bottom: 16px;">
                        <label style="display:block; margin-bottom: 6px; font-weight: 600;">Position Display Slot:</label>
                        <select id="ad-position" style="width:100%; padding:8px; border-radius:4px; border:1px solid #cbd5e1;">
                            <option value="header_banner">Header Banner</option>
                            <option value="sidebar_banner">Sidebar Banner</option>
                            <option value="article_banner">Article Banner</option>
                        </select>
                    </div>
                    <div style="margin-bottom: 16px;">
                        <label style="display:block; margin-bottom: 6px; font-weight: 600;">Banner Image (ಜಾಹೀರಾತು ಚಿತ್ರ):</label>
                        <button type="button" id="ad-toggle-img-method" onclick="sampathiToggleAdImageMethod()" style="padding: 6px 12px; font-size: 11px; background-color: #64748b; color:#fff; border:none; border-radius:4px; cursor:pointer; margin-bottom: 8px;">📁 Switch to File Upload</button>
                        <div id="ad-img-url-block">
                            <input type="url" id="ad-banner-image" placeholder="Paste banner image web URL here" style="width:100%; padding:8px; border-radius:4px; border:1px solid #cbd5e1;">
                        </div>
                        <div id="ad-img-file-block" style="display:none;">
                            <input type="file" id="ad-banner-image-file" accept="image/*" onchange="sampathiPreviewAdImage(event)">
                        </div>
                        <div id="ad-image-preview" style="margin-top: 10px; display: none;">
                            <img id="ad-preview-img" style="max-height: 100px; border-radius: 6px; border: 1px solid #cbd5e1; display: block;">
                        </div>
                    </div>
                    <div style="margin-bottom: 16px;">
                        <label style="display:block; margin-bottom: 6px; font-weight: 600;">Landing / Target URL (ಲಿಂಕ್):</label>
                        <input type="url" id="ad-landing-url" placeholder="e.g., https://google.com" style="width:100%; padding:8px; border-radius:4px; border:1px solid #cbd5e1;">
                    </div>
                    <div style="margin-bottom: 16px;">
                        <label style="display:block; margin-bottom: 6px; font-weight: 600;">Campaign Start (Time Period):</label>
                        <div style="display:flex; gap:8px;">
                            <input type="date" id="ad-start-date" style="flex:1; padding:8px; border-radius:4px; border:1px solid #cbd5e1;">
                            <input type="time" id="ad-start-time" style="flex:1; padding:8px; border-radius:4px; border:1px solid #cbd5e1;">
                        </div>
                        <small style="color:#64748b;">Leave as now to start immediately, or pick a future date/time to schedule it.</small>
                    </div>
                    <div style="margin-bottom: 16px;">
                        <label style="display:block; margin-bottom: 6px; font-weight: 600;">Ad Duration (in Days - ಜಾಹೀರಾತು ಅವಧಿ ದಿನಗಳಲ್ಲಿ):</label>
                        <input type="number" id="ad-duration" value="7" min="1" style="width:100%; padding:8px; border-radius:4px; border:1px solid #cbd5e1;">
                    </div>
                    <div style="margin-bottom: 20px;">
                        <label style="display:flex; align-items:center; gap: 8px;">
                            <input type="checkbox" id="ad-fast-forward">
                            ⚡ Fast-forward testing (treat days as seconds for instant expiration!)
                        </label>
                    </div>
                    <button type="submit" style="width:100%; padding: 12px; background:#438AFE; color:#fff; border:none; border-radius:6px; font-weight:bold; cursor:pointer; font-size: 14px;">🚀 Submit &amp; Schedule Campaign</button>
                </form>
            </div>

            <!-- Ad List Expiry Table -->
            <div style="flex: 1; background: #fff; padding: 24px; border-radius: 8px; border: 1px solid #ccd0d4; box-shadow: 0 1px 1px rgba(0,0,0,.04);">
                <h2 style="margin-top: 0; font-weight: bold;">ಜಾಹೀರಾತು ಬುಕಿಂಗ್ ವಿವರಗಳು (Active &amp; Scheduled Campaigns)</h2>
                <table class="wp-list-table widefat fixed striped table-view-list" style="margin-top: 16px;">
                    <thead>
                        <tr>
                            <th><b>Business Name</b></th>
                            <th><b>Position</b></th>
                            <th><b>Start Date</b></th>
                            <th><b>End Date</b></th>
                            <th><b>Status</b></th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php
                        $ad_query = new WP_Query([
                            'post_type' => 'advertisement',
                            'posts_per_page' => 10,
                            'post_status' => 'publish'
                        ]);

                        if ( $ad_query->have_posts() ) {
                            while ( $ad_query->have_posts() ) {
                                $ad_query->the_post();
                                $id = get_the_ID();
                                ?>
                                <tr>
                                    <td><strong><?php echo esc_html(get_post_meta($id, 'sampathi_ad_business_name', true)); ?></strong></td>
                                    <td><?php echo esc_html(get_post_meta($id, 'sampathi_ad_position', true)); ?></td>
                                    <td><?php echo esc_html(get_post_meta($id, 'sampathi_ad_start_date', true)); ?></td>
                                    <td><?php echo esc_html(get_post_meta($id, 'sampathi_ad_end_date', true)); ?></td>
                                    <td>
                                        <?php
                                        $status = get_post_meta($id, 'sampathi_ad_status', true) ?: 'expired';
                                        $colors = [
                                            'active'    => '#22C55E',
                                            'scheduled' => '#F59E0B',
                                            'inactive'  => '#9CA3AF',
                                            'expired'   => '#EF4444',
                                        ];
                                        ?>
                                        <select class="sampathi-ad-status-select" data-ad-id="<?php echo esc_attr($id); ?>"
                                            style="background:<?php echo esc_attr($colors[$status] ?? '#9CA3AF'); ?>;color:#fff;border:none;border-radius:4px;font-size:11px;padding:3px 4px;font-weight:bold;">
                                            <option value="scheduled" <?php selected($status, 'scheduled'); ?>>SCHEDULED</option>
                                            <option value="active" <?php selected($status, 'active'); ?>>ACTIVE</option>
                                            <option value="inactive" <?php selected($status, 'inactive'); ?>>INACTIVE</option>
                                            <option value="expired" <?php selected($status, 'expired'); ?>>EXPIRED</option>
                                        </select>
                                    </td>
                                </tr>
                                <?php
                            }
                            wp_reset_postdata();
                        } else {
                            echo '<tr><td colspan="5">ಯಾವುದೇ ಜಾಹೀರಾತು ಬುಕಿಂಗ್ ಲಭ್ಯವಿಲ್ಲ.</td></tr>';
                        }
                        ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        const SAMPATHI_ADS_REST_URL = <?php echo wp_json_encode( esc_url_raw( rest_url( 'sampathi/v1' ) ) ); ?>;
        const SAMPATHI_ADS_NONCE = <?php echo wp_json_encode( wp_create_nonce( 'wp_rest' ) ); ?>;

        // Default the campaign start date/time inputs to right now.
        (function () {
            const now = new Date();
            const pad = n => String(n).padStart(2, '0');
            document.getElementById('ad-start-date').value = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
            document.getElementById('ad-start-time').value = `${pad(now.getHours())}:${pad(now.getMinutes())}`;
        })();

        function sampathiShowAdStatus(message, isError) {
            const el = document.getElementById('sampathi-ad-status');
            el.style.display = 'block';
            el.style.background = isError ? '#FEE2E2' : '#DCFCE7';
            el.style.color = isError ? '#991B1B' : '#166534';
            el.textContent = message;
        }

        let sampathiAdImageMethod = 'url';
        let sampathiAdSelectedFile = null;

        function sampathiToggleAdImageMethod() {
            const btn = document.getElementById('ad-toggle-img-method');
            const urlBlock = document.getElementById('ad-img-url-block');
            const fileBlock = document.getElementById('ad-img-file-block');
            const previewBlock = document.getElementById('ad-image-preview');

            if (sampathiAdImageMethod === 'url') {
                sampathiAdImageMethod = 'file';
                btn.textContent = '🔗 Switch to URL Link';
                urlBlock.style.display = 'none';
                fileBlock.style.display = 'block';
            } else {
                sampathiAdImageMethod = 'url';
                btn.textContent = '📁 Switch to File Upload';
                urlBlock.style.display = 'block';
                fileBlock.style.display = 'none';
                previewBlock.style.display = 'none';
                sampathiAdSelectedFile = null;
            }
        }

        function sampathiPreviewAdImage(event) {
            const file = event.target.files[0];
            if (!file) return;
            sampathiAdSelectedFile = file;

            const reader = new FileReader();
            reader.onload = (e) => {
                document.getElementById('ad-preview-img').src = e.target.result;
                document.getElementById('ad-image-preview').style.display = 'block';
            };
            reader.readAsDataURL(file);
        }

        async function sampathiUploadAdImageToMediaLibrary(file) {
            const formData = new FormData();

            const extMatch = file.name.match(/\.[a-zA-Z0-9]+$/);
            const ext = extMatch ? extMatch[0] : '.jpg';
            const safeName = `sampathi-ad-${Date.now()}${ext}`;

            formData.append('file', file, safeName);

            const res = await fetch(`${SAMPATHI_ADS_REST_URL.replace('/sampathi/v1', '/wp/v2')}/media`, {
                method: 'POST',
                headers: {
                    'X-WP-Nonce': SAMPATHI_ADS_NONCE,
                    'Content-Disposition': `attachment; filename="${safeName}"`,
                },
                body: formData,
            });

            const data = await res.json();
            if (!res.ok) throw new Error(data.message || 'Image upload failed');
            return data.source_url;
        }

        async function sampathiBookAd(e) {
            e.preventDefault();

            let bannerImageUrl = undefined;
            try {
                if (sampathiAdImageMethod === 'file' && sampathiAdSelectedFile) {
                    sampathiShowAdStatus('⏳ Uploading banner image...', false);
                    bannerImageUrl = await sampathiUploadAdImageToMediaLibrary(sampathiAdSelectedFile);
                } else {
                    const urlVal = document.getElementById('ad-banner-image').value.trim();
                    if (urlVal.length > 0) bannerImageUrl = urlVal;
                }
            } catch (err) {
                sampathiShowAdStatus('❌ Image upload failed: ' + err.message, true);
                return;
            }

            const payload = {
                business_name: document.getElementById('ad-business').value,
                heading: document.getElementById('ad-heading').value,
                position: document.getElementById('ad-position').value,
                banner_image: bannerImageUrl,
                landing_url: document.getElementById('ad-landing-url').value.trim() || undefined,
                start_date: `${document.getElementById('ad-start-date').value} ${document.getElementById('ad-start-time').value}:00`,
                duration_days: parseInt(document.getElementById('ad-duration').value),
                fast_forward: document.getElementById('ad-fast-forward').checked,
            };

            fetch(`${SAMPATHI_ADS_REST_URL}/ads/add`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-WP-Nonce': SAMPATHI_ADS_NONCE,
                },
                body: JSON.stringify(payload)
            })
            .then(async res => {
                const data = await res.json();
                if (!res.ok) throw new Error(data.message || 'Failed to book ad');
                return data;
            })
            .then(data => {
                sampathiShowAdStatus('✅ Campaign scheduled successfully (ID: ' + data.id + '). Reloading...', false);
                setTimeout(() => window.location.reload(), 1200);
            })
            .catch(err => {
                sampathiShowAdStatus('❌ Failed: ' + err.message, true);
            });
        }

        // Wire every status dropdown in the campaigns table: on change,
        // push the new status to the backend and recolor the select itself.
        document.querySelectorAll('.sampathi-ad-status-select').forEach(select => {
            select.addEventListener('change', function () {
                const adId = this.dataset.adId;
                const newStatus = this.value;
                const colors = { active: '#22C55E', scheduled: '#F59E0B', inactive: '#9CA3AF', expired: '#EF4444' };

                fetch(`${SAMPATHI_ADS_REST_URL}/ads/update-status`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-WP-Nonce': SAMPATHI_ADS_NONCE,
                    },
                    body: JSON.stringify({ id: parseInt(adId), status: newStatus }),
                })
                .then(res => res.json())
                .then(data => {
                    if (data.success) {
                        this.style.background = colors[newStatus] || '#9CA3AF';
                    } else {
                        alert('Failed to update status: ' + (data.message || 'unknown error'));
                    }
                })
                .catch(err => alert('Failed to update status: ' + err.message));
            });
        });
    </script>
    <?php
}
