<?php
/**
 * Renders the custom WordPress Admin "Publish News" page — same UI as the
 * original prototype's publish.html, but hosted inside wp-admin so it is
 * gated by WordPress's own login + capability system (no more fake
 * localStorage-based "admin" check), and stores directly into WordPress
 * via the site's own REST API using a nonce (no Application Password needed).
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

add_action( 'admin_menu', 'sampathi_news_register_publish_page' );

function sampathi_news_register_publish_page() {
    add_menu_page(
        'Publish News',
        'Publish News',
        'publish_posts', // any role that can publish posts (Author and above) can see this menu
        'sampathi-publish-news',
        'sampathi_news_render_publish_page',
        'dashicons-edit-page',
        5
    );
}

add_action( 'admin_enqueue_scripts', 'sampathi_news_enqueue_publish_page_assets' );

function sampathi_news_enqueue_publish_page_assets( $hook ) {
    // Only load our custom CSS on this specific admin page, not site-wide.
    if ( $hook !== 'toplevel_page_sampathi-publish-news' ) {
        return;
    }
    wp_enqueue_style(
        'sampathi-admin-styles',
        SAMPATHI_NEWS_CORE_URL . 'admin/assets/admin-styles.css',
        [],
        '1.0.0'
    );
}

function sampathi_news_render_publish_page() {
    if ( ! current_user_can( 'publish_posts' ) ) {
        wp_die( 'You do not have permission to publish news articles.' );
    }

    // A REST nonce lets our fetch() calls authenticate as the currently
    // logged-in WordPress user, without needing Application Passwords.
    $rest_nonce = wp_create_nonce( 'wp_rest' );
    $rest_url   = esc_url_raw( rest_url( 'sampathi/v1' ) );
    ?>
    <div class="wrap" style="background: var(--bg, #F1F5F9); margin: 0 -20px; padding: 24px;">
        <div style="max-width: 800px; margin: 0 auto; background: #fff; border-radius: 10px; padding: 32px; box-shadow: 0 1px 3px rgba(0,0,0,.08);">
            <h2 class="section-title">ಹೊಸ ಸುದ್ದಿ ಪ್ರಕಟಣೆ (Publish New Article)</h2>
            <div class="underline"></div>

            <div id="sampathi-publish-status" style="display:none; margin: 16px 0; padding: 12px 16px; border-radius: 6px; font-weight: 600;"></div>

            <form id="news-publish-form" class="booking-form" onsubmit="sampathiPublishNews(event)">
                <div class="form-group">
                    <label for="news-title">Headline / Title (ಸುದ್ದಿ ಶೀರ್ಷಿಕೆ):</label>
                    <input type="text" id="news-title" required placeholder="e.g., ರಾಜಧಾನಿಯಲ್ಲಿ ಭಾರಿ ಯಶಸ್ಸು ಕಂಡ ಕನ್ನಡ ತಂತ್ರಜ್ಞಾನ ಮೇಳ">
                </div>

                <div class="form-group">
                    <label for="news-sub">Subtitle (ಉಪಶೀರ್ಷಿಕೆ):</label>
                    <input type="text" id="news-sub" placeholder="e.g., ನೂರಾರು ಸ್ಟಾರ್ಟ್‌ಅಪ್‌ಗಳು ಭಾಗಿ, ಯುವ ಸಂಶೋಧಕರಿಗೆ ಪ್ರಶಸ್ತಿ ವಿತರಣೆ">
                </div>

                <div class="form-group">
                    <label for="news-exc">Excerpt / Brief Summary (ಸುದ್ದಿ ಮುಖ್ಯಾಂಶ):</label>
                    <input type="text" id="news-exc" required placeholder="e.g., ಕೃಷಿ ಮತ್ತು ಶಿಕ್ಷಣ ಕ್ಷೇತ್ರದಲ್ಲಿ ತಂತ್ರಜ್ಞಾನ ಬಳಕೆಯ ಬಗ್ಗೆ ಪ್ರಮುಖ ಪ್ರದರ್ಶನ...">
                </div>

                <div class="form-group">
                    <label for="news-body">News Content Body (ಲೇಖನ ಪೂರ್ಣ ಮಾಹಿತಿ - Paragraphs split by Enter):</label>
                    <textarea id="news-body" required rows="8" placeholder="ಇಲ್ಲಿ ಪೂರ್ಣ ಸುದ್ದಿಯ ವಿವರಗಳನ್ನು ಬರೆಯಿರಿ..." style="width: 100%; padding: 10px; border-radius: 6px; border: 1px solid #cbd5e1; font-family: inherit; font-size: 14px; outline: none;"></textarea>
                </div>

                <div class="form-group">
                    <label for="news-cat">Category (ಸುದ್ದಿ ವಿಭಾಗ):</label>
                    <select id="news-cat" required></select>
                </div>

                <div class="form-group">
                    <label for="news-dist">Target District (ಜಿಲ್ಲೆ):</label>
                    <select id="news-dist" required></select>
                </div>

                <div class="form-group">
                    <label>Featured Cover Image (ಮುಖಪುಟ ಚಿತ್ರ):</label>
                    <div style="display: flex; gap: 12px; margin-bottom: 8px;">
                        <button type="button" id="toggle-img-method" onclick="sampathiToggleImageMethod()" class="submit-btn" style="width: auto; padding: 6px 12px; font-size: 11px; background-color: #64748b; cursor: pointer;">📁 Switch to File Upload</button>
                    </div>

                    <div id="img-url-block">
                        <input type="url" id="news-img" placeholder="Paste image web URL here" style="width:100%; padding: 8px;">
                    </div>

                    <div id="img-file-block" style="display: none;">
                        <input type="file" id="news-image-file" accept="image/*" onchange="sampathiPreviewUploadedImage(event)">
                    </div>

                    <div id="image-preview" style="margin-top: 10px; display: none;">
                        <img id="preview-img" style="max-height: 120px; border-radius: 6px; border: 1px solid #cbd5e1; display: block;">
                    </div>
                </div>

                <div class="form-group">
                    <label for="news-dur">Estimated Reading Time (Minutes):</label>
                    <input type="number" id="news-dur" value="3" min="1" max="30" required>
                </div>

                <button type="submit" class="submit-btn" style="margin-top: 16px;">🚀 Publish Now (ಸುದ್ದಿ ಪ್ರಕಟಿಸಿ)</button>
            </form>
        </div>
    </div>

    <script>
        const SAMPATHI_REST_URL = <?php echo wp_json_encode( $rest_url ); ?>;
        const SAMPATHI_NONCE = <?php echo wp_json_encode( $rest_nonce ); ?>;

        window.addEventListener('DOMContentLoaded', () => {
            fetch(`${SAMPATHI_REST_URL}/categories`)
                .then(res => res.json())
                .then(data => {
                    document.getElementById('news-cat').innerHTML =
                        data.map(c => `<option value="${c.id}">${c.name}</option>`).join('');
                });

            fetch(`${SAMPATHI_REST_URL}/districts`)
                .then(res => res.json())
                .then(data => {
                    document.getElementById('news-dist').innerHTML =
                        data.map(d => `<option value="${d.id}">${d.name}</option>`).join('');
                });
        });

        function sampathiShowStatus(message, isError) {
            const el = document.getElementById('sampathi-publish-status');
            el.style.display = 'block';
            el.style.background = isError ? '#FEE2E2' : '#DCFCE7';
            el.style.color = isError ? '#991B1B' : '#166534';
            el.textContent = message;
        }

        let sampathiActiveImageMethod = 'url'; // 'url' or 'file'
        let sampathiSelectedFile = null;

        function sampathiToggleImageMethod() {
            const btn = document.getElementById('toggle-img-method');
            const urlBlock = document.getElementById('img-url-block');
            const fileBlock = document.getElementById('img-file-block');
            const previewBlock = document.getElementById('image-preview');

            if (sampathiActiveImageMethod === 'url') {
                sampathiActiveImageMethod = 'file';
                btn.textContent = '🔗 Switch to URL Link';
                urlBlock.style.display = 'none';
                fileBlock.style.display = 'block';
            } else {
                sampathiActiveImageMethod = 'url';
                btn.textContent = '📁 Switch to File Upload';
                urlBlock.style.display = 'block';
                fileBlock.style.display = 'none';
                previewBlock.style.display = 'none';
                sampathiSelectedFile = null;
            }
        }

        function sampathiPreviewUploadedImage(event) {
            const file = event.target.files[0];
            if (!file) return;
            sampathiSelectedFile = file;

            const reader = new FileReader();
            reader.onload = (e) => {
                document.getElementById('preview-img').src = e.target.result;
                document.getElementById('image-preview').style.display = 'block';
            };
            reader.readAsDataURL(file);
        }

        // Uploads the chosen file straight into the WordPress Media Library
        // (core /wp/v2/media endpoint) and returns the resulting image URL.
        async function sampathiUploadFileToMediaLibrary(file) {
            const formData = new FormData();

            // HTTP headers must be ASCII-only. If the original filename has
            // non-Latin characters (e.g. Kannada), passing it raw in the
            // Content-Disposition header gets mangled by the server, producing
            // a broken/inaccessible file. So we always generate a safe ASCII
            // filename ourselves, keeping only the original file extension.
            const extMatch = file.name.match(/\.[a-zA-Z0-9]+$/);
            const ext = extMatch ? extMatch[0] : '.jpg';
            const safeName = `sampathi-news-${Date.now()}${ext}`;

            formData.append('file', file, safeName);

            const res = await fetch(`${SAMPATHI_REST_URL.replace('/sampathi/v1', '/wp/v2')}/media`, {
                method: 'POST',
                headers: {
                    'X-WP-Nonce': SAMPATHI_NONCE,
                    'Content-Disposition': `attachment; filename="${safeName}"`,
                },
                body: formData,
            });

            const data = await res.json();
            if (!res.ok) throw new Error(data.message || 'Image upload failed');
            return data.source_url;
        }

        async function sampathiPublishNews(e) {
            e.preventDefault();

            const rawBody = document.getElementById('news-body').value;
            const content = rawBody.split('\n').filter(p => p.trim() !== '').map(p => `<p>${p}</p>`).join('');

            let featuredImageUrl = undefined;
            try {
                if (sampathiActiveImageMethod === 'file' && sampathiSelectedFile) {
                    sampathiShowStatus('⏳ Uploading image...', false);
                    featuredImageUrl = await sampathiUploadFileToMediaLibrary(sampathiSelectedFile);
                } else {
                    const urlVal = document.getElementById('news-img').value.trim();
                    if (urlVal.length > 0) featuredImageUrl = urlVal;
                }
            } catch (err) {
                sampathiShowStatus('❌ Image upload failed: ' + err.message, true);
                return;
            }

            const payload = {
                title: document.getElementById('news-title').value,
                subtitle: document.getElementById('news-sub').value,
                excerpt: document.getElementById('news-exc').value,
                content: content,
                category_id: parseInt(document.getElementById('news-cat').value),
                district_id: parseInt(document.getElementById('news-dist').value),
                featured_image_url: featuredImageUrl,
                reading_time: parseInt(document.getElementById('news-dur').value),
            };

            fetch(`${SAMPATHI_REST_URL}/news/add`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-WP-Nonce': SAMPATHI_NONCE, // authenticates as the logged-in WP admin
                },
                body: JSON.stringify(payload)
            })
            .then(async res => {
                const data = await res.json();
                if (!res.ok) throw new Error(data.message || 'Failed to publish');
                return data;
            })
            .then(data => {
                sampathiShowStatus('✅ ಸುದ್ದಿ ಯಶಸ್ವಿಯಾಗಿ ಪ್ರಕಟಿಸಲಾಗಿದೆ! (Published successfully — Post ID: ' + data.id + ')', false);
                document.getElementById('news-publish-form').reset();
                document.getElementById('image-preview').style.display = 'none';
                sampathiSelectedFile = null;
            })
            .catch(err => {
                sampathiShowStatus('❌ Failed to publish: ' + err.message, true);
            });
        }
    </script>
    <?php
}
