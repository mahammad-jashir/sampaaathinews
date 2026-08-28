class Category {
  final int id;
  final String name;
  final String slug;

  Category({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}

class District {
  final int id;
  final String name;
  final String slug;

  District({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}

class Reporter {
  final int id;
  final String name;
  final String photoUrl;
  final String bio;
  final String designation;

  Reporter({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.bio,
    required this.designation,
  });

  factory Reporter.fromJson(Map<String, dynamic> json) {
    return Reporter(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      photoUrl: json['photo_url'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      bio: json['bio'] ?? '',
      designation: json['designation'] ?? 'ವರದಿಗಾರರು (Reporter)',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photo_url': photoUrl,
      'bio': bio,
      'designation': designation,
    };
  }
}

class Article {
  final int id;
  final String title;
  final String subtitle;
  final String content;
  final String excerpt;
  final String featuredImageUrl;
  final String datePublished;
  final String dateModified;
  final int readingTime;
  final int viewCount;
  final List<Category> categories;
  final List<District> districts;
  final Reporter reporter;
  final String shareUrl;

  Article({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.excerpt,
    required this.featuredImageUrl,
    required this.datePublished,
    required this.dateModified,
    required this.readingTime,
    required this.viewCount,
    required this.categories,
    required this.districts,
    required this.reporter,
    required this.shareUrl,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    var catList = <Category>[];
    if (json['categories_data'] != null) {
      catList = (json['categories_data'] as List)
          .map((c) => Category.fromJson(c))
          .toList();
    }
    
    var distList = <District>[];
    if (json['districts_data'] != null) {
      distList = (json['districts_data'] as List)
          .map((d) => District.fromJson(d))
          .toList();
    }

    return Article(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      content: json['content'] ?? '',
      excerpt: json['excerpt'] ?? '',
      featuredImageUrl: json['featured_image_url'] ?? 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800',
      datePublished: json['date_published'] ?? '',
      dateModified: json['date_modified'] ?? '',
      readingTime: json['reading_time'] ?? 3,
      viewCount: json['view_count'] ?? 0,
      categories: catList,
      districts: distList,
      reporter: Reporter.fromJson(json['reporter'] ?? {}),
      shareUrl: json['share_url'] ?? 'https://sampathinews.com/article/${json['id']}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'content': content,
      'excerpt': excerpt,
      'featured_image_url': featuredImageUrl,
      'date_published': datePublished,
      'date_modified': dateModified,
      'reading_time': readingTime,
      'view_count': viewCount,
      'categories_data': categories.map((c) => c.toJson()).toList(),
      'districts_data': districts.map((d) => d.toJson()).toList(),
      'reporter': reporter.toJson(),
      'share_url': shareUrl,
    };
  }
}

class Advertisement {
  final int id;
  final String businessName;
  final String title;
  final String imageUrl;
  final String landingUrl;
  final String position; // e.g., 'header_banner', 'homepage_banner', 'sidebar_banner'
  final String package; // 'bronze', 'silver', 'gold', 'platinum'
  final String startDate;
  final String endDate;
  final String status; // 'active', 'scheduled', 'expired'
  final int priority; // higher priority loads first
  final int? categoryId; // target category id (if any)
  final int? districtId; // target district id (if any)

  Advertisement({
    required this.id,
    required this.businessName,
    required this.title,
    required this.imageUrl,
    required this.landingUrl,
    required this.position,
    required this.package,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.priority,
    this.categoryId,
    this.districtId,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'] ?? 0,
      businessName: json['business_name'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? 'https://images.unsplash.com/photo-1542744094-3a31f103e35f?w=600',
      landingUrl: json['landing_url'] ?? '',
      position: json['position'] ?? 'homepage_banner',
      package: json['package'] ?? 'bronze',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: json['status'] ?? 'expired',
      priority: json['priority'] ?? 1,
      categoryId: json['category_id'],
      districtId: json['district_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': businessName,
      'title': title,
      'image_url': imageUrl,
      'landing_url': landingUrl,
      'position': position,
      'package': package,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      'priority': priority,
      'category_id': categoryId,
      'district_id': districtId,
    };
  }

  /// Evaluates client-side if the ad is active at the current moment
  bool isCurrentlyActive() {
    if (status != 'active') return false;
    try {
      final now = DateTime.now();
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return true; // fallback to WordPress DB-computed status if parse fails
    }
  }
}
