const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Serve static preview files from public folder
app.use(express.static(path.join(__dirname, 'public')));

// --- IN-MEMORY DATABASE STATE (Simulating WordPress DB) ---
let categories = [
  { id: 1, name: 'ಪ್ರಮುಖ ಸುದ್ದಿ', slug: 'top-stories' },
  { id: 2, name: 'ದಕ್ಷಿಣ ಕನ್ನಡ', slug: 'dakshina-kannada' },
  { id: 3, name: 'ಉಡುಪಿ', slug: 'udupi' },
  { id: 4, name: 'ಕೊಡಗು', slug: 'kodagu' },
  { id: 5, name: 'ಕ್ರೀಡೆ', slug: 'sports' },
  { id: 6, name: 'ದೇಶ-ವಿದೇಶ', slug: 'country-and-abroad' },
  { id: 7, name: 'ರಾಜ್ಯ', slug: 'state' }
];

let districts = [
  { id: 101, name: 'ಸುಳ್ಯ (Sullia)', slug: 'sullia' },
  { id: 102, name: 'ಪುತ್ತೂರು (Puttur)', slug: 'puttur' },
  { id: 103, name: 'ಮಂಗಳೂರು (Mangalore)', slug: 'mangalore' },
  { id: 104, name: 'ಉಡುಪಿ (Udupi)', slug: 'udupi' },
  { id: 105, name: 'ಕೊಡಗು (Kodagu)', slug: 'kodagu' }
];

let reporters = [
  {
    id: 10,
    name: 'ಸಂಪಾದಕೀಯ ತಂಡ (Editorial Team)',
    photo_url: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
    bio: 'ಸಂಪಾತಿ ನ್ಯೂಸ್ ಸುದ್ದಿ ವಿಭಾಗದ ಹಿರಿಯ ಪತ್ರಕರ್ತರು.',
    designation: 'ಹಿರಿಯ ಸಂಪಾದಕರು (Chief Editor)'
  }
];

