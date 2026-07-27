import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../Api/Models/category_slider_item.dart';
import '../Api/Models/categorymodel.dart';
import '../Configs/config.dart';

class HomeSliderController extends GetxController {
  final isCateloading = false.obs;
  final sliderItems = <CategorySliderItem>[].obs;
  final category = <categoriesModel>[].obs;
  final filterCategory = <categoriesModel>[].obs;
  final selectedCategoryId = ''.obs;
  final firstCategoryName = ''.obs;
  final secondCategoryName = ''.obs;
  final firstId = ''.obs;
  final secondId = ''.obs;

  /// Parallel Fetching: App load hotey hi dono endpoints call karen:
  /// 1. GET /api/custom-slider-items/active
  /// 2. GET /api/categories/slider
  /// Merge & Order:
  /// Pehle Custom Items rakhen (type: 'custom'), Uske baad Categories (type: 'category')
  Future<List<CategorySliderItem>> homeCategorySlider() async {
    isCateloading.value = true;
    update();

    try {
      final responses = await Future.wait([
        http.get(Uri.parse(Configss.newHomeCategory)),
        http.get(Uri.parse(Configss.sliderCategories)),
      ]).timeout(const Duration(seconds: 15));

      final customResponse = responses[0];
      final categoryResponse = responses[1];

      List<CategorySliderItem> customItems = [];
      List<CategorySliderItem> categoryItems = [];

      // 1. Parse Custom Items (type: 'custom')
      if (customResponse.statusCode == 200) {
        final List<dynamic> customData = jsonDecode(customResponse.body);
        customItems = customData
            .where((json) =>
                json != null &&
                json is Map<String, dynamic> &&
                json['isActive'] != false &&
                json['isDeleted'] != true &&
                json['status'] != 'inactive')
            .map((json) =>
                CategorySliderItem.fromCustomJson(json as Map<String, dynamic>))
            .toList();
      } else {
        if (kDebugMode) {
          print(
              'Failed to fetch custom slider items: ${customResponse.statusCode}');
        }
      }

      // 2. Parse Category Items (type: 'category')
      if (categoryResponse.statusCode == 200) {
        final List<dynamic> categoryData = jsonDecode(categoryResponse.body);
        categoryItems = categoryData
            .where((json) =>
                json != null &&
                json is Map<String, dynamic> &&
                json['isActive'] != false &&
                json['isDeleted'] != true &&
                json['status'] != 'inactive' &&
                json['showInSlider'] != false)
            .map((json) => CategorySliderItem.fromCategoryJson(
                json as Map<String, dynamic>))
            .toList();
      } else {
        if (kDebugMode) {
          print(
              'Failed to fetch category slider: ${categoryResponse.statusCode}');
        }
      }

      // 3. Merge & Order: Custom items first, then Category items
      sliderItems.clear();
      sliderItems.addAll(customItems);
      sliderItems.addAll(categoryItems);

      // Legacy fallback mapping to maintain compatibility with legacy components
      category.clear();
      filterCategory.clear();
      for (var item in sliderItems) {
        final model = categoriesModel(
          sId: item.id,
          name: item.name,
          slug: item.slug,
          image: item.image,
        );
        category.add(model);
        filterCategory.add(model);
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
          if (category.length > 6) {
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
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in homeCategorySlider parallel fetch: $e');
      }
    } finally {
      isCateloading.value = false;
      update();
    }

    return sliderItems;
  }
}
