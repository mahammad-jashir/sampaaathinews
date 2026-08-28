import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class SeoHelper {
  /// Dynamically updates the page title, meta descriptions, and OpenGraph/JSON-LD schemas for SEO scrapers.
  static void updateMetadata({
    required String title,
    required String description,
    required String url,
    String? imageUrl,
    String? type,
    Map<String, dynamic>? jsonLdSchema,
  }) {
    if (!kIsWeb) return;

    // 1. Update Title
    html.document.title = "$title | ಸಂಪಾತಿ ನ್ಯೂಸ್ - Sampathi News";

    // 2. Update Standard Meta Description
    _updateOrCreateMeta('name="description"', 'description', description);

    // 3. Update OpenGraph (Facebook/WhatsApp/Telegram) Tags
    _updateOrCreateMeta('property="og:title"', 'og:title', title, isProperty: true);
    _updateOrCreateMeta('property="og:description"', 'og:description', description, isProperty: true);
    _updateOrCreateMeta('property="og:url"', 'og:url', url, isProperty: true);
    _updateOrCreateMeta('property="og:type"', 'og:type', type ?? 'article', isProperty: true);
    if (imageUrl != null) {
      _updateOrCreateMeta('property="og:image"', 'og:image', imageUrl, isProperty: true);
    }

    // 4. Update Twitter Card Tags
    _updateOrCreateMeta('name="twitter:card"', 'twitter:card', 'summary_large_image');
    _updateOrCreateMeta('name="twitter:title"', 'twitter:title', title);
    _updateOrCreateMeta('name="twitter:description"', 'twitter:description', description);
    if (imageUrl != null) {
      _updateOrCreateMeta('name="twitter:image"', 'twitter:image', imageUrl);
    }

    // 5. Update Canonical URL
    _updateOrCreateLink('canonical', url);

    // 6. Inject JSON-LD Schema
    if (jsonLdSchema != null) {
      _injectJsonLd(jsonLdSchema);
    }
  }

  /// Updates or creates a meta tag in the document header.
  static void _updateOrCreateMeta(String selector, String nameOrProperty, String content, {bool isProperty = false}) {
    final head = html.document.head;
    if (head == null) return;

    var element = head.querySelector('meta[$selector]');
    if (element == null) {
      element = html.MetaElement();
      if (isProperty) {
        element.setAttribute('property', nameOrProperty);
      } else {
        element.setAttribute('name', nameOrProperty);
      }
      head.append(element);
    }
    element.setAttribute('content', content);
  }

  /// Updates or creates a link tag in the document header.
  static void _updateOrCreateLink(String rel, String href) {
    final head = html.document.head;
    if (head == null) return;

    var element = head.querySelector('link[rel="$rel"]');
    if (element == null) {
      element = html.LinkElement()..setAttribute('rel', rel);
      head.append(element);
    }
    element.setAttribute('href', href);
  }

  /// Injects a JSON-LD structured data script.
  static void _injectJsonLd(Map<String, dynamic> schema) {
    final head = html.document.head;
    if (head == null) return;

    // Remove existing schema scripts
    final oldSchema = head.querySelectorAll('script[type="application/ld+json"]');
    for (var el in oldSchema) {
      el.remove();
    }

    // Add new schema script
    final script = html.ScriptElement()
      ..setAttribute('type', 'application/ld+json')
      ..text = _mapToJsonString(schema);
    head.append(script);
  }

  static String _mapToJsonString(Map<String, dynamic> map) {
    // Simple custom JSON serializer to avoid bringing in heavy converters, 
    // or standard jsonEncode.
    importStringify(dynamic value) {
      if (value is String) {
        return '"${value.replaceAll('"', '\\"')}"';
      } else if (value is num || value is bool) {
        return value.toString();
      } else if (value is Map<String, dynamic>) {
        return '{${value.entries.map((e) => '"${e.key}": ${importStringify(e.value)}').join(', ')}}';
      } else if (value is List) {
        return '[${value.map((item) => importStringify(item)).join(', ')}]';
      }
      return 'null';
    }
    return importStringify(map);
  }

  /// Builds a standard article JSON-LD schema helper.
  static Map<String, dynamic> buildArticleSchema({
    required String headline,
    required String description,
    required String url,
    required String datePublished,
    required String dateModified,
    required String authorName,
    required String authorPhoto,
    required String imageUrl,
  }) {
    return {
      "@context": "https://schema.org",
      "@type": "NewsArticle",
      "mainEntityOfPage": {
        "@type": "WebPage",
        "@id": url
      },
      "headline": headline,
      "description": description,
      "image": imageUrl,
      "datePublished": datePublished,
      "dateModified": dateModified,
      "author": {
        "@type": "Person",
        "name": authorName,
        "image": authorPhoto
      },
      "publisher": {
        "@type": "Organization",
        "name": "Sampathi News",
        "logo": {
          "@type": "ImageObject",
          "url": "https://sampathinews.com/assets/images/logo.png"
        }
      }
    };
  }
}

// Simple schema helper for a list of items
class SchemaBuilder {
  static Map<String, dynamic> buildBreadcrumbSchema(List<Map<String, String>> steps) {
    final listItems = <Map<String, dynamic>>[];
    for (int i = 0; i < steps.length; i++) {
      listItems.add({
        "@type": "ListItem",
        "position": i + 1,
        "name": steps[i]['name'],
        "item": steps[i]['url']
      });
    }
    return {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      "itemListElement": listItems
    };
  }
}