let articles = [
  {
    id: 1,
    title: 'ಸುಳ್ಯ : ಎನ್ನೆoಪಿಯುಸಿಯಲ್ಲಿ ಕಾರ್ಗಿಲ್ ವಿಜಯ್ ದಿವಸ್ ಆಚರಣೆ',
    subtitle: 'ಹುತಾತ್ಮ ಯೋಧರ ತ್ಯಾಗಕ್ಕೆ ಕಾಲೇಜಿನಲ್ಲಿ ಭಾವಪೂರ್ಣ ನಮನ',
    excerpt: 'ಸುಳ್ಯದ ನೆಹರೂ ಸ್ಮಾರಕ ಪದವಿ ಪೂರ್ವ ಕಾಲೇಜಿನಲ್ಲಿ ಕಾರ್ಗಿಲ್ ವಿಜಯ್ ದಿವಸ್ ಸಂಭ್ರಮದಿಂದ ಆಚರಿಸಲಾಯಿತು. ಯೋಧರ ತ್ಯಾಗವನ್ನು ದೇಶದ ಹೆಮ್ಮೆಯ ಸಂಕೇತವೆಂದು ಸ್ಮರಿಸಲಾಯಿತು.',
    content: '<p><strong>ಸುಳ್ಯ:</strong> ನೆಹರೂ ಸ್ಮಾರಕ ಪದವಿ ಪೂರ್ವ ಕಾಲೇಜಿನ ಎನ್‌ಸಿಸಿ ಘಟಕ ಮತ್ತು ಸಾಂಸ್ಕೃತಿಕ ವೇದಿಕೆಯ ಸಂಯುಕ್ತ ಆಶ್ರಯದಲ್ಲಿ ಕಾರ್ಗಿಲ್ ವಿಜಯ್ ದಿವಸ್ ಆಚರಿಸಲಾಯಿತು.</p><p>ಕಾರ್ಯಕ್ರಮದ ಮುಖ್ಯ ಅತಿಥಿಗಳು ಮಾತನಾಡಿ, ಭಾರತೀಯ ಸೇನೆಯ ಶೌರ್ಯ ಮತ್ತು ಹುತಾತ್ಮ ಯೋಧರ ದೇಶಭಕ್ತಿ ಇಂದಿನ ಯುವ ಪೀಳಿಗೆಗೆ ದಾರಿದೀಪವಾಗಿದೆ. ಗಡಿಯಲ್ಲಿ ಕಾವಲು ಕಾಯುವ ಸೈನಿಕರ ಧೀರತನವೇ ನಮ್ಮ ದೇಶದ ಭದ್ರತೆಯ ಅಡಿಪಾಯ ಎಂದರು. ವಿದ್ಯಾರ್ಥಿಗಳು ಹುತಾತ್ಮರ ಭಾವಚಿತ್ರಕ್ಕೆ ಪುಷ್ಪ ನಮನ ಸಲ್ಲಿಸಿ ಗೌರವ ಸಮರ್ಪಿಸಿದರು.</p>',
    featured_image_url: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=1200',
    date_published: new Date().toISOString(),
    date_modified: new Date().toISOString(),
    reading_time: 3,
    view_count: 1420,
    categories_data: [categories[1], categories[6]],
    districts_data: [districts[0]],
    reporter: reporters[0],
    share_url: 'http://localhost:3000/article.html?id=1'
  },
  {
    id: 2,
    title: 'ನಟ ರಕ್ಷಿತ್ ಶೆಟ್ಟಿ ತಂದೆ-ತಾಯಿಗೆ 50ನೇ ವಿವಾಹ ವಾರ್ಷಿಕೋತ್ಸವ ಸಂಭ್ರಮ',
    subtitle: 'ಉಡುಪಿಯಲ್ಲಿ ನಡೆದ ಸರಳ ಕೌಟುಂಬಿಕ ಸಡಗರದ ವಿಡಿಯೋ ವೈರಲ್',
    excerpt: 'ಕರಾವಳಿಯ ಖ್ಯಾತ ಚಲನಚಿತ್ರ ನಿರ್ದೇಶಕ ಮತ್ತು ನಟ ರಕ್ಷಿತ್ ಶೆಟ್ಟಿ ಅವರ ತಂದೆ-ತಾಯಿಯರ 50ನೇ ವರ್ಷದ ಸುವರ್ಣ ಮಹೋತ್ಸವ ವಿವಾಹ ವಾರ್ಷಿಕೋತ್ಸವ ಉಡುಪಿಯಲ್ಲಿ ನೆರವೇರಿತು.',
    content: '<p><strong>ಉಡುಪಿ:</strong> ಕನ್ನಡ ಚಿತ್ರರಂಗದ ಖ್ಯಾತ ನಟ ರಕ್ಷಿತ್ ಶೆಟ್ಟಿ ಪೋಷಕರಾದ ಶ್ರೀಧರ್ ಶೆಟ್ಟಿ ಮತ್ತು ರಂಜನಿ ಶೆಟ್ಟಿ ಅವರ 50ನೇ ವಿವಾಹ ವಾರ್ಷಿಕೋತ್ಸವವನ್ನು ಹತ್ತಿರದ ಸಂಬಂಧಿಗಳು ಹಾಗೂ ಆಪ್ತರ ಸಮ್ಮುಖದಲ್ಲಿ ಆಚರಿಸಲಾಯಿತು.</p><p>ಸಾಮಾಜಿಕ ಜಾಲತಾಣಗಳಲ್ಲಿ ಈ ಸುಂದರ ಕ್ಷಣಗಳ ಫೋಟೋಗಳನ್ನು ರಕ್ಷಿತ್ ಶೆಟ್ಟಿ ಹಂಚಿಕೊಂಡಿದ್ದು, ಅಭಿಮಾನಿಗಳಿಂದ ಮತ್ತು ಚಿತ್ರರಂಗದ ಗಣ್ಯರಿಂದ ವ್ಯಾಪಕ ಅಭಿನಂದನೆಗಳ ಸುರಿಮಳೆಯಾಗಿದೆ.</p>',
    featured_image_url: 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=1200',
    date_published: new Date().toISOString(),
    date_modified: new Date().toISOString(),
    reading_time: 2,
    view_count: 2450,
    categories_data: [categories[2], categories[6]],
    districts_data: [districts[3]],
    reporter: reporters[0],
    share_url: 'http://localhost:3000/article.html?id=2'
  },
  {
    id: 3,
    title: 'ಬ್ರಹ್ಮಾವರ: ಬಸ್ - ಕಾರು ಭೀಕರ ಅಪಘಾತ, ಕರಾವಳಿಯ ಖ್ಯಾತ ಹುلیವೇಷ ಕಲಾವಿದ ಸ್ಥಳದಲ್ಲೇ ಸಾವು..!',
    subtitle: 'ರಾಷ್ಟ್ರೀಯ ಹೆದ್ದಾರಿಯಲ್ಲಿ ಚಾಲಕನ ನಿಯಂತ್ರಣ ತಪ್ಪಿ ಸಂಭವಿಸಿದ ಅವಘಡ',
    excerpt: 'ಬ್ರಹ್ಮಾವರದ ಸಮೀಪ ರಾಷ್ಟ್ರೀಯ ಹೆದ್ದಾರಿಯಲ್ಲಿ ಖಾಸಗಿ ಎಕ್ಸ್‌ಪ್ರೆಸ್ ಬಸ್ ಮತ್ತು ಕಾರಿನ ನಡುವೆ ಸಂಭವಿಸಿದ ಮುಖಾಮುಖಿ ಭೀಕರ ಅಪಘಾತದಲ್ಲಿ ಕರಾವಳಿಯ ಜನಪ್ರಿಯ ಹುಲಿವೇಷ ಕಲಾವಿದ ಸ್ಥಳದಲ್ಲೇ ಮೃತಪಟ್ಟಿದ್ದಾರೆ.',
    content: '<p><strong>ಬ್ರಹ್ಮಾವರ:</strong> ರಾಷ್ಟ್ರೀಯ ಹೆದ್ದಾರಿ 66 ರ ಕರಾವಳಿ ಜಂಕ್ಷನ್ ಬಳಿ ಭೀಕರ ಅಪಘಾತ ಸಂಭವಿಸಿದೆ. ಮಂಗಳೂರಿನಿಂದ ಕುಂದಾಪುರ ಕಡೆಗೆ ಚಲಿಸುತ್ತಿದ್ದ ಖಾಸಗಿ ಬಸ್ ಮತ್ತು ಎದುರಿನಿಂದ ಬರುತ್ತಿದ್ದ ಕಾರಿನ ನಡುವೆ ಸಂಭವಿಸಿದ ಡಿಕ್ಕಿಯ ರಭಸಕ್ಕೆ ಕಾರು ಸಂಪೂರ್ಣ ನಜ್ಜುಗುಜ್ಜಾಗಿದೆ.</p><p>ಮೃತರನ್ನು ಕರಾವಳಿ ಭಾಗದ ಹೆಸರಾಂತ ಹುಲಿವೇಷ ತಂಡದ ಪ್ರಮುಖ ಕಲಾವಿದ ಎಂದು ಗುರುತಿಸಲಾಗಿದ್ದು, ಇಡೀ ಬ್ರಹ್ಮಾವರ ವಲಯ ಕಂಬನಿ ಮಿಡಿದಿದೆ. ಸ್ಥಳಕ್ಕೆ ಪೊಲೀಸರು ಧಾವಿಸಿ ತನಿಖೆ ಮುಂದುವರಿಸಿದ್ದಾರೆ.</p>',
    featured_image_url: 'https://images.unsplash.com/photo-1506015391300-4802dc74de2e?w=1200',
    date_published: new Date(Date.now() - 86400000).toISOString(),
    date_modified: new Date(Date.now() - 86400000).toISOString(),
    reading_time: 4,
    view_count: 3120,
    categories_data: [categories[2], categories[6]],
    districts_data: [districts[3]],
    reporter: reporters[0],
    share_url: 'http://localhost:3000/article.html?id=3'
  },
  {
    id: 4,
    title: 'ಕೊಡಗಿನಲ್ಲಿ ಕೋವಿಡ್ ಎಚ್ಚರಿಕೆ, ಚಿಕಿತ್ಸೆಗೆ ಅಗತ್ಯ ಸಿದ್ಧತೆ ಪೂರ್ಣ : ಜಿಲ್ಲಾ ಆಸ್ಪತ್ರೆಯಲ್ಲಿ 40 ಹಾಸಿಗೆ ಮೀಸಲು',
    subtitle: 'ಆರೋಗ್ಯ ಇಲಾಖೆಯಿಂದ ಮಾರ್ಗಸೂಚಿ ಪ್ರಕಟ, ಸಾರ್ವಜನಿಕರಲ್ಲಿ ಜಾಗೃತಿ',
    excerpt: 'ಕೊಡಗು ಜಿಲ್ಲೆಯಲ್ಲಿ ಕೋವಿಡ್ ಪ್ರಕರಣಗಳ ಸಂಭವನೀಯ ಹೆಚ್ಚಳದ ಹಿನ್ನೆಲೆಯಲ್ಲಿ ಆರೋಗ್ಯ ಇಲಾಖೆ ಕಟ್ಟೆಚ್ಚರ ವಹಿಸಿದ್ದು ಮಡಿಕೇರಿಯ ಜಿಲ್ಲಾ ಆಸ್ಪತ್ರೆಯಲ್ಲಿ ಅಗತ್ಯ ವೈದ್ಯಕೀಯ ಹಾಸಿಗೆಗಳನ್ನು ಸಿದ್ಧಪಡಿಸಿದೆ.',
    content: '<p><strong>ಮಡಿಕೇರಿ:</strong> ನೆರೆಯ ಕೇರಳ ಗಡಿಭಾಗದಲ್ಲಿ ವೈರಲ್ ಜ್ವರ ಪ್ರಕರಣಗಳು ವರದಿಯಾಗುತ್ತಿರುವುದರಿಂದ ಕೊಡಗು ಜಿಲ್ಲಾಡಳಿತ ಮುನ್ನೆಚ್ಚರಿಕೆ ವಹಿಸಿದೆ.</p><p>ಜಿಲ್ಲಾ ವೈದ್ಯಾಧಿಕಾರಿಗಳು ಪ್ರಕಟಣೆ ನೀಡಿ, ಸಾರ್ವಜನಿಕರು ಆತಂಕಪಡುವ ಅಗತ್ಯವಿಲ್ಲ, ಮುಂಜಾಗ್ರತೆಯಾಗಿ ಮಾಸ್ಕ್ ಧರಿಸುವುದು ಸೂಕ್ತ. ಆಸ್ಪತ್ರೆಗಳಲ್ಲಿ ಗಂಟಲು ಮಾದರಿ ಸಂಗ್ರಹ ಮತ್ತು ಆಕ್ಸಿಜನ್ ಪೂರೈಕೆ ವ್ಯವಸ್ಥೆಯನ್ನು ಸುಸ್ಥಿತಿಯಲ್ಲಿಡಲಾಗಿದೆ ಎಂದಿದ್ದಾರೆ.</p>',
    featured_image_url: 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=1200',
    date_published: new Date(Date.now() - 172800000).toISOString(),
    date_modified: new Date(Date.now() - 172800000).toISOString(),
    reading_time: 3,
    view_count: 950,
    categories_data: [categories[3], categories[6]],
    districts_data: [districts[4]],
    reporter: reporters[0],
    share_url: 'http://localhost:3000/article.html?id=4'
  }
];

