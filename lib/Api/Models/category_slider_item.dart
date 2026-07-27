class CategorySliderItem {
  final String? id;
  final String? name;
  final String? image;
  final String? redirectUrl;
  final String? slug;
  final String type; // 'custom' or 'category'

  CategorySliderItem({
    this.id,
    this.name,
    this.image,
    this.redirectUrl,
    this.slug,
    required this.type,
  });

  factory CategorySliderItem.fromCustomJson(Map<String, dynamic> json) {
    return CategorySliderItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['title']?.toString() ?? json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? json['imageUrl']?.toString() ?? '',
      redirectUrl: json['redirectUrl']?.toString() ??
          json['redirect_url']?.toString() ??
          json['link']?.toString() ??
          json['url']?.toString(),
      slug: json['slug']?.toString(),
      type: 'custom',
    );
  }

  factory CategorySliderItem.fromCategoryJson(Map<String, dynamic> json) {
    return CategorySliderItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      image: json['image']?.toString() ?? json['imageUrl']?.toString() ?? '',
      slug: json['slug']?.toString(),
      redirectUrl: json['redirectUrl']?.toString() ??
          json['redirect_url']?.toString() ??
          json['link']?.toString(),
      type: 'category',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'image': image,
      'redirectUrl': redirectUrl,
      'slug': slug,
      'type': type,
    };
  }
}
