class ImageHelper {
  static const String _baseUrl = "https://api.grabatoz.ae";

  static String getUrl(String? url) {
    if (url == null || url.trim().isEmpty) return "";

    final trimmed = url.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (trimmed.startsWith('/')) {
      return "$_baseUrl$trimmed";
    }

    return "$_baseUrl/$trimmed";
  }

  static List<String> extractProductImages(dynamic productData) {
    final List<String> images = [];

    void addSingle(dynamic item) {
      if (item == null) return;
      if (item is List) {
        for (var subItem in item) {
          addSingle(subItem);
        }
        return;
      }
      if (item is Map) {
        final url = item['url'] ?? item['src'] ?? item['path'] ?? item['image'];
        addSingle(url);
        return;
      }
      final str = item.toString().trim();
      if (str.isNotEmpty && str.toLowerCase() != 'null' && !images.contains(str)) {
        images.add(str);
      }
    }

    if (productData is Map) {
      const keys = [
        'image',
        'mainImage',
        'thumbnail',
        'primaryImage',
        'galleryImages',
        'images',
        'gallery',
        'imageUrls',
        'productImages',
      ];
      for (final k in keys) {
        addSingle(productData[k]);
      }
    } else if (productData is String) {
      addSingle(productData);
    } else if (productData is List) {
      addSingle(productData);
    }

    if (images.isEmpty) {
      images.add('https://i.postimg.cc/SsWYSvq6/noimage.png');
    }

    return images;
  }
}