let advertisements = [
  {
    id: 501,
    business_name: 'ಕರಾವಳಿ ಫ್ರೆಶ್ ಫಿಶ್ (Karavali Fresh Fish)',
    title: 'ತಾಜಾ ಸಮುದ್ರದ ಮೀನುಗಳು - ನಿಮ್ಮ ಮನೆ ಬಾಗಿಲಿಗೆ',
    image_url: 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?w=1200',
    landing_url: 'https://sampathinews.com',
    position: 'header_banner',
    package: 'gold',
    start_date: new Date(Date.now() - 86400000).toISOString(),
    end_date: new Date(Date.now() + 86400000).toISOString(),
    status: 'active',
    priority: 5
  },
  {
    id: 502,
    business_name: 'ಕೆವಿಜಿ ಎಜುಕೇಷನ್ ಫೌಂಡೇಶನ್ (KVG Educational)',
    title: 'ಪ್ರವೇಶಾತಿಗೆ ಸೀಟುಗಳು ಲಭ್ಯವಿವೆ - ಸುಳ್ಯ ಕ್ಯಾಂಪಸ್',
    image_url: 'https://images.unsplash.com/photo-1601121141461-9d6647bca1ed?w=600',
    landing_url: 'https://sampathinews.com',
    position: 'sidebar_banner',
    package: 'platinum',
    start_date: new Date(Date.now() - 86400000).toISOString(),
    end_date: new Date(Date.now() + 86400000).toISOString(),
    status: 'active',
    priority: 10,
    district_id: 101 // Targets Sullia
  },
  {
    id: 503,
    business_name: 'ಮಂಗಳೂರು ಸ್ಪೋರ್ಟ್ಸ್ ಜೋನ್ (Mangalore Sports)',
    title: 'ಕ್ರೀಡಾ ಪರಿಕರಗಳ ಮೇಲಿನ ಭಾರಿ ರಿಯಾಯಿತಿ',
    image_url: 'https://images.unsplash.com/photo-1594913785162-e6785e50529e?w=800',
    landing_url: 'https://sampathinews.com',
    position: 'article_banner',
    package: 'silver',
    start_date: new Date(Date.now() - 86400000).toISOString(),
    end_date: new Date(Date.now() + 86400000).toISOString(),
    status: 'active',
    priority: 3,
    category_id: 5 // Targets Sports
  }
];

