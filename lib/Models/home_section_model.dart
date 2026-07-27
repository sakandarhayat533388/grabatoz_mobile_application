import 'package:graba2z/Utils/image_helper.dart';

class HomeSectionSettings {
  final int cardsCount;
  final int cardsPerRow;
  final bool showArrows;
  final String backgroundColor;
  final String sideImage;
  final String backgroundImage;

  HomeSectionSettings({
    this.cardsCount = 5,
    this.cardsPerRow = 2,
    this.showArrows = true,
    this.backgroundColor = '#ffffff',
    this.sideImage = '',
    this.backgroundImage = '',
  });

  String get sideImageUrl => ImageHelper.getUrl(sideImage);
  String get backgroundImageUrl => ImageHelper.getUrl(backgroundImage);

  factory HomeSectionSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HomeSectionSettings();
    return HomeSectionSettings(
      cardsCount: json['cardsCount'] is int
          ? json['cardsCount']
          : int.tryParse(json['cardsCount']?.toString() ?? '') ?? 5,
      cardsPerRow: json['cardsPerRow'] is int
          ? json['cardsPerRow']
          : int.tryParse(json['cardsPerRow']?.toString() ?? '') ?? 2,
      showArrows: json['showArrows'] ?? true,
      backgroundColor: json['backgroundColor']?.toString() ?? '#ffffff',
      sideImage: json['sideImage']?.toString() ?? '',
      backgroundImage: json['backgroundImage']?.toString() ?? '',
    );
  }
}

class HomeSectionModel {
  final String id;
  final String name;
  final String nameAr;
  final String slug;
  final String key;
  final String description;
  final String descriptionAr;
  final bool isActive;
  final int order;
  final String sectionType;
  final HomeSectionSettings settings;

  HomeSectionModel({
    required this.id,
    required this.name,
    this.nameAr = '',
    required this.slug,
    this.key = '',
    this.description = '',
    this.descriptionAr = '',
    this.isActive = true,
    this.order = 1,
    required this.sectionType,
    required this.settings,
  });

  static int _parseOrder(dynamic rawOrder) {
    if (rawOrder == null) return 1;
    if (rawOrder is int) return rawOrder;
    if (rawOrder is num) return rawOrder.toInt();
    final str = rawOrder.toString().trim();
    final parsedInt = int.tryParse(str);
    if (parsedInt != null) return parsedInt;
    final parsedDouble = double.tryParse(str);
    if (parsedDouble != null) return parsedDouble.toInt();
    return 1;
  }

  factory HomeSectionModel.fromJson(Map<String, dynamic> json) {
    return HomeSectionModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      descriptionAr: json['descriptionAr']?.toString() ?? '',
      isActive: json['isActive'] ?? true,
      order: _parseOrder(json['order']),
      sectionType: json['sectionType']?.toString() ?? 'simple-cards',
      settings: HomeSectionSettings.fromJson(
        json['settings'] is Map<String, dynamic> ? json['settings'] : null,
      ),
    );
  }
}

class BannerCardModel {
  final String id;
  final String name;
  final String nameAr;
  final String slug;
  final String details;
  final String detailsAr;
  final String image;
  final String mobileImage;
  final String section;
  final String linkUrl;
  final bool isActive;
  final int order;
  final String bgColor;

  BannerCardModel({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.slug = '',
    this.details = '',
    this.detailsAr = '',
    required this.image,
    this.mobileImage = '',
    this.section = '',
    this.linkUrl = '',
    this.isActive = true,
    this.order = 0,
    this.bgColor = '#ffffff',
  });

  // Helper getter to pick mobile image if available, else fallback to image, resolved through ImageHelper
  String get displayImage {
    String selectedUrl = '';
    if (mobileImage.trim().isNotEmpty) {
      selectedUrl = mobileImage.trim();
    } else {
      selectedUrl = image.trim();
    }
    return ImageHelper.getUrl(selectedUrl);
  }

  factory BannerCardModel.fromJson(Map<String, dynamic> json) {
    return BannerCardModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      detailsAr: json['detailsAr']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      mobileImage: json['mobileImage']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      linkUrl: json['linkUrl']?.toString() ?? '',
      isActive: json['isActive'] ?? true,
      order: json['order'] is int
          ? json['order']
          : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      bgColor: json['bgColor']?.toString() ?? '#ffffff',
    );
  }
}
