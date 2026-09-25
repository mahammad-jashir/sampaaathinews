const path = require('path');
const fs = require('fs');

module.exports = async (req, res) => {
  const id = req.query.id || (req.url.match(/\/article\/([0-9]+)/) || [])[1] || '';
  const baseUrl = process.env.WORDPRESS_API_URL || 'https://sampathi-backend.onrender.com/wp-json';

  let article = null;
  if (id) {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 15000);
      const resp = await fetch(`${baseUrl.replace(/\/$/, '')}/sampathi/v1/news/${id}`, {
        signal: controller.signal
      });
      clearTimeout(timeout);
      if (resp.ok) {
        article = await resp.json();
      }
    } catch (e) {
      // Backend sleeping or network error; fall back to static/seed dictionary & database
    }
  }

  // Check prototype/news_db.json if available
  if (!article && id) {
    const dbPaths = [
      path.join(process.cwd(), 'prototype', 'news_db.json'),
      path.join(__dirname, '..', 'prototype', 'news_db.json')
    ];
    for (const dbPath of dbPaths) {
      if (fs.existsSync(dbPath)) {
        try {
          const list = JSON.parse(fs.readFileSync(dbPath, 'utf8'));
          const found = list.find(item => String(item.id) === String(id));
          if (found) {
            article = found;
            break;
          }
        } catch (_) {}
      }
    }
  }

  // Pre-configured fallback headlines for seed articles if backend is waking up
  const seedArticles = {
    '1': {
      title: 'ಸುಳ್ಯ : ನೆಹರೂ ಕಾಲೇಜಿನಲ್ಲಿ ಕಾರ್ಗಿಲ್ ವಿಜಯ್ ದಿವಸ್ ಆಚರಣೆ',
      excerpt: 'ಸುಳ್ಯದ ನೆಹರೂ ಸ್ಮಾರಕ ಪದವಿ ಪೂರ್ವ ಕಾಲೇಜಿನಲ್ಲಿ ಕಾರ್ಗಿಲ್ ವಿಜಯ್ ದಿವಸ್ ಸಂಭ್ರಮದಿಂದ ಆಚರಿಸಲಾಯಿತು. ಯೋಧರ ತ್ಯಾಗವನ್ನು ದೇಶದ ಹೆಮ್ಮೆಯ ಸಂಕೇತವೆಂದು ಸ್ಮರಿಸಲಾಯಿತು.',
      featured_image_url: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=1200'
    },
    '2': {
      title: 'ನಟ ರಕ್ಷಿತ್ ಶೆಟ್ಟಿ ತಂದೆ-ತಾಯಿಗೆ 50ನೇ ವಿವಾಹ ವಾರ್ಷಿಕೋತ್ಸವ ಸಂಭ್ರಮ',
      excerpt: 'ಕರಾವಳಿಯ ಖ್ಯಾತ ಚಲನಚಿತ್ರ ನಿರ್ದೇಶಕ ಮತ್ತು ನಟ ರಕ್ಷಿತ್ ಶೆಟ್ಟಿ ಅವರ ತಂದೆ-ತಾಯಿಯರ 50ನೇ ವರ್ಷದ ಸುವರ್ಣ ಮಹೋತ್ಸವ ವಿವಾಹ ವಾರ್ಷಿಕೋತ್ಸವ ಉಡುಪಿಯಲ್ಲಿ ನೆರವೇರಿತು.',
      featured_image_url: 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=1200'
    },
    '3': {
      title: 'ಬ್ರಹ್ಮಾವರ: ಬಸ್ - ಕಾರು ಭೀಕರ ಅಪಘಾತ, ಕರಾವಳಿಯ ಖ್ಯಾತ ಹುಲಿವೇಷ ಕಲಾವಿದ ಸ್ಥಳದಲ್ಲೇ ಸಾವು..!',
      excerpt: 'ಬ್ರಹ್ಮಾವರದ ಸಮೀಪ ರಾಷ್ಟ್ರೀಯ ಹೆದ್ದಾರಿಯಲ್ಲಿ ಖಾಸಗಿ ಎಕ್ಸ್‌ಪ್ರೆಸ್ ಬಸ್ ಮತ್ತು ಕಾರಿನ ನಡುವೆ ಸಂಭವಿಸಿದ ಮುಖಾಮುಖಿ ಭೀಕರ ಅಪಘಾತದಲ್ಲಿ ಕರಾವಳಿಯ ಜನಪ್ರಿಯ ಹುಲಿವೇಷ ಕಲಾವಿದ ಸ್ಥಳದಲ್ಲೇ ಮೃತಪಟ್ಟಿದ್ದಾರೆ.',
      featured_image_url: 'https://images.unsplash.com/photo-1506015391300-4802dc74de2e?w=1200'
    },
    '4': {
      title: 'ಕೊಡಗಿನಲ್ಲಿ ಕೋವಿಡ್ ಎಚ್ಚರಿಕೆ, ಚಿಕಿತ್ಸೆಗೆ ಅಗತ್ಯ ಸಿದ್ಧತೆ ಪೂರ್ಣ : ಜಿಲ್ಲಾ ಆಸ್ಪತ್ರೆಯಲ್ಲಿ 40 ಹಾಸಿಗೆ ಮೀಸಲು',
      excerpt: 'ಕೊಡಗು ಜಿಲ್ಲೆಯಲ್ಲಿ ಕೋವಿಡ್ ಪ್ರಕರಣಗಳ ಸಂಭವನೀಯ ಹೆಚ್ಚಳದ ಹಿನ್ನೆಲೆಯಲ್ಲಿ ಆರೋಗ್ಯ ಇಲಾಖೆ ಕಟ್ಟೆಚ್ಚರ ವಹಿಸಿದ್ದು ಮಡಿಕೇರಿಯ ಜಿಲ್ಲಾ ಆಸ್ಪತ್ರೆಯಲ್ಲಿ ಅಗತ್ಯ ವೈದ್ಯಕೀಯ ಹಾಸಿಗೆಗಳನ್ನು ಸಿದ್ಧಪಡಿಸಿದೆ.',
      featured_image_url: 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=1200'
    },
    '1790317731256': {
      title: 'ಕಾರಿಗೆ ನಾಯಿ ಅಡ್ಡ',
      excerpt: 'ಕಾರಿಗೆ ನಾಯಿ ಅಡ್ಡ ಬಂದ ಪರಿಣಾಮ ಸಂಭವಿಸಿದ ಘಟನೆ. ಹೆಚ್ಚಿನ ಮಾಹಿತಿ ನಿರೀಕ್ಷಿಸಲಾಗುತ್ತಿದೆ.',
      featured_image_url: 'https://sampaaathinews.vercel.app/assets/images/article_1790317731256.jpg'
    }
  };

  if (!article && seedArticles[id]) {
    article = seedArticles[id];
    article.id = id;
  }

  const cleanTitle = (article && article.title ? article.title : 'ಸಂಪಾತಿ ನ್ಯೂಸ್ - ಕರ್ನಾಟಕದ ಪ್ರಮುಖ ಡಿಜಿಟಲ್ ಸುದ್ದಿ ಮಾಧ್ಯಮ')
    .replace(/"/g, '&quot;');
  const rawExcerpt = article && (article.excerpt || article.subtitle)
    ? article.excerpt || article.subtitle
    : 'ಕರಾವಳಿ, ಕರ್ನಾಟಕ ಮತ್ತು ದೇಶ-ವಿದೇಶಗಳ ಕ್ಷಣ ಕ್ಷಣದ ತಾಜಾ ಸುದ್ದಿಗಳು ಸಂಪಾತಿ ನ್ಯೂಸ್‌ನಲ್ಲಿ.';
  const cleanExcerpt = rawExcerpt.replace(/<[^>]*>?/gm, '').replace(/"/g, '&quot;');
  
  // WhatsApp / Facebook / Twitter require a real HTTP or HTTPS URL for og:image.
  // Base64 data:image URIs are rejected by social crawlers.
  let imageUrl = 'https://sampaaathinews.vercel.app/assets/images/logo.png';
  if (article && article.featured_image_url) {
    if (article.featured_image_url.startsWith('data:image/')) {
      imageUrl = `https://sampaaathinews.vercel.app/article/${id}/image.jpg`;
    } else if (article.featured_image_url.startsWith('http://') || article.featured_image_url.startsWith('https://')) {
      imageUrl = article.featured_image_url;
    }
  } else if (id) {
    imageUrl = `https://sampaaathinews.vercel.app/article/${id}/image.jpg`;
  }
  const pageUrl = `https://sampaaathinews.vercel.app/article/${id}`;

  // Find index.html
  let html = '';
  const candidatePaths = [
    path.join(process.cwd(), 'build', 'web', 'index.html'),
    path.join(process.cwd(), 'index.html'),
    path.join(__dirname, '..', 'build', 'web', 'index.html'),
    path.join(__dirname, '..', 'index.html')
  ];
  for (const p of candidatePaths) {
    if (fs.existsSync(p)) {
      html = fs.readFileSync(p, 'utf8');
      break;
    }
  }

  const ogTags = `
  <title>${cleanTitle} | ಸಂಪಾತಿ ನ್ಯೂಸ್</title>
  <meta name="description" content="${cleanExcerpt}">
  <!-- WhatsApp & Social OpenGraph Tags -->
  <meta property="og:site_name" content="ಸಂಪಾತಿ ನ್ಯೂಸ್ | Sampathi News">
  <meta property="og:title" content="${cleanTitle}">
  <meta property="og:description" content="${cleanExcerpt}">
  <meta property="og:image" content="${imageUrl}">
  <meta property="og:image:secure_url" content="${imageUrl}">
  <meta property="og:image:type" content="image/jpeg">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:url" content="${pageUrl}">
  <meta property="og:type" content="article">
  <!-- Twitter Card Tags -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${cleanTitle}">
  <meta name="twitter:description" content="${cleanExcerpt}">
  <meta name="twitter:image" content="${imageUrl}">
  `;

  if (html) {
    // Strip default static meta tags from index.html so dynamic tags take full precedence
    html = html
      .replace(/<title>.*?<\/title>/gi, '')
      .replace(/<meta\s+name=["']description["'][^>]*>/gi, '')
      .replace(/<meta\s+property=["']og:[^"']+["'][^>]*>/gi, '')
      .replace(/<meta\s+name=["']twitter:[^"']+["'][^>]*>/gi, '');

    html = html.replace('<head>', `<head>\n${ogTags}`);
  } else {
    html = `<!DOCTYPE html><html><head><meta charset="UTF-8">${ogTags}</head><body><script>window.location.href="/#/article/${id}";</script></body></html>`;
  }

  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 's-maxage=60, stale-while-revalidate');
  return res.status(200).send(html);
};
