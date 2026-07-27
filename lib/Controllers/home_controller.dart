import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:graba2z/Api/Models/categorymodel.dart';
import 'package:graba2z/Configs/config.dart';
import "package:http/http.dart" as http;

class HomeController extends GetxController {
  final isCateloading = false.obs;
  final isprobyCateloaded = false.obs;
  final isprobyCateloaded2 = false.obs;
  final firstCategoryName = ''.obs;
  final firstId = ''.obs;
  final secondId = ''.obs;
  final secondCategoryName = ''.obs;
  final category = <categoriesModel>[].obs;
  final filterCategory = <categoriesModel>[].obs;

  final productBycategory = [].obs;
  final productBycategory2 = [].obs;
  final selectedCategoryId = ''.obs;
  final subcategory = <SubCategoryModel>[].obs;
  final filterSubcategory = <SubCategoryModel>[].obs;

  final subCateNames = <String>[].obs;
  final defaultSubCategory = SubCategoryModel(name: "All", sId: "");
  final isMoreDataAvailableForShop = true.obs;

  final RxMap<String, RxList<dynamic>> productsByCategoryIdMap = <String, RxList<dynamic>>{}.obs;
  final RxMap<String, RxBool> isLoadingProductsByCategoryIdMap = <String, RxBool>{}.obs;

  // --- New State for All Products by Category (No Pagination) ---
  final allProductsByCategoryMap = <String, RxList<dynamic>>{}.obs;
  final isLoadingAllProductsByCategoryMap = <String, RxBool>{}.obs;
  // --- End New State ---

  final RxList<dynamic> featuredProducts = <dynamic>[].obs;
  final RxBool isLoadingFeaturedProducts = true.obs;

  // Store current active pagination parameters
  String? _currentPagingCateId;
  String? _currentPagingParentType;
  String? _currentPagingSortby;
  String? _currentPagingBrandName;
  String? _currentPagingBrandId;
  String? _currentPagingFirstName;
  String? _currentPagingFirstValue;
  String? _currentPagingSecondName;
  String? _currentPagingSecondValue;
  double? _currentPagingMinPrice;
  double? _currentPagingMaxPrice;

  void filterSubcategoriesByCategory(String categoryId) {
    filterSubcategory.clear();
    filterSubcategory.add(SubCategoryModel(name: "All", sId: ""));
    filterSubcategory.addAll(
      subcategory.where((subCat) => subCat.category?.sId == categoryId),
    );
    update();
  }

