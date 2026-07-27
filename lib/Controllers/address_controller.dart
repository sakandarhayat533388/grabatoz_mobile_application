import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Configs/config.dart';

String formatNormalizedPhone(String rawPhone) {
  if (rawPhone.trim().isEmpty) return '';

  String text = rawPhone.trim();
  if (text.startsWith('00')) {
    text = '+${text.substring(2)}';
  }

  final StringBuffer digitsBuf = StringBuffer();
  final bool hasPlus = text.startsWith('+');
  for (int i = 0; i < text.length; i++) {
    if (RegExp(r'\d').hasMatch(text[i])) {
      digitsBuf.write(text[i]);
    }
  }
  final String digits = digitsBuf.toString();
  if (digits.isEmpty) return rawPhone;

  String formattedFull = hasPlus ? '+$digits' : digits;
  if (!formattedFull.startsWith('+')) {
    formattedFull = '+$formattedFull';
  }

  final Map<String, String> dialCodeToCountry = {
    '+971': 'AE', '+966': 'SA', '+968': 'OM', '+974': 'QA', '+973': 'BH',
    '+965': 'KW', '+91': 'IN', '+92': 'PK', '+44': 'GB', '+1': 'US',
    '+63': 'PH', '+20': 'EG', '+962': 'JO', '+961': 'LB', '+86': 'CN',
  };

  final sortedCodes = dialCodeToCountry.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  for (String dialCode in sortedCodes) {
    if (formattedFull.startsWith(dialCode)) {
      final dialDigits = dialCode.replaceAll('+', '');
      String national = digits.substring(dialDigits.length);
      while (national.startsWith('0')) {
        national = national.substring(1);
      }
      return '$dialCode$national';
    }
  }

  String national = digits;
  while (national.startsWith('0')) {
    national = national.substring(1);
  }

  return '+971$national';
}

class AddressModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    final rawPhone = json['phone']?.toString() ?? '';
    return AddressModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: formatNormalizedPhone(rawPhone),
      email: json['email']?.toString() ?? '',
      address: (json['address'] ?? json['street'])?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'isDefault': isDefault,
    };
  }
}

class AddressController extends GetxController {
  var addresses = <AddressModel>[].obs;
  var isLoading = false.obs;
  var isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAddresses();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// GET /api/users/addresses
  Future<void> fetchAddresses() async {
    try {
      isLoading.value = true;
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        isLoading.value = false;
        return;
      }

      final response = await http.get(
        Uri.parse(Configss.userAddresses),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('📥 GET Addresses Status: ${response.statusCode}');
      log('📥 GET Addresses Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          addresses.value = decoded
              .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } else {
        print("Failed to fetch addresses: ${response.statusCode}");
      }
    } catch (e) {
      log('⚠️ Error fetching addresses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// POST /api/users/addresses
  Future<bool> addAddress(Map<String, dynamic> addressData) async {
    try {
      isSaving.value = true;
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        Get.snackbar('Error', 'User not authenticated',
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }

      final Map<String, dynamic> payload = Map<String, dynamic>.from(addressData);
      if (payload.containsKey('phone') && payload['phone'] != null) {
        payload['phone'] = formatNormalizedPhone(payload['phone'].toString());
      }

      final response = await http.post(
        Uri.parse(Configss.userAddresses),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      log('📥 POST Address Status: ${response.statusCode}');
      log('📥 POST Address Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          addresses.value = decoded
              .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          await fetchAddresses();
        }
        Get.snackbar('Success', 'Address added successfully',
            backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      } else {
        final err = json.decode(response.body);
        Get.snackbar('Error', err['message'] ?? 'Failed to add address',
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred while adding address',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// PUT /api/users/addresses/:addressId
  Future<bool> updateAddress(String addressId, Map<String, dynamic> addressData) async {
    try {
      isSaving.value = true;
      final token = await _getToken();
      if (token == null || token.isEmpty) return false;

      final Map<String, dynamic> payload = Map<String, dynamic>.from(addressData);
      if (payload.containsKey('phone') && payload['phone'] != null) {
        payload['phone'] = formatNormalizedPhone(payload['phone'].toString());
      }

      final response = await http.put(
        Uri.parse(Configss.userAddressById(addressId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      log('📥 PUT Address Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          addresses.value = decoded
              .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          await fetchAddresses();
        }
        Get.snackbar('Success', 'Address updated successfully',
            backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      } else {
        Get.snackbar('Error', 'Failed to update address',
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred while updating address',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// DELETE /api/users/addresses/:addressId
  Future<bool> deleteAddress(String addressId) async {
    try {
      isLoading.value = true;
      final token = await _getToken();
      if (token == null || token.isEmpty) return false;

      final response = await http.delete(
        Uri.parse(Configss.userAddressById(addressId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('📥 DELETE Address Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          addresses.value = decoded
              .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          await fetchAddresses();
        }
        Get.snackbar('Success', 'Address deleted successfully',
            backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      } else {
        Get.snackbar('Error', 'Failed to delete address',
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred while deleting address',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// PUT /api/users/addresses/:addressId/default
  Future<bool> setDefaultAddress(String addressId) async {
    try {
      isLoading.value = true;
      final token = await _getToken();
      if (token == null || token.isEmpty) return false;

      final response = await http.put(
        Uri.parse(Configss.userAddressDefault(addressId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('📥 DEFAULT Address Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          addresses.value = decoded
              .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          await fetchAddresses();
        }
        Get.snackbar('Success', 'Default address updated',
            backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      } else {
        Get.snackbar('Error', 'Failed to set default address',
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred while setting default address',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
