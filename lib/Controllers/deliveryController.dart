import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:graba2z/Configs/config.dart';

class DeliveryMethod {
  final String id;
  final String name;
  final String description;
  final double charge;
  final double? minOrderAmount;
  final double? maxOrderAmount;
  final bool isActive;
  final List<String> applicableAreas;
  final String deliveryTime;

  DeliveryMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.charge,
    this.minOrderAmount,
    this.maxOrderAmount,
    required this.isActive,
    required this.applicableAreas,
    required this.deliveryTime,
  });

  factory DeliveryMethod.fromJson(Map<String, dynamic> json) {
    return DeliveryMethod(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      charge: (json['charge'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble(),
      maxOrderAmount: (json['maxOrderAmount'] as num?)?.toDouble(),
      isActive: json['isActive'] ?? true,
      applicableAreas: (json['applicableAreas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      deliveryTime: json['deliveryTime']?.toString() ?? '',
    );
  }
}

class DeliveryController extends GetxController {
  final methods = <DeliveryMethod>[].obs;
  final selectedId = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMethods();
  }

  /// Whether active delivery charges are configured from backend.
  /// If false, admin turned off all delivery charges or returned empty [].
  bool get hasActiveDeliveryCharges =>
      methods.isNotEmpty && methods.any((m) => m.isActive);

  /// Returns the active selected method, or first active method as fallback.
  DeliveryMethod? get selectedMethod {
    if (methods.isEmpty) return null;
    final activeList = methods.where((m) => m.isActive).toList();
    if (activeList.isEmpty) return null;

    if (selectedId.value.isNotEmpty) {
      try {
        return activeList.firstWhere((m) => m.id == selectedId.value);
      } catch (_) {}
    }
    return activeList.first;
  }

  double get selectedCharge => selectedMethod?.charge ?? 0.0;

  /// Calculates shipping fee based on subtotal & rules from backend.
  /// Returns `null` if delivery charges are turned off by admin.
  /// Returns `0.0` if free shipping threshold is met (minOrderAmount > 0 && subtotal >= minOrderAmount).
  /// Returns `charge` otherwise.
  double? calculateShippingFee(double subtotal) {
    if (!hasActiveDeliveryCharges) return null;
    final method = selectedMethod;
    if (method == null) return null;

    final minAmt = method.minOrderAmount;
    if (minAmt != null && minAmt > 0 && subtotal >= minAmt) {
      return 0.0;
    }

    return method.charge;
  }

  /// Whether free shipping threshold is met for the given subtotal.
  bool isFreeShippingApplied(double subtotal) {
    if (!hasActiveDeliveryCharges) return false;
    final fee = calculateShippingFee(subtotal);
    return fee != null && fee == 0.0;
  }

  Future<void> fetchMethods() async {
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse(Configss.getShippingCharge));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          methods.value = decoded
              .map((e) => DeliveryMethod.fromJson(e as Map<String, dynamic>))
              .where((m) => m.isActive)
              .toList();
          if (methods.isNotEmpty) {
            if (selectedId.value.isEmpty ||
                !methods.any((m) => m.id == selectedId.value)) {
              selectedId.value = methods.first.id;
            }
          } else {
            selectedId.value = '';
          }
        } else {
          methods.clear();
          selectedId.value = '';
        }
      } else {
        methods.clear();
        selectedId.value = '';
      }
    } catch (e) {
      if (kDebugMode) print('DeliveryController.fetchMethods error: $e');
      methods.clear();
      selectedId.value = '';
    } finally {
      isLoading.value = false;
    }
  }

  void select(String id) {
    selectedId.value = id;
  }
}
