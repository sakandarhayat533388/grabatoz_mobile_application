import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../Api/Models/categorymodel.dart';
import '../Configs/config.dart';

class HomeSliderController extends GetxController {
  final isCateloading = false.obs;
  final category = <categoriesModel>[].obs;
  final filterCategory = <categoriesModel>[].obs;
  final selectedCategoryId = ''.obs;
  final firstCategoryName = ''.obs;
  final secondCategoryName = ''.obs;
  final firstId = ''.obs;
  final secondId = ''.obs;


  Future<List<categoriesModel>> homeCategorySlider() async {
    isCateloading.value = true;
    String url = "${Configss.newHomeCategory}";
    var response = await http.get(Uri.parse(url));
    isCateloading.value = false;
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      category.clear();
      filterCategory.clear();
      for (Map<String, dynamic> i in data) {
        category.add(categoriesModel.fromJson(i));
        filterCategory.add(categoriesModel.fromJson(i));
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
        // getHomeCategoryProducts();
        // getsecondHomeCategoryProducts();
      }
      update();
      return category;
    } else {
      print('Failed to fetch categories: ${response.body}');
      return category;
    }
  }
}