// --- LOCAL JSON FILE-BASED PERSISTENT STORAGE ---
const ADS_DB_PATH = path.join(__dirname, 'ads_db.json');
const ANALYTICS_DB_PATH = path.join(__dirname, 'analytics_db.json');
const NEWS_DB_PATH = path.join(__dirname, 'news_db.json');

// 1. Load articles from DB or save defaults
if (fs.existsSync(NEWS_DB_PATH)) {
  try {
    articles = JSON.parse(fs.readFileSync(NEWS_DB_PATH, 'utf8'));
  } catch (e) {
    console.error("Error reading news_db.json, using defaults", e);
  }
} else {
  fs.writeFileSync(NEWS_DB_PATH, JSON.stringify(articles, null, 2), 'utf8');
}

// 2. Load advertisements from DB or save defaults
if (fs.existsSync(ADS_DB_PATH)) {
  try {
    advertisements = JSON.parse(fs.readFileSync(ADS_DB_PATH, 'utf8'));
  } catch (e) {
    console.error("Error reading ads_db.json, using defaults", e);
  }
} else {
  fs.writeFileSync(ADS_DB_PATH, JSON.stringify(advertisements, null, 2), 'utf8');
}

// 3. Load analytics from DB or save defaults
let adAnalytics = [];
if (fs.existsSync(ANALYTICS_DB_PATH)) {
  try {
    adAnalytics = JSON.parse(fs.readFileSync(ANALYTICS_DB_PATH, 'utf8'));
  } catch (e) {
    console.error("Error reading analytics_db.json", e);
  }
} else {
  fs.writeFileSync(ANALYTICS_DB_PATH, JSON.stringify(adAnalytics, null, 2), 'utf8');
}

