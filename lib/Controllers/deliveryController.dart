import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Utils/packages.dart';

class DeliveryMethod {
  final String id;
  final String name;
  final double charge;
  final String deliveryTime;

  DeliveryMethod({
    required this.id,
    required this.name,
    required this.charge,
    required this.deliveryTime,
  });

  factory DeliveryMethod.fromJson(Map<String, dynamic> json) {
    return DeliveryMethod(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      charge: (json['charge'] as num?)?.toDouble() ?? 0.0,
      deliveryTime: json['deliveryTime'] ?? '',
    );
  }
}

class DeliveryController extends GetxController {
  final methods = <DeliveryMethod>[].obs;
  final selectedId = ''.obs;
  final isLoading = false.obs;

  DeliveryMethod? get selectedMethod {
    if (selectedId.value.isEmpty || methods.isEmpty) return null;
    try {
      return methods.firstWhere((m) => m.id == selectedId.value);
    } catch (_) {
      return methods.isNotEmpty ? methods.first : null;
    }
  }

  double get selectedCharge => selectedMethod?.charge ?? 0.0;

  Future<void> fetchMethods() async {
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse(Configss.getShippingCharge));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        methods.value = data.map((e) => DeliveryMethod.fromJson(e)).toList();
        if (methods.isNotEmpty && selectedId.value.isEmpty) {
          selectedId.value = methods.first.id;
        }
      }
    } catch (e) {
      print('DeliveryController.fetchMethods error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void select(String id) {
    selectedId.value = id;
  }
}
