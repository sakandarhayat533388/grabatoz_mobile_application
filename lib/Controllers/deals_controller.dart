import 'dart:developer' as developer;
import 'dart:async';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:graba2z/Configs/config.dart';

class DealsController extends GetxController {
  var productList = <dynamic>[].obs;
  var isLoading = false.obs;

  // Cache for brand and category info to avoid multiple API calls
  final Map<String, String> brandCache = {};
  final Map<String, String> categoryCache = {};

  var offerCategories = <dynamic>[].obs;
  var offerBrands = <dynamic>[].obs;

  Future<void> fetchDealsProducts({
    required String? slug,
  }) async {
    try {
      isLoading(true);

      final url = Configss.getOfferProducts(slug ?? 'hot-deals');

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Deals API timeout'),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        developer.log("Deals API Response received", name: "FetchDealsProducts");

        final filtered = <dynamic>[];

        // Handle response - API returns array of offers with nested product field
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              if (item.containsKey('product') && item['product'] is Map<String, dynamic>) {
                final product = item['product'] as Map<String, dynamic>;
                filtered.add(product);
              } else {
                filtered.add(item);
              }
            } else if (item is Map) {
              filtered.add(Map<String, dynamic>.from(item));
            }
          }
        } else if (decoded is Map<String, dynamic>) {
          dynamic dataField;
          if (decoded['data'] is List) {
            dataField = decoded['data'];
          } else if (decoded['products'] is List) {
            dataField = decoded['products'];
          } else if (decoded['product'] is List) {
            dataField = decoded['product'];
          }

          if (dataField is List) {
            for (final item in dataField) {
              if (item is Map<String, dynamic>) {
                if (item.containsKey('product') && item['product'] is Map<String, dynamic>) {
                  filtered.add(item['product'] as Map<String, dynamic>);
                } else {
                  filtered.add(item);
                }
              } else if (item is Map) {
                filtered.add(Map<String, dynamic>.from(item));
              }
            }
          }
        }

        // Set products immediately for fast display
        productList.value = filtered;
        isLoading(false);
        developer.log("Loaded ${filtered.length} deals products", name: "FetchDealsProducts");

        // Enrich data in background (non-blocking)
        _enrichProductsInBackground(filtered);

      } else {
        Get.snackbar("Error", "Failed to load deals: ${response.statusCode}");
        developer.log("API Error: ${response.statusCode}", name: "FetchDealsProducts");
        isLoading(false);
      }
    } catch (e) {
      Get.snackbar("Error", "Error loading deals: $e");
      developer.log("Exception: $e", name: "FetchDealsProducts");
      isLoading(false);
    }
  }

  // Enrich products in background without blocking UI
  Future<void> _enrichProductsInBackground(List<dynamic> products) async {
    for (final product in products) {
      if (product is Map<String, dynamic>) {
        await _enrichProductData(product);
      }
    }
    // Trigger UI update after enrichment
    productList.refresh();
  }

  /// Enrich product data by fetching brand and category names from their IDs
  Future<void> _enrichProductData(Map<String, dynamic> product) async {
    try {
      // Extract brand and category IDs first
      String? brandId;
      String? categoryId;

      // Brand extraction with better debugging
      if (product.containsKey('brand') && product['brand'] != null) {
        final brand = product['brand'];
        developer.log("🔍 Brand data type: ${brand.runtimeType}, value: $brand", name: "EnrichProductData");

        if (brand is Map) {
          // Brand is already an object - just check if it has name
          final brandName = brand['name'] ?? brand['_name'] ?? '';
          if (brandName.toString().isNotEmpty) {
            developer.log("✅ Brand already has name: $brandName", name: "EnrichProductData");
            brandId = null; // Skip API call since we already have the name
          } else {
            // Brand object exists but no name - try to get ID and fetch
            brandId = brand['_id'] ?? brand['id'];
          }
        } else if (brand is String) {
          brandId = brand;
        } else {
          brandId = brand?.toString();
        }

        if (brandId != null && brandId.toString().isEmpty) {
          brandId = null;
        } else if (brandId != null) {
          brandId = brandId.toString();
        }
        developer.log("🔍 Extracted brandId: $brandId", name: "EnrichProductData");
      }

      // Category extraction
      if (product.containsKey('parentCategory') && product['parentCategory'] != null) {
        final category = product['parentCategory'];
        developer.log("Category data type: ${category.runtimeType}, value: $category", name: "EnrichProductData");

        if (category is Map) {
          categoryId = category['_id'] ?? category['id'];
        } else if (category is String) {
          categoryId = category;
        } else {
          categoryId = category?.toString();
        }

        if (categoryId != null && categoryId.toString().isEmpty) {
          categoryId = null;
        } else if (categoryId != null) {
          categoryId = categoryId.toString();
        }
        developer.log("Extracted categoryId: $categoryId", name: "EnrichProductData");
      }

      // Fetch brand and category names in parallel if IDs exist
      final futures = <Future>[];
      String? brandName;
      String? categoryName;

      if (brandId != null && brandId!.isNotEmpty) {
        developer.log("Fetching brand name for ID: $brandId", name: "EnrichProductData");
        futures.add(
          _getBrandName(brandId).then((name) {
            brandName = name;
            developer.log("Got brand name: $name for ID: $brandId", name: "EnrichProductData");
          })
        );
      } else {
        developer.log("Skipping brand fetch - no valid brandId", name: "EnrichProductData");
      }

      if (categoryId != null && categoryId!.isNotEmpty) {
        developer.log("Fetching category name for ID: $categoryId", name: "EnrichProductData");
        futures.add(
          _getCategoryName(categoryId).then((name) {
            categoryName = name;
            developer.log("Got category name: $name for ID: $categoryId", name: "EnrichProductData");
          })
        );
      }

      // Wait for all futures to complete
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

      // Update product with fetched names
      if (brandName != null && brandName!.isNotEmpty) {
        if (product['brand'] is Map) {
          product['brand']['name'] = brandName;
        } else {
          product['brand'] = {'_id': brandId, 'name': brandName};
        }
        developer.log("Updated product with brand name: $brandName", name: "EnrichProductData");
      }

      if (categoryName != null && categoryName!.isNotEmpty) {
        if (product['parentCategory'] is Map) {
          product['parentCategory']['name'] = categoryName;
        } else {
          product['parentCategory'] = {'_id': categoryId, 'name': categoryName};
        }
        developer.log("Updated product with category name: $categoryName", name: "EnrichProductData");
      }
    } catch (e) {
      developer.log("Error enriching product data: $e", name: "EnrichProductData");
    }
  }

  /// Fetch brand name by ID with timeout protection
  Future<String> _getBrandName(String brandId) async {
    try {
      // Check cache first
      if (brandCache.containsKey(brandId)) {
        final cached = brandCache[brandId] ?? '';
        developer.log("Cached brand name for $brandId: $cached", name: "GetBrandName");
        return cached;
      }

      // API call to get brand by ID with timeout
      final url = '${Configss.baseUrl}/api/brands/$brandId';
      developer.log("Fetching brand from URL: $url", name: "GetBrandName");

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 3), // Reduced timeout
        onTimeout: () {
          developer.log("Brand fetch timeout for $brandId", name: "GetBrandName");
          return http.Response('', 504); // Return empty response on timeout
        },
      );

      developer.log("Brand API Response status: ${response.statusCode}", name: "GetBrandName");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log("Brand API Response data: $data", name: "GetBrandName");

        final brandData = (data is Map) ? data : (data is List && data.isNotEmpty) ? data[0] : null;

        if (brandData is Map) {
          final name = brandData['name'] ?? brandData['_name'] ?? brandData['title'] ?? '';
          brandCache[brandId] = name;
          developer.log("Fetched and cached brand name: $name for ID: $brandId", name: "GetBrandName");
          return name;
        }
      }
    } on TimeoutException {
      developer.log("TimeoutException for brand $brandId", name: "GetBrandName");
    } catch (e, s) {
      developer.log("Error fetching brand name: $e\nStacktrace: $s", name: "GetBrandName");
    }
    return '';
  }

  /// Fetch category name by ID with caching
  Future<String> _getCategoryName(String categoryId) async {
    try {
      // Check cache first
      if (categoryCache.containsKey(categoryId)) {
        final cached = categoryCache[categoryId] ?? '';
        developer.log("Returning cached category name for $categoryId: $cached", name: "GetCategoryName");
        return cached;
      }

      // API call to get category by ID
      final url = '${Configss.baseUrl}/api/categories/$categoryId';
      developer.log("Fetching category from URL: $url", name: "GetCategoryName");

      final response = await http.get(Uri.parse(url));
      developer.log("Category API Response status: ${response.statusCode}", name: "GetCategoryName");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log("Category API Response data: $data", name: "GetCategoryName");

        // Handle both direct object and wrapped response
        final categoryData = (data is Map) ? data : (data is List && data.isNotEmpty) ? data[0] : null;

        if (categoryData is Map) {
          final name = categoryData['name'] ?? categoryData['_name'] ?? categoryData['title'] ?? '';
          categoryCache[categoryId] = name;
          developer.log("Fetched and cached category name: $name for ID: $categoryId", name: "GetCategoryName");
          return name;
        }
      } else {
        developer.log("Category API error - status: ${response.statusCode}, body: ${response.body}", name: "GetCategoryName");
      }
    } catch (e, s) {
      developer.log("Error fetching category name: $e\nStacktrace: $s", name: "GetCategoryName");
    }
    return '';
  }

  /// Fetch offer categories for a page slug according to API docs: GET /api/offer-categories/page/:slug
  Future<void> fetchOfferCategories(String slug) async {
    try {
      final url = Configss.getOfferCategories(slug);
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          offerCategories.value = decoded;
        }
      }
    } catch (e) {
      developer.log("Error fetching offer categories: $e", name: "FetchOfferCategories");
    }
  }

  /// Fetch offer brands for a page slug according to API docs: GET /api/offer-brands/page/:slug
  Future<void> fetchOfferBrands(String slug) async {
    try {
      final url = Configss.getOfferBrands(slug);
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          offerBrands.value = decoded;
        }
      }
    } catch (e) {
      developer.log("Error fetching offer brands: $e", name: "FetchOfferBrands");
    }
  }
}