// Helper to write memory states back to files
function saveDb() {
  try {
    fs.writeFileSync(ADS_DB_PATH, JSON.stringify(advertisements, null, 2), 'utf8');
    fs.writeFileSync(ANALYTICS_DB_PATH, JSON.stringify(adAnalytics, null, 2), 'utf8');
    fs.writeFileSync(NEWS_DB_PATH, JSON.stringify(articles, null, 2), 'utf8');
  } catch (e) {
    console.error("Failed to persist database changes to files", e);
  }
}

// --- AUTOMATED SCHEDULER (WP-CRON SIMULATION) ---
setInterval(() => {
  const now = new Date();
  advertisements.forEach(ad => {
    const start = new Date(ad.start_date);
    const end = new Date(ad.end_date);

    if (ad.status === 'scheduled' && now >= start && now < end) {
      ad.status = 'active';
      console.log(`[SCHEDULER CRON] Ad '${ad.business_name}' transitioned to ACTIVE.`);
      saveDb();
    } else if (ad.status === 'active' && now >= end) {
      ad.status = 'expired';
      console.log(`[SCHEDULER CRON] Ad '${ad.business_name}' transitioned to EXPIRED.`);
      saveDb();
    }
  });
}, 5000); // Check every 5 seconds for interactive demonstration

