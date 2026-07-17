import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'orderController.dart';

class ProductCardDeal {
  final bool showBadge;
  final bool showPriceCut;
  final double? originalPrice;
  final double? discountedPrice;

  const ProductCardDeal({
    required this.showBadge,
    required this.showPriceCut,
    this.originalPrice,
    this.discountedPrice,
  });

  static const none = ProductCardDeal(showBadge: false, showPriceCut: false);
}

class FirstUserDiscountController extends GetxController {
  static const double guestCardDiscountPercent = 10.0;

  final isStatusLoading = false.obs;
  final isPreviewLoading = false.obs;
  final hasAuthSession = false.obs;
  final eligible = false.obs;
  final reason = ''.obs;
  final hasAnyOrder = false.obs;
  final discount = Rxn<Map<String, dynamic>>();
  final previewApplied = false.obs;
  final previewDiscountAmount = 0.0.obs;
  final previewEligibleSubtotal = 0.0.obs;
  final previewDiscount = Rxn<Map<String, dynamic>>();
  // Track whether loadStatus() has been called and returned at least once
  final statusChecked = false.obs;

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('Guest') == true) return null;
    return prefs.getString('token');
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  void clearPreview() {
    previewApplied.value = false;
    previewDiscountAmount.value = 0.0;
    previewEligibleSubtotal.value = 0.0;
    previewDiscount.value = null;
  }

  void clearAll() {
    hasAuthSession.value = false;
    eligible.value = false;
    reason.value = '';
    hasAnyOrder.value = false;
    discount.value = null;
    statusChecked.value = false; // Reset so next login re-checks from API
    clearPreview();
  }

  void markAuthSessionPresent() {
    hasAuthSession.value = true;
    // Immediately check orders from OrderController (no API wait needed)
    _checkOrdersFromController();
  }

  /// Check directly from OrderController if user has any orders.
  /// This is instant (no network) and runs as soon as auth session is known.
  void _checkOrdersFromController() {
    try {
      if (Get.isRegistered<OrderController>()) {
        final orderCtrl = Get.find<OrderController>();
        final totalOrders = orderCtrl.activeOrders.length +
            orderCtrl.completedOrders.length +
            orderCtrl.cancelledOrders.length;
        if (totalOrders > 0) {
          hasAnyOrder.value = true;
          log('🔍 [Badge] Orders found from OrderController ($totalOrders) → badge hidden');
        }
      }
    } catch (e) {
      log('🔍 [Badge] _checkOrdersFromController error: $e');
    }
  }

  Future<void> loadStatus() async {
    isStatusLoading.value = true;
    final authToken = await _token();
    log('🔍 [Badge] loadStatus() called. Token: ${authToken != null && authToken.isNotEmpty ? "FOUND (${authToken.substring(0, 10)}...)" : "NULL/EMPTY"}');
    if (authToken == null || authToken.isEmpty) {
      clearAll();
      isStatusLoading.value = false;
      log('🔍 [Badge] No token → clearAll, badge = GUEST mode');
      return;
    }
    hasAuthSession.value = true;

    try {
      final response = await http.get(
        Uri.parse(Configss.firstUserDiscountStatus),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      log('🔍 [Badge] API status: ${response.statusCode}');
      log('🔍 [Badge] API body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          eligible.value = data['eligible'] == true;
          reason.value = data['reason']?.toString() ?? '';
          hasAnyOrder.value = data['hasAnyOrder'] == true;
          final rawDiscount = data['discount'];
          discount.value = rawDiscount is Map
              ? Map<String, dynamic>.from(rawDiscount)
              : null;
          if (!eligible.value) clearPreview();
          log('🔍 [Badge] eligible=${eligible.value}, hasAnyOrder=${hasAnyOrder.value}, reason="${reason.value}"');
          log('🔍 [Badge] → Badge should show: ${!hasAnyOrder.value}');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        clearAll();
        log('🔍 [Badge] 401/403 → clearAll');
      } else {
        log('First user discount status failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      log('First user discount status error: $e');
    } finally {
      isStatusLoading.value = false;
      statusChecked.value =
          true; // Mark that we've completed at least one check
      log('🔍 [Badge] Final state → hasAuthSession=${hasAuthSession.value}, hasAnyOrder=${hasAnyOrder.value}, statusChecked=${statusChecked.value}');
    }
  }

  Future<void> previewCart(List<dynamic> cartItems) async {
    final authToken = await _token();
    if (authToken == null ||
        authToken.isEmpty ||
        !eligible.value ||
        cartItems.isEmpty) {
      clearPreview();
      return;
    }

    final cpList = cartItems
        .where((item) =>
            (item.productId ?? '').isNotEmpty &&
            (item.quantity ?? 0) > 0)
        .map((item) => {
              'product': item.productId,
              'qty': item.quantity ?? 1,
            })
        .toList();

    if (cpList.isEmpty) {
      clearPreview();
      return;
    }

    isPreviewLoading.value = true;
    try {
      final couponName = discount.value?['name'] ?? '';
      if (couponName.isEmpty) {
        clearPreview();
        return;
      }

      final response = await http.post(
        Uri.parse(Configss.applyCoupon),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'code': couponName,
          'orderSource': 'app',
          'cartItems': cpList,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          previewApplied.value = data['valid'] == true;
          previewDiscountAmount.value = _toDouble(data['discountAmount']);
          previewEligibleSubtotal.value = _toDouble(data['totalEligibleAmount']);
          final rawDiscount = data['coupon'];
          previewDiscount.value = rawDiscount is Map
              ? Map<String, dynamic>.from(rawDiscount)
              : null;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        clearAll();
      } else {
        clearPreview();
        log('First user discount preview failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      clearPreview();
      log('First user discount preview error: $e');
    } finally {
      isPreviewLoading.value = false;
    }
  }

  Future<void> refreshAfterOrder() async {
    await loadStatus();
  }

  ProductCardDeal getProductCardDeal(
    dynamic product,
  ) {
    // While API is still loading AND user is logged in → hide badge to avoid flicker
    if (isStatusLoading.value && hasAuthSession.value) {
      return ProductCardDeal.none;
    }

    // API check not done yet for a logged-in session → hide badge (wait for result)
    if (hasAuthSession.value && !statusChecked.value) {
      return ProductCardDeal.none;
    }

    // Logged-in user who has already placed an order → hide badge completely
    if (hasAuthSession.value && hasAnyOrder.value) {
      return ProductCardDeal.none;
    }

    // Guest (no auth session) → always show badge, no price cut
    if (!hasAuthSession.value) {
      return const ProductCardDeal(showBadge: true, showPriceCut: false);
    }

    // Logged-in user not eligible or missing discount info → hide badge
    if (!eligible.value || discount.value == null || product is! Map) {
      return ProductCardDeal.none;
    }

    final currentDiscount = discount.value!;
    final productId = (product['_id'] ?? product['id'] ?? '').toString();
    if (productId.isEmpty) return ProductCardDeal.none;

    final appliesTo = currentDiscount['appliesTo']?.toString();
    var matchesScope = appliesTo == 'all';

    if (!matchesScope && appliesTo == 'products') {
      final products = currentDiscount['products'];
      if (products is List) {
        matchesScope = products.any((entry) {
          if (entry is Map) {
            return (entry['_id'] ?? entry['id'] ?? entry['product'] ?? '')
                    .toString() ==
                productId;
          }
          return entry.toString() == productId;
        });
      }
    }

    if (!matchesScope) return ProductCardDeal.none;

    final offerPrice = _toDouble(product['offerPrice']);
    final regularPrice = _toDouble(product['price']);
    final basePrice = offerPrice > 0 ? offerPrice : regularPrice;
    if (basePrice <= 0) {
      return const ProductCardDeal(showBadge: true, showPriceCut: false);
    }

    final minOrderAmount = _toDouble(currentDiscount['minOrderAmount']);
    if (minOrderAmount > basePrice) {
      return const ProductCardDeal(showBadge: true, showPriceCut: false);
    }

    String? discountType = currentDiscount['discountType']?.toString();
    double discountValue = _toDouble(currentDiscount['discountValue']);

    final rules = currentDiscount['rules'];
    if (rules is List && rules.isNotEmpty) {
      final matchingRule = rules.firstWhere(
        (r) {
          final minAmt = _toDouble(r['minCartAmount']);
          final maxAmt = _toDouble(r['maxCartAmount']);
          return basePrice >= minAmt && (maxAmt <= 0 || basePrice <= maxAmt);
        },
        orElse: () => rules.first,
      );
      if (matchingRule != null) {
        discountType = matchingRule['discountType']?.toString();
        discountValue = _toDouble(matchingRule['discountValue']);
      }
    }

    var rawDiscount = 0.0;
    if (discountType == 'percentage') {
      rawDiscount = basePrice * (discountValue / 100);
    } else if (discountType == 'fixed') {
      rawDiscount = discountValue;
    }

    final maxDiscountAmount = _toDouble(currentDiscount['maxDiscountAmount']);
    final effectiveDiscount = (maxDiscountAmount > 0
            ? rawDiscount.clamp(0.0, maxDiscountAmount)
            : rawDiscount.clamp(0.0, double.infinity))
        .toDouble();
    final discountedPrice =
        (basePrice - effectiveDiscount).clamp(0.0, basePrice).toDouble();

    return ProductCardDeal(
      showBadge: true,
      showPriceCut: discountedPrice < basePrice,
      originalPrice: regularPrice > 0 ? regularPrice : basePrice,
      discountedPrice: discountedPrice,
    );
  }
}
