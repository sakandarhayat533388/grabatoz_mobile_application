import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:graba2z/Configs/config.dart';

class PaymentChargeLine {
  final String name;
  final double amount;

  PaymentChargeLine({
    required this.name,
    required this.amount,
  });

  factory PaymentChargeLine.fromJson(Map<String, dynamic> json) {
    return PaymentChargeLine(
      name: json['name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ??
          double.tryParse(json['amount']?.toString() ?? '') ??
          0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
    };
  }
}

class PaymentMethodCharge {
  final String id;
  final String paymentMethod;
  final String description;
  final List<PaymentChargeLine> charges;
  final bool isActive;

  PaymentMethodCharge({
    required this.id,
    required this.paymentMethod,
    required this.description,
    required this.charges,
    required this.isActive,
  });

  factory PaymentMethodCharge.fromJson(Map<String, dynamic> json) {
    final rawCharges = json['charges'];
    return PaymentMethodCharge(
      id: json['_id']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString().toLowerCase() ?? '',
      description: json['description']?.toString() ?? '',
      charges: rawCharges is List
          ? rawCharges
              .whereType<Map>()
              .map((charge) =>
                  PaymentChargeLine.fromJson(Map<String, dynamic>.from(charge)))
              .toList()
          : <PaymentChargeLine>[],
      isActive: json['isActive'] == true,
    );
  }

  double get total {
    return charges.fold(0.0, (sum, charge) => sum + charge.amount);
  }
}

class PaymentChargesController extends GetxController {
  final activeCharges = <PaymentMethodCharge>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchActiveCharges();
  }

  Future<void> fetchActiveCharges() async {
    isLoading.value = true;
    try {
      final response =
          await http.get(Uri.parse(Configss.getActivePaymentCharges));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded is List
            ? decoded
            : decoded is Map && decoded['data'] is List
                ? decoded['data'] as List
                : decoded is Map && decoded['paymentCharges'] is List
                    ? decoded['paymentCharges'] as List
                    : <dynamic>[];

        activeCharges.value = list
            .whereType<Map>()
            .map((item) =>
                PaymentMethodCharge.fromJson(Map<String, dynamic>.from(item)))
            .where((charge) => charge.isActive)
            .toList();
      }
    } catch (e) {
      print('PaymentChargesController.fetchActiveCharges error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  PaymentMethodCharge? chargeFor(String paymentMethod) {
    final normalized = paymentMethod.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    try {
      return activeCharges.firstWhere(
        (charge) => charge.paymentMethod == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  List<PaymentChargeLine> linesFor(String paymentMethod) {
    return chargeFor(paymentMethod)?.charges ?? <PaymentChargeLine>[];
  }

  double totalFor(String paymentMethod) {
    return chargeFor(paymentMethod)?.total ?? 0.0;
  }

  double amountMatching(String paymentMethod, List<String> keywords) {
    final normalizedKeywords =
        keywords.map((keyword) => keyword.toLowerCase()).toList();
    return linesFor(paymentMethod).fold(0.0, (sum, charge) {
      final name = charge.name.toLowerCase();
      final matches =
          normalizedKeywords.any((keyword) => name.contains(keyword));
      return matches ? sum + charge.amount : sum;
    });
  }
}