  Future<List<SubCategoryModel>> getSubcategory() async {
    isCateloading.value = true;
    try {
      String url = "${Configss.getSubCategories}";
      var response = await http.get(Uri.parse(url));
      isCateloading.value = false;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        subcategory.clear();
        filterSubcategory.clear();
        filterSubcategory.add(defaultSubCategory);
        for (Map<String, dynamic> i in data) {
          subcategory.add(SubCategoryModel.fromJson(i));
          filterSubcategory.add(SubCategoryModel.fromJson(i));
        }
        update();
        return subcategory;
      } else {
        print('Failed to fetch subcategories: ${response.body}');
        return subcategory;
      }
    } catch (e) {
      isCateloading.value = false;
      print('⚠️ Network error fetching subcategories: $e');
      return subcategory;
    }
  }

  Future<List<categoriesModel>> getCategory() async {
    isCateloading.value = true;
    try {
      String url = "${Configss.getAllCategories}";
      var response = await http.get(Uri.parse(url));
      isCateloading.value = false;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        category.clear();
        filterCategory.clear();
        for (Map<String, dynamic> i in data) {
          if (i['isActive'] != false && i['isDeleted'] != true && i['status'] != 'inactive') {
            category.add(categoriesModel.fromJson(i));
            filterCategory.add(categoriesModel.fromJson(i));
          }
        }
        if (category.isNotEmpty) {
          selectedCategoryId.value = category.first.sId ?? '';
          if (category.length > 7) {
              firstCategoryName.value = category[5].name ?? '';
              secondCategoryName.value = category[7].name ?? '';
              firstId.value = category[5].sId ?? '';
              secondId.value = category[7].sId ?? '';
          } else if (category.length > 5) {
              firstCategoryName.value = category[5].name ?? '';
              firstId.value = category[5].sId ?? '';
              if(category.length > 6) {
                   secondCategoryName.value = category[6].name ?? '';
                   secondId.value = category[6].sId ?? '';
              } else {
                   secondCategoryName.value = category.last.name ?? '';
                   secondId.value = category.last.sId ?? '';
              }
          } else if (category.isNotEmpty) {
              firstCategoryName.value = category.first.name ?? '';
              firstId.value = category.first.sId ?? '';
              secondCategoryName.value = category.first.name ?? '';
              secondId.value = category.first.sId ?? '';
          }
          getHomeCategoryProducts();
          getsecondHomeCategoryProducts();
        }
        update();
        return category;
      } else {
        print('Failed to fetch categories: ${response.body}');
        return category;
      }
    } catch (e) {
      isCateloading.value = false;
      print('⚠️ Network error fetching categories: $e');
      return category;
    }
  }



  getHomeCategoryProducts() async {
    if (firstId.value.isEmpty) return;
    isprobyCateloaded.value = true;
    try {
      String url = "${Configss.searchAll}?parentCategory=${firstId.value}&limit=5"; 
      var response = await http.get(Uri.parse(url));
      isprobyCateloaded.value = false;
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] is List) {
          productBycategory.assignAll(responseData['data']);
        } else {
          productBycategory.clear();
        }
      } else {
        productBycategory.clear();
      }
    } catch (e) {
      isprobyCateloaded.value = false;
      productBycategory.clear();
      log('⚠️ Exception in getHomeCategoryProducts: $e');
    }
    update();
  }

  getsecondHomeCategoryProducts() async {
    if (secondId.value.isEmpty) return;
    isprobyCateloaded2.value = true;
    try {
      String url = "${Configss.searchAll}?parentCategory=${secondId.value}&limit=5";
      var response = await http.get(Uri.parse(url));
      isprobyCateloaded2.value = false;
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] is List) {
          productBycategory2.assignAll(responseData['data']);
        } else {
          productBycategory2.clear();
        }
      } else {
        productBycategory2.clear();
      }
    } catch (e) {
      isprobyCateloaded2.value = false;
      productBycategory2.clear();
      log('⚠️ Exception in getsecondHomeCategoryProducts: $e');
    }
    update();
  }

  // Method to fetch products for a category, used by home screen sections
  Future<void> fetchProductsForCategory(String categoryId, {String? categoryNameForLog, int fetchLimit = 5}) async {
    final String logName = categoryNameForLog ?? categoryId;
    isLoadingProductsByCategoryIdMap.putIfAbsent(categoryId, () => false.obs);
    isLoadingProductsByCategoryIdMap[categoryId]!.value = true;
    productsByCategoryIdMap.putIfAbsent(categoryId, () => <dynamic>[].obs);
    productsByCategoryIdMap[categoryId]!.clear();

    try {
      String url = "${Configss.searchAll}?parentCategory=${categoryId}&limit=$fetchLimit"; // Use fetchLimit
      log('[fetchProductsForCategory] Fetching for "$logName" with limit $fetchLimit: $url');
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] is List) {
          productsByCategoryIdMap[categoryId]!.assignAll(responseData['data']);
        }
      } else {
         productsByCategoryIdMap[categoryId]!.clear(); // Clear on error too
         log('[fetchProductsForCategory] HTTP Error ${response.statusCode} for "$logName": ${response.body}');
      }
    } catch (e) {
      productsByCategoryIdMap[categoryId]?.clear(); // Null-safe clear
      log('Exception fetching products for $logName: $e');
    } finally {
      isLoadingProductsByCategoryIdMap[categoryId]!.value = false;
    }
  }

  // --- New Method to Fetch All Products for a Category (No Pagination) ---
  Future<void> fetchAllProductsForCategory(
    String categoryId, {
    String? categoryNameForLog,
    String? sortBy,
    String? brandId, // API key is 'brand'
    double? minPrice,
    double? maxPrice,
    String? firstName, // e.g., 'parentCategory'
    String? firstValue,  // e.g., ID of parentCategory
    String? secondName, // e.g., 'subcategory'
    String? secondValue, // e.g., ID of subCategory
  }) async {
    final String logName = categoryNameForLog ?? categoryId;
    final String effectiveCategoryId = secondValue != null && secondValue.isNotEmpty ? secondValue : (firstValue != null && firstValue.isNotEmpty ? firstValue : categoryId);
    final String effectiveParentType = secondName != null && secondName.isNotEmpty ? secondName : (firstName != null && firstName.isNotEmpty ? firstName : "parentCategory");


    isLoadingAllProductsByCategoryMap.putIfAbsent(effectiveCategoryId, () => false.obs);
    isLoadingAllProductsByCategoryMap[effectiveCategoryId]!.value = true;
    allProductsByCategoryMap.putIfAbsent(effectiveCategoryId, () => <dynamic>[].obs);
    allProductsByCategoryMap[effectiveCategoryId]!.clear();

    log('Fetching all products for $effectiveParentType: $effectiveCategoryId (Original request ID: $categoryId, LogName: $logName)');

    try {
      Uri baseUri = Uri.parse(Configss.product);
      Map<String, String> queryParams = {
      };

      if (firstName != null && firstValue != null && firstName.isNotEmpty && firstValue.isNotEmpty) {
        queryParams[firstName] = firstValue;
      }

// Add subcategory if exists
      if (secondName != null && secondValue != null && secondName.isNotEmpty && secondValue.isNotEmpty) {
        queryParams[secondName] = secondValue;
      }


      
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }
      if (brandId != null && brandId.isNotEmpty && brandId.toLowerCase() != "all") {
        queryParams['brand'] = brandId; 
      }
      if (minPrice != null) {
        queryParams['minPrice'] = minPrice.toStringAsFixed(0);
      }
      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice.toStringAsFixed(0);
      }

      if (effectiveParentType == secondName && firstName != null && firstValue != null && firstName.isNotEmpty && firstValue.isNotEmpty) {
           log("Note: secondName/secondValue used as primary filter. firstName/firstValue ('$firstName':'$firstValue') were present but not added as secondary query param in this logic. Adjust if API supports.");
      }

      final finalUri = baseUri.replace(queryParameters: queryParams);
      log('Fetching all products URL: $finalUri');

      var response = await http.get(finalUri);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] is List) {
          allProductsByCategoryMap[effectiveCategoryId]!.assignAll(responseData['data']);
          log('Successfully fetched ${allProductsByCategoryMap[effectiveCategoryId]!.length} products for $logName.');
        } else {
          allProductsByCategoryMap[effectiveCategoryId]!.clear();
          log('Failed to fetch or parse all products for $logName. Success: ${responseData['success']}, Data type: ${responseData['data']?.runtimeType}');
        }
      } else {
        allProductsByCategoryMap[effectiveCategoryId]!.clear();
        log('HTTP Error ${response.statusCode} fetching all products for $logName: ${response.body}');
      }
    } catch (e) {
      log('Exception fetching all products for $logName: $e');
      allProductsByCategoryMap[effectiveCategoryId]?.clear(); 
    } finally {
      isLoadingAllProductsByCategoryMap[effectiveCategoryId]!(false);
    }
  }
  // --- End New Method ---

  final limit = 13.obs; // This limit is for paginationProducts, not directly for fetchProductsForCategory
  final isdataloaded = 0.obs;
  final paginationProducts = [].obs;
  bool isFetchingMore = false;
  final fetchedIds = <String>{}.obs;
  int currentPage = 1;

  // --- START: Method to Fetch Featured Products ---
  Future<void> fetchFeaturedProducts({int fetchLimit = 20}) async {
    try {
      isLoadingFeaturedProducts.value = true;
      // featuredProducts.clear(); // Clear previous results - We will assign a new list instead

      String url = "${Configss.searchAll}?featured=true&limit=$fetchLimit";
      log('[fetchFeaturedProducts] Fetching with limit $fetchLimit: $url');

      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] is List) {
          List<dynamic> fetchedData = responseData['data'];
          
          // --- De-duplication logic START ---
          final uniqueProducts = <dynamic>[];
          final seenIds = <String>{}; // Set to keep track of product IDs already added

          for (var productData in fetchedData) {
            if (productData is Map<String, dynamic> && productData.containsKey('_id')) {
              String productId = productData['_id'].toString();
              if (!seenIds.contains(productId)) {
                uniqueProducts.add(productData);
                seenIds.add(productId);
              } else {
                log('[fetchFeaturedProducts] Duplicate product ID found and skipped: $productId');
              }
            } else {
              // If the item doesn't have an ID or isn't a map, add it anyway or log an error
              uniqueProducts.add(productData); 
              log('[fetchFeaturedProducts] Warning: Product data without _id or not a Map: $productData');
            }
          }
          featuredProducts.assignAll(uniqueProducts);
          // --- De-duplication logic END ---
          
          log('[fetchFeaturedProducts] Successfully fetched and de-duplicated ${featuredProducts.length} featured products.');
        } else {
          featuredProducts.clear(); // Clear if API call wasn't successful in structure
          log('[fetchFeaturedProducts] API call successful but data format incorrect or success false. Response: ${response.body}');
        }
      } else {
        featuredProducts.clear(); // Clear on HTTP error
        log('[fetchFeaturedProducts] HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      featuredProducts.clear(); // Clear on exception
      log('[fetchFeaturedProducts] Exception: $e');
    } finally {
      isLoadingFeaturedProducts.value = false;
    }
  }



  Future<void> getProductsPaggination({
    String? cateId,
    String? parentType,
    String? sortby,
    String? brandName,
    String? brandId,
    String? firstName,
    String? firstValue,
    String? secondName,
    String? secondValue,
    double? minPrice,
    double? maxPrice,
    bool isNewRequest = false,
  }) async {
    bool parametersChanged = _currentPagingCateId != cateId ||
        _currentPagingParentType != parentType ||
        _currentPagingSortby != sortby ||
        _currentPagingBrandName != brandName ||
        _currentPagingBrandId != brandId ||
        _currentPagingFirstName != firstName ||
        _currentPagingFirstValue != firstValue ||
        _currentPagingSecondName != secondName ||
        _currentPagingSecondValue != secondValue ||
        _currentPagingMinPrice != minPrice ||
        _currentPagingMaxPrice != maxPrice;

    if (isNewRequest || parametersChanged) {
      log('🔁 New pagination context. Resetting state. isNewRequest: $isNewRequest, paramsChanged: $parametersChanged');
      paginationProducts.clear();
      fetchedIds.clear();
      currentPage = 1;
      isMoreDataAvailableForShop.value = true;

      _currentPagingCateId = cateId;
      _currentPagingParentType = parentType;
      _currentPagingSortby = sortby;
      _currentPagingBrandName = brandName; 
      _currentPagingBrandId = brandId;     
      _currentPagingFirstName = firstName; 
      _currentPagingFirstValue = firstValue; 
      _currentPagingSecondName = secondName; 
      _currentPagingSecondValue = secondValue; 
      _currentPagingMinPrice = minPrice;
      _currentPagingMaxPrice = maxPrice;

      isdataloaded.value = 1; 
    } else {
      if (!isMoreDataAvailableForShop.value || isFetchingMore) {
        log("Load more skipped: More data unavailable or already fetching.");
        return;
      }
      isdataloaded.value = 2; 
    }

    isFetchingMore = true;

    Uri baseUri = Uri.parse(Configss.searchAll);
    Map<String, String?> queryParams = {
      'page': currentPage.toString(),
      'limit': limit.value.toString(), // Uses the class-level limit for pagination
    };

    if (_currentPagingSecondName != null && _currentPagingSecondValue != null && _currentPagingSecondName!.isNotEmpty && _currentPagingSecondValue!.isNotEmpty) {
        queryParams[_currentPagingSecondName!] = _currentPagingSecondValue;
        if (_currentPagingFirstName != null && _currentPagingFirstValue != null && _currentPagingFirstName!.isNotEmpty && _currentPagingFirstValue!.isNotEmpty) {
            log("Pagination: Subcategory specified. Parent category ('${_currentPagingFirstName!}:${_currentPagingFirstValue!}') also available but not added as secondary query param.");
        }
    } else if (_currentPagingFirstName != null && _currentPagingFirstValue != null && _currentPagingFirstName!.isNotEmpty && _currentPagingFirstValue!.isNotEmpty) {
        queryParams[_currentPagingFirstName!] = _currentPagingFirstValue;
    } else if (_currentPagingParentType != null && _currentPagingCateId != null && _currentPagingParentType!.isNotEmpty && _currentPagingCateId!.isNotEmpty) {
        queryParams[_currentPagingParentType!] = _currentPagingCateId;
    }

    if (_currentPagingSortby != null && _currentPagingSortby!.isNotEmpty) {
      queryParams['sortBy'] = _currentPagingSortby;
    }
    if (_currentPagingBrandName != null && _currentPagingBrandId != null && _currentPagingBrandName!.isNotEmpty && _currentPagingBrandId!.isNotEmpty && _currentPagingBrandId!.toLowerCase() != "all") {
      queryParams[_currentPagingBrandName!] = _currentPagingBrandId;
    }
    
    if (_currentPagingMinPrice != null) {
      queryParams['minPrice'] = _currentPagingMinPrice!.toStringAsFixed(0);
    }
    if (_currentPagingMaxPrice != null) {
      queryParams['maxPrice'] = _currentPagingMaxPrice!.toStringAsFixed(0);
    }
    
    queryParams.removeWhere((key, value) => value == null || value.isEmpty);
    final finalUri = baseUri.replace(queryParameters: queryParams.cast<String, String>());

    log('Pagination API call: ${finalUri}');

    try {
      final response = await http.get(finalUri);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse is Map && jsonResponse['success'] == true && jsonResponse['data'] is List) {
          List<dynamic> fetchedData = jsonResponse['data'];
          final List<dynamic> productsToAdd = [];
          for (var product in fetchedData) {
            final dynamic rawId = product['_id'];
            if (rawId == null) {
              log('Warning: Product with null ID. Skipping.');
              continue;
            }
            final String id = rawId.toString();
            if (!fetchedIds.contains(id)) {
              productsToAdd.add(product);
            } 
          }

          if (productsToAdd.isNotEmpty) {
            paginationProducts.addAll(productsToAdd);
            for (var product in productsToAdd) {
                 fetchedIds.add(product['_id'].toString());
            }
            currentPage++;
          }

          if (fetchedData.isEmpty || fetchedData.length < limit.value) {
            isMoreDataAvailableForShop.value = false;
          }
        } else {
          isMoreDataAvailableForShop.value = false;
          log('API response success was not true or data was not a list.');
        }
      } else {
        isMoreDataAvailableForShop.value = false;
        log('API error: ${response.statusCode}');
      }
    } catch (e) {
      log('🚨 Pagination error: $e');
      isMoreDataAvailableForShop.value = false;
    } finally {
      isFetchingMore = false;
      isdataloaded.value = 0;
      update();
    }
  }

  final relatedProducts = [].obs;
  final isrelatedLoading = false.obs;
  getRelatedProducts(String cateId) async {
    if (cateId.isEmpty) return;
    isrelatedLoading.value = true;
    try {
      String url = "${Configss.searchAll}?parentCategory=${cateId}&limit=10";
      var response = await http.get(Uri.parse(url));
      isrelatedLoading.value = false;
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] is List) {
          relatedProducts.assignAll(responseData['data']);
        } else {
          relatedProducts.clear();
        }
      } else {
        relatedProducts.clear();
      }
    } catch (e) {
      isrelatedLoading.value = false;
      relatedProducts.clear();
      print("⚠️ Exception in getRelatedProducts: $e");
    }
  }

  @override
  void onInit() {
    super.onInit();
    getCategory();
    getSubcategory();
  }
}
