// ignore_for_file: use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Api/Models/popup_settings_model.dart';
import '../../Utils/packages.dart';

class ApiServiceController extends GetxController {
  final isLoading = false.obs;

  // ================================Logout Api Function=====================================================================================

  // }
  Future<void> logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all stored user data

      // Optionally, remove specific keys:
      // await prefs.remove('user_id');
      // await prefs.remove('auth_token');

      // Navigate to the Login screen
      final navigationProvider = Get.put(BottomNavigationController());

      navigationProvider.setTabIndex(0); // Reset to the default tab index
      print('Logged out successfully');

      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (context) => const Log()),
      //   (Route<dynamic> route) => false, // Remove all previous routes
      // );
    } catch (e) {
      print('Error logging out: $e');
      // Optionally, show a snackbar or dialog to inform the user of the error
    }
  }

  // ================================shipping Function=====================================================================================

  // Future<RetrieveCustomer> getCustomerDetails() async {
  //   final prefs = await SharedPreferences.getInstance();

  //   String? userId = prefs.getString('userId')?.toString();
  //   // print(userId);

  //   // debugPrint("Retrieved Customer ID from SharedPreferences: $userId");

  //   if (userId == null) {
  //     throw Exception("Customer ID not found or invalid in SharedPreferences");
  //   }

  //   String url = '';

  //   var dio = Dio();

  //   try {
  //     var response = await dio.get(url);

  //     // debugPrint("Response Status Code: ${response.statusCode}");
  //     // debugPrint("Response Body: ${response.data}");

  //     if (response.statusCode == 200) {
  //       return RetrieveCustomer.fromJson(response.data);
  //     } else {
  //       throw Exception(
  //           "Error fetching customer details: ${response.statusMessage}");
  //     }
  //   } on DioException catch (e) {
  //     debugPrint("Dio Error: $e");
  //     throw Exception(e.response?.data['message'] ??
  //         "Network error: Unable to connect to server.");
  //   } catch (e) {
  //     debugPrint("Unexpected Error: $e");
  //     throw Exception("An unexpected error occurred: $e");
  //   }
  // }

  // ================================Product Api Function=====================================================================================

  List _products = [];

  List get products => _products;

  Future<Map<String, dynamic>> fetchProductById(String productId) async {
    // TODO: Adjust endpoint to your backend
    final uri = Uri.parse('${Configss.baseUrl}/api/products/$productId');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch product ($productId): ${res.statusCode}');
    }
    final body = json.decode(res.body);
    // Handle common API response wrappers
    final product = (body is Map && body.containsKey('data'))
        ? body['data']
        : (body is Map && body.containsKey('product'))
            ? body['product']
            : body;
    if (product is! Map<String, dynamic>) {
      throw Exception('Unexpected product payload shape');
    }
    return product;
  }

  Future<String> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(Configss.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email.trim().toLowerCase()}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'] ?? 'If this email is registered, a reset link has been sent.';
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to send reset email');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<PopupSettingsModel?> fetchActivePopup({String pageKey = 'home'}) async {
    try {
      final uri = Uri.parse('${Configss.getPopupSettings}?platform=app&pageKey=$pageKey');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body == null) {
          return null;
        }
        if (body is Map<String, dynamic>) {
          return PopupSettingsModel.fromJson(body);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching active popup settings: $e');
      return null;
    }
  }
}