// --- REST API ENDPOINTS ---

// Get News
app.get('/wp-json/sampathi/v1/news', (req, res) => {
  let filtered = [...articles];
  const { category, district, search } = req.query;

  if (category) {
    filtered = filtered.filter(a => a.categories_data.some(c => c.id == category));
  }
  if (district) {
    filtered = filtered.filter(a => a.districts_data.some(d => d.id == district));
  }
  if (search) {
    const query = search.toLowerCase();
    filtered = filtered.filter(a => a.title.toLowerCase().includes(query) || a.excerpt.toLowerCase().includes(query));
  }
  res.json(filtered);
});

// Get Single Article Details
app.get('/wp-json/sampathi/v1/news/:id', (req, res) => {
  const article = articles.find(a => a.id == req.params.id);
  if (!article) return res.status(404).json({ error: 'Article not found' });
  article.view_count++;
  res.json(article);
});

// Get Categories
app.get('/wp-json/sampathi/v1/categories', (req, res) => {
  res.json(categories);
});

// Get Districts
app.get('/wp-json/sampathi/v1/districts', (req, res) => {
  res.json(districts);
});

// Get Active Targeted Advertisements
app.get('/wp-json/sampathi/v1/ads', (req, res) => {
  const { position, category, district } = req.query;
  let activeAds = advertisements.filter(ad => ad.status === 'active');

  if (position) {
    activeAds = activeAds.filter(ad => ad.position === position);
  }
  if (category) {
    activeAds = activeAds.filter(ad => !ad.category_id || ad.category_id == category);
  }
  if (district) {
    activeAds = activeAds.filter(ad => !ad.district_id || ad.district_id == district);
  }

  // Sort by priority (descending)
  activeAds.sort((a, b) => b.priority - a.priority);
  res.json(activeAds);
});

// Track impressions & clicks
app.post('/wp-json/sampathi/v1/ads/track', (req, res) => {
  const { ad_id, action } = req.body;
  if (!ad_id || !['impression', 'click'].includes(action)) {
    return res.status(400).json({ error: 'Bad parameters' });
  }

  adAnalytics.push({
    ad_id,
    action,
    timestamp: new Date().toISOString(),
    device: Math.random() > 0.4 ? 'desktop' : 'mobile',
    browser: 'Chrome',
    location: 'Karnataka, IN'
  });

  saveDb();
  res.json({ success: true });
});

// Get Analytics report for the Dashboard
app.get('/wp-json/sampathi/v1/analytics/report', (req, res) => {
  const running = advertisements.filter(a => a.status === 'active').length;
  const scheduled = advertisements.filter(a => a.status === 'scheduled').length;
  const expired = advertisements.filter(a => a.status === 'expired').length;

  const impressions = adAnalytics.filter(ev => ev.action === 'impression').length;
  const clicks = adAnalytics.filter(ev => ev.action === 'click').length;
  const ctr = impressions > 0 ? ((clicks / impressions) * 100).toFixed(2) : '0.00';

  res.json({
    running,
    scheduled,
    expired,
    impressions,
    clicks,
    ctr,
    advertisements
  });
});

