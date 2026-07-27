import 'dart:convert';
import 'dart:developer';
import 'package:graba2z/Configs/config.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class SearchScController extends GetxController {
  final searchQuery = ''.obs;
  final dmy = ''.obs;
  final itemCountsd = 8.obs;
  // String get searchQuery => _searchQuery;
  final List<String> _stockStatus = ["All", "In Stock", "Out of Stock"];
  List<String> get stockStatus => _stockStatus;
  // Store categories and brands locally
  // List<String> _categories = [];
  // List<String> get categories => _categories;

  final searhProducts = [].obs;
  List<String> _brands = [];
  List<String> get brands => _brands;

  void setSearchQuery(String query) {
    searchQuery.value = query;
    update();
  }

  void clearSearchQuery() {
    searchQuery.value = '';
    hasFilterApplied.value = false;
    update();
  }

  RxBool hasFilterApplied = false.obs;

  bool isFetchingMore = false;
  final isrequesting = 0.obs;
  final isMoreDataAvailableForShop = true.obs;
  final limit = 13.obs;
  final fetchedIds = <String>{}.obs;
  // ========================= Fetch All ADS by Search with Filters ==============================
  fetchAdsbysearchWithFilters(
      String sortby,
      String brandName,
      String brandId,
      String firstName,
      String firstValue,
      String secondName,
      String secondValue,
      double minPrice,
      double maxPrice,
      ) async {
    // ✅ Debugging print statements
    isrequesting.value = 1;
    isFetchingMore = true;
    if (searhProducts.isNotEmpty) {
      isrequesting.value = 2;
    } else {
      isrequesting.value = 1;
    }
    var apiUrl = Configss.searchAll;

    // Build query params safely
    final Map<String, String> params = {};
    if (sortby.isNotEmpty) params['sortBy'] = sortby;
    if (brandName.isNotEmpty && brandId.isNotEmpty) {
      if (brandName == 'parentCategory' || brandName == 'category') {
        params['category'] = brandId;
        params['parentCategory'] = brandId;
      } else {
        params[brandName] = brandId;
      }
    }
    if (firstName.isNotEmpty && firstValue.isNotEmpty) params[firstName] = firstValue;
    if (secondName.isNotEmpty && secondValue.isNotEmpty) params[secondName] = secondValue;
    if (minPrice > 0) params['minPrice'] = minPrice.toStringAsFixed(0);
    if (maxPrice > 0) params['maxPrice'] = maxPrice.toStringAsFixed(0);
    params['limit'] = limit.value.toString();
    final uri = Uri.parse(apiUrl).replace(queryParameters: params);
    log("the url of search is data $uri");

    print("$uri");

    var response = await http.get(uri);

    // ✅ Check API response
    isrequesting.value = 0;


    // print("🔍 API Response Body: ${response.body}");
    if (response.statusCode == 200) {
      // print("the url of search is : ${uri}");
      final jsonResponse = jsonDecode(response.body);
      // final data = jsonResponse;
      final data = jsonResponse['data'];
      // var body = jsonDecode(response.body);
      // searhProducts.value = body;

      if (data is List && data.isNotEmpty) {
        // filter already-added products
        final newProducts = data.where((product) {
          final id = product['_id']; // or whatever unique ID key is
          if (fetchedIds.contains(id)) return false;
          fetchedIds.add(id);
          return true;
        }).toList();

        if (newProducts.isNotEmpty) {
          searhProducts.addAll(newProducts);

          // Only increment limit when doing paged requests (avoid bumping on full-fetch)
          if (limit.value < 1000) {
            limit.value += 13;
          }
          log('the url is and lmit ${limit.value}');
          log('the url is and lenght ${searhProducts.length}');
          print('the url is and lmit ${limit.value}');
          print('the url is and lenght ${searhProducts.length}');
        }

        // If server returned less than requested limit, no more data
        if (data.length < (int.tryParse(params['limit'] ?? '13') ?? 13)) {
          isMoreDataAvailableForShop.value = false;
        }
      } else {
        isMoreDataAvailableForShop.value = false;
      }
    } else {
      print(response.reasonPhrase);
      isMoreDataAvailableForShop.value = false;
      log('failed to load products ${response.reasonPhrase}');
      // throw Exception('Failed to load products.');
    }
  }

  List<String> _priceRanges = []; // Store dynamic price ranges here
  List<String> get priceRanges => _priceRanges;
}