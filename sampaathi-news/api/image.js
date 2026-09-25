const path = require('path');
const fs = require('fs');

// Pre-configured fallback image URLs for seed articles
const seedArticles = {
  '1': {
    featured_image_url: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=1200'
  },
  '2': {
    featured_image_url: 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=1200'
  },
  '3': {
    featured_image_url: 'https://images.unsplash.com/photo-1506015391300-4802dc74de2e?w=1200'
  },
  '4': {
    featured_image_url: 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=1200'
  },
  '1790317731256': {
    featured_image_url: 'https://sampaaathinews.vercel.app/assets/images/article_1790317731256.jpg'
  }
};

module.exports = async (req, res) => {
  const id = req.query.id || (req.url.match(/(?:article\/|news\/|id=)([0-9]+)/) || [])[1] || '';

  // 1. Check if a static file exists locally on disk first (super fast response)
  if (id) {
    const candidateLocalImages = [
      path.join(process.cwd(), 'assets', 'images', `article_${id}.jpg`),
      path.join(process.cwd(), 'build', 'web', 'assets', 'images', `article_${id}.jpg`),
      path.join(__dirname, '..', 'assets', 'images', `article_${id}.jpg`),
      path.join(__dirname, '..', 'build', 'web', 'assets', 'images', `article_${id}.jpg`)
    ];
    for (const imgPath of candidateLocalImages) {
      if (fs.existsSync(imgPath)) {
        try {
          const fileBuf = fs.readFileSync(imgPath);
          res.setHeader('Content-Type', 'image/jpeg');
          res.setHeader('Content-Length', fileBuf.length);
          res.setHeader('Cache-Control', 'public, max-age=86400, s-maxage=86400, stale-while-revalidate=604800');
          return res.status(200).send(fileBuf);
        } catch (_) {}
      }
    }
  }

  // 2. Fetch article from backend API
  const baseUrl = process.env.WORDPRESS_API_URL || 'https://sampathi-backend.onrender.com/wp-json';
  let article = null;

  if (id) {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 6000);
      const resp = await fetch(`${baseUrl.replace(/\/$/, '')}/sampathi/v1/news/${id}`, {
        signal: controller.signal
      });
      clearTimeout(timeout);
      if (resp.ok) {
        article = await resp.json();
      }
    } catch (e) {
      // Backend sleeping or network error; fall back to seedArticles
    }
  }

  if (!article && seedArticles[id]) {
    article = seedArticles[id];
  }

  const defaultLogo = 'https://sampaaathinews.vercel.app/assets/images/logo.png';
  const img = (article && article.featured_image_url) ? article.featured_image_url : null;

  if (!img) {
    return res.redirect(302, defaultLogo);
  }

  // 3. Handle base64 data URI (uploaded images) -> return raw image binary
  if (img.startsWith('data:image/')) {
    try {
      const matches = img.match(/^data:image\/([a-zA-Z0-9+]+);base64,(.+)$/);
      const mimeType = matches ? `image/${matches[1]}` : 'image/jpeg';
      const base64Data = matches ? matches[2] : img.split(';base64,').pop();
      const buffer = Buffer.from(base64Data, 'base64');

      res.setHeader('Content-Type', mimeType);
      res.setHeader('Content-Length', buffer.length);
      res.setHeader('Cache-Control', 'public, max-age=86400, s-maxage=86400, stale-while-revalidate=604800');
      return res.status(200).send(buffer);
    } catch (err) {
      console.error('Error parsing base64 image in api/image.js:', err);
      return res.redirect(302, defaultLogo);
    }
  }

  // 4. Handle external HTTP / HTTPS URLs
  if (img.startsWith('http://') || img.startsWith('https://')) {
    res.setHeader('Cache-Control', 'public, max-age=86400, s-maxage=86400');
    return res.redirect(302, img);
  }

  return res.redirect(302, defaultLogo);
};