// Admin endpoint to book a new advertisement (scheduling demo)
app.post('/wp-json/sampathi/v1/ads/add', (req, res) => {
  const { business_name, title, image_url, position, duration_seconds, landing_url } = req.body;

  const start = new Date();
  const end = new Date(start.getTime() + (duration_seconds || 15) * 1000); // expires in N seconds

  const newAd = {
    id: Date.now(),
    business_name: business_name || 'ಟೆಸ್ಟ್ ಕಂಪನಿ',
    title: title || 'ವಿಶೇಷ ಕೊಡುಗೆ ಜಾಹೀರಾತು',
    image_url: image_url || 'https://images.unsplash.com/photo-1542744094-3a31f103e35f?w=600',
    landing_url: landing_url || 'https://google.com',
    position: position || 'sidebar_banner',
    package: 'bronze',
    start_date: start.toISOString(),
    end_date: end.toISOString(),
    status: 'scheduled',
    priority: 1
  };

  advertisements.push(newAd);
  saveDb();
  res.json(newAd);
});

// Admin endpoint to reactivate/renew an expired ad campaign
app.post('/wp-json/sampathi/v1/ads/reactivate', (req, res) => {
  const { ad_id } = req.body;
  const ad = advertisements.find(a => a.id == ad_id);
  if (!ad) return res.status(404).json({ error: 'Ad campaign not found' });

  const start = new Date();
  const end = new Date(start.getTime() + 7 * 24 * 60 * 60 * 1000); // Renew for 7 days

  ad.start_date = start.toISOString();
  ad.end_date = end.toISOString();
  ad.status = 'active'; // Set back to active immediately

  console.log(`[SCHEDULER] Ad '${ad.title}' has been manually RENEWED & REACTIVATED.`);
  saveDb();
  res.json(ad);
});

// Admin endpoint to manually deactivate an active ad campaign
app.post('/wp-json/sampathi/v1/ads/deactivate', (req, res) => {
  const { ad_id } = req.body;
  const ad = advertisements.find(a => a.id == ad_id);
  if (!ad) return res.status(404).json({ error: 'Ad campaign not found' });

  ad.status = 'expired'; // Set status to expired immediately
  ad.end_date = new Date().toISOString(); // Set end date to now

  console.log(`[SCHEDULER] Ad '${ad.title}' has been manually DEACTIVATED.`);
  saveDb();
  res.json(ad);
});

// Admin endpoint to add a new article dynamically
app.post('/wp-json/sampathi/v1/news/add', (req, res) => {
  const { title, subtitle, excerpt, content, featured_image_url, category_id, district_id, reading_time } = req.body;

  const catObj = categories.find(c => c.id == category_id) || categories[0];
  const distObj = districts.find(d => d.id == district_id) || districts[0];

  const newArticle = {
    id: Date.now(),
    title: title || 'ಹೊಸ ಸುದ್ದಿ',
    subtitle: subtitle || '',
    excerpt: excerpt || '',
    content: content || '<p>ಸುದ್ದಿ ವಿವರಗಳು...</p>',
    featured_image_url: featured_image_url || 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800',
    date_published: new Date().toISOString(),
    date_modified: new Date().toISOString(),
    reading_time: parseInt(reading_time) || 3,
    view_count: 0,
    categories_data: [catObj],
    districts_data: [distObj],
    reporter: reporters[0],
    share_url: `http://localhost:3000/article.html?id=${Date.now()}`
  };

  articles.unshift(newArticle); // Prepend to articles list (loads as latest story)
  saveDb();
  res.json(newArticle);
});


// Run server
app.listen(PORT, () => {
  console.log(`=============================================================`);
  console.log(`🚀 Sampathi News Headless mock server running at:`);
  console.log(`   http://localhost:${PORT}`);
  console.log(`=============================================================`);
});
