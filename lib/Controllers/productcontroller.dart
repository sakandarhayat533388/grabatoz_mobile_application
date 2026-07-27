import 'dart:developer' as developer;
import 'package:graba2z/Configs/config.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShopController extends GetxController {
  var productList = <dynamic>[].obs;
  var isLoading = false.obs;

  Future<void> fetchProducts({
    required String? id,
    required String? parentType,
    List<String> makeIds = const [],
    List<String> modelIds = const [],
    List<String> seriesIds = const [],
    List<String> manufacturerIds = const [],
    List<String> soldByIds = const [],
    String sortBy = 'newest',
    int page = 1,
    int limit = 2500,
  }) async {
    try {
      isLoading(true);

      final uri = _buildProductsUri(
        id: id,
        parentType: parentType,
        makeIds: makeIds,
        modelIds: modelIds,
        seriesIds: seriesIds,
        manufacturerIds: manufacturerIds,
        soldByIds: soldByIds,
        sortBy: sortBy,
        page: page,
        limit: limit,
      );

      developer.log("Fetching products: $uri", name: "FetchProducts");
      var response = await http.get(uri);
      List<dynamic>? productData;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        productData = _extractProductList(decoded);
      }

      // Fallback if primary query returned 0 products
      if ((productData == null || productData.isEmpty) &&
          id != null &&
          id.trim().isNotEmpty &&
          makeIds.isEmpty &&
          modelIds.isEmpty &&
          seriesIds.isEmpty) {
        final lower = (parentType ?? '').toLowerCase().trim();
        final fallbackParam = (lower == 'subcategory') ? 'subCategory' : 'category';
        final fallbackUri = Uri.parse(Configss.product)
            .replace(queryParameters: {fallbackParam: id.trim()});
        developer.log("Fallback fetching products: $fallbackUri", name: "FetchProducts");
        final fallbackRes = await http.get(fallbackUri);
        if (fallbackRes.statusCode == 200) {
          final decoded = json.decode(fallbackRes.body);
          final fallbackData = _extractProductList(decoded);
          if (fallbackData != null && fallbackData.isNotEmpty) {
            productData = fallbackData;
          }
        }
      }

      if (productData != null) {
        final filtered = <dynamic>[];
        for (final item in productData) {
          if (item is Map<String, dynamic>) {
            filtered.add(item);
          } else if (item is Map) {
            filtered.add(Map<String, dynamic>.from(item));
          } else {
            developer.log("Skipping non-map item: $item",
                name: "FetchProducts");
          }
        }
        productList.value = filtered;
      } else {
        productList.clear();
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Uri _buildProductsUri({
    required String? id,
    required String? parentType,
    required List<String> makeIds,
    required List<String> modelIds,
    required List<String> seriesIds,
    required List<String> manufacturerIds,
    required List<String> soldByIds,
    required String sortBy,
    required int page,
    required int limit,
  }) {
    final cleanMakeIds = makeIds.where((e) => e.trim().isNotEmpty).toList();
    final cleanModelIds = modelIds.where((e) => e.trim().isNotEmpty).toList();
    final cleanSeriesIds = seriesIds.where((e) => e.trim().isNotEmpty).toList();
    final cleanManufacturerIds =
        manufacturerIds.where((e) => e.trim().isNotEmpty).toList();
    final cleanSoldByIds = soldByIds.where((e) => e.trim().isNotEmpty).toList();
    final hasSystemFilters = cleanMakeIds.isNotEmpty ||
        cleanModelIds.isNotEmpty ||
        cleanSeriesIds.isNotEmpty ||
        cleanManufacturerIds.isNotEmpty ||
        cleanSoldByIds.isNotEmpty;

    if (hasSystemFilters) {
      final baseUri = Uri.parse(Configss.shopQueryProducts);
      final params = <String>[];

      void addParam(String key, String value) {
        params.add(
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
        );
      }

      for (final makeId in cleanMakeIds) {
        addParam('make', makeId);
      }
      for (final modelId in cleanModelIds) {
        addParam('model', modelId);
      }
      for (final seriesId in cleanSeriesIds) {
        addParam('series', seriesId);
      }
      for (final manufacturerId in cleanManufacturerIds) {
        addParam('manufacturer', manufacturerId);
      }
      for (final soldById in cleanSoldByIds) {
        addParam('soldBy', soldById);
      }

      final productParam = _productFilterParam(parentType);
      if (productParam != null && id != null && id.trim().isNotEmpty) {
        addParam(productParam, id.trim());
      }

      addParam('page', page.toString());
      addParam('limit', limit.toString());
      if (sortBy.trim().isNotEmpty) {
        addParam('sortBy', sortBy.trim());
      }

      return baseUri.replace(query: params.join('&'));
    }

    final queryParams = <String, String>{};
    final productParam = _productFilterParam(parentType);
    if (productParam != null && id != null && id.trim().isNotEmpty) {
      queryParams[productParam] = id.trim();
    }

    return Uri.parse(Configss.product).replace(queryParameters: queryParams);
  }

  String? _productFilterParam(String? parentType) {
    final lower = (parentType ?? '').toLowerCase().trim();
    if (lower == 'subcategory') return 'subcategory';
    if (lower == 'parentcategory' || lower == 'category') return 'parentCategory';
    if (lower == 'brand') return 'brand';
    return 'parentCategory';
  }

  List<dynamic>? _extractProductList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      for (final key in ['data', 'products', 'items', 'results']) {
        final value = decoded[key];
        if (value is List) return value;
        if (value is Map<String, dynamic>) {
          final nested = _extractProductList(value);
          if (nested != null) return nested;
        }
      }
    }
    return null;
  }

  // Future<void> fetchGamingZoneProducts({required String slug}) async {
  //   try {
  //     isLoading(true);

  //     final url =
  //         "https://api.grabatoz.ae/api/gaming-zone-pages/slug/$slug/products?limit=1200";

  //     final response = await http.get(Uri.parse(url));

  //     // 🔹 Debug raw response
  //     print("Raw Response Body: ${response.body}");
  //     developer.log(response.body, name: "GamingZoneRaw");

  //     dynamic decoded;
  //     try {
  //       decoded = json.decode(response.body);
  //     } catch (e) {
  //       print("Failed to decode JSON: $e");
  //       developer.log("Failed to decode JSON: $e", name: "GamingZone");
  //       productList.clear();
  //       return;
  //     }

  //     // 🔹 Debug decoded response
  //     print("Gaming Zone Response: $decoded");
  //     developer.log(decoded.toString(), name: "GamingZone");
  //     developer.log(
  //         "Products count: ${decoded['products']?.length ?? 0}",
  //         name: "GamingZone"
  //     );
  //     // 🔹 Parse products safely
  //     List<dynamic> products = [];

  //     if (decoded is Map<String, dynamic> && decoded['products'] != null && decoded['products'] is List) {
  //       products = decoded['products'];
  //     } else if (decoded is List) {
  //       products = decoded;
  //     } else {
  //       productList.clear(); // no products found
  //       return;
  //     }

  //     // 🔹 Flatten products: if each item has a nested 'product' field, extract it
  //     final flattened = <dynamic>[];
  //     for (final item in products) {
  //       if (item is Map<String, dynamic>) {
  //         // Check if product is nested inside a 'product' field
  //         if (item.containsKey('product') && item['product'] is Map<String, dynamic>) {
  //           flattened.add(item['product']);
  //         } else {
  //           // Product is already at root level
  //           flattened.add(item);
  //         }
  //       } else {
  //         // Skip non-map items
  //         developer.log("Skipping non-map product: $item", name: "GamingZone");
  //       }
  //     }

  //     productList.value = flattened;

  //   } catch (e) {
  //     Get.snackbar("Error", e.toString());
  //   } finally {
  //     isLoading(false);
  //   }
  // }
}
