/// Routes a push notification's data payload to the right app screen.
///
/// Spec action.screen enum: home | product | category | offer | orders |
/// cart | url | none. Unknown values are treated as `none` (just open the
/// app) — the enum may gain values and the app must not crash on them.
/// Navigation is 100% GetX, matching the rest of the app.
library;

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:graba2z/Api/Services/apiservices.dart';
import 'package:graba2z/Models/notification_models.dart';
import 'package:graba2z/Views/Categories Folder/subcategories_view.dart';
import 'package:graba2z/Views/Home/Screens/Cart/cart.dart';
import 'package:graba2z/Views/Home/Screens/Deals Screen/dealsview.dart';
import 'package:graba2z/Views/Home/Screens/Settings/Modules/Order History/orderhistory.dart';
import 'package:graba2z/Views/Home/home.dart';
import 'package:graba2z/Views/Product Folder/newProductDetails.dart';

class PushDeepLink {
  PushDeepLink._();

  /// Entry point: route on the spec's action payload.
  static Future<void> handle(NotificationAction action) async {
    await handleRaw(
      screen: action.screen,
      targetId: action.targetId,
      url: action.url,
    );
  }

  /// Entry point straight from an FCM data map (all values are strings).
  static Future<void> handleData(Map<String, dynamic> data) async {
    String s(dynamic v) => v?.toString() ?? '';
    await handleRaw(
      screen: s(data['screen']),
      targetId: s(data['targetId']),
      url: s(data['url']),
    );
  }

  static Future<void> handleRaw({
    required String screen,
    required String targetId,
    required String url,
  }) async {
    switch (screen.trim().toLowerCase()) {
      case 'home':
        Get.offAll(() => const Home());
        break;
      case 'product':
        await _openProduct(targetId);
        break;
      case 'category':
        if (targetId.isNotEmpty) {
          Get.to(() => SubCategoryScreen(
                selectedCategoryId: targetId,
                title: targetId,
              ));
        } else {
          Get.offAll(() => const Home());
        }
        break;
      case 'offer':
        Get.to(() => offerDeals(
              slug: targetId.isEmpty ? null : targetId,
            ));
        break;
      case 'orders':
        // OrderDetailScreen needs the full order model, so we open the
        // order history list and let the customer pick the order.
        Get.to(() => const OrderHistoryScreen());
        break;
      case 'cart':
        Get.to(() => const Cart());
        break;
      case 'url':
        await _openUrl(url);
        break;
      case 'none':
      default:
        // Unknown screens are treated as none: just open the app.
        break;
    }
  }

  static Future<void> _openProduct(String productId) async {
    if (productId.isEmpty) return;
    EasyLoading.show(status: 'Loading...');
    try {
      final api = Get.isRegistered<ApiServiceController>()
          ? Get.find<ApiServiceController>()
          : Get.put(ApiServiceController());
      final productData = await api.fetchProductById(productId);
      EasyLoading.dismiss();
      Get.to(() => _buildProductDetails(productData));
    } catch (e) {
      EasyLoading.dismiss();
      // ignore: avoid_print
      print('PushDeepLink: failed to open product $productId: $e');
      Get.snackbar(
        'Product unavailable',
        'Could not open this product right now.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Mirrors the field mapping in NewProductCard.navigateToDetails so a
  /// push-opened product looks identical to a card-opened one.
  static Widget _buildProductDetails(Map<String, dynamic> productData) {
    List<String> images = [];
    final gallery = productData['galleryImages'];
    if (gallery is List) {
      images.addAll(gallery
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty));
    }
    final main = productData['image']?.toString() ?? '';
    if (main.isNotEmpty && !images.contains(main)) images.insert(0, main);

    List<dynamic> listOf(dynamic v) =>
        v is List ? List<dynamic>.from(v) : <dynamic>[];

    String priceOf(dynamic v) {
      final p = double.tryParse(v?.toString() ?? '');
      return p == null ? '0' : p.toStringAsFixed(2);
    }

    String str(dynamic v) => v?.toString() ?? '';

    final brand = productData['brand'];
    final parentCategory = productData['parentCategory'];
    Map? sub;
    for (final k in ['subcategory', 'subCategory', 'childCategory']) {
      if (productData[k] is Map) {
        sub = productData[k] as Map;
        break;
      }
    }
    String subcategoryName = '';
    if (sub != null && (sub['name']?.toString().isNotEmpty ?? false)) {
      subcategoryName = sub['name'].toString();
    } else {
      final cat = productData['category'];
      if (cat is Map && (cat['name']?.toString().isNotEmpty ?? false)) {
        subcategoryName = cat['name'].toString();
      }
    }

    return NewProductDetails(
      specs: listOf(productData['specifications']),
      reviews: listOf(productData['reviews']),
      images: images,
      productId: str(productData['_id']),
      name: productData['name']?.toString() ?? 'Product',
      brandName: brand is Map ? str(brand['name']) : '',
      categoryName:
          parentCategory is Map ? str(parentCategory['name']) : '',
      categoryId: parentCategory is Map ? str(parentCategory['_id']) : '',
      sku: str(productData['sku']),
      offerPrice: priceOf(productData['offerPrice']),
      price: priceOf(productData['price']),
      stockStatus: str(productData['stockStatus']).isEmpty
          ? 'Unknown'
          : str(productData['stockStatus']),
      stockCount: str(productData['stock'] ??
          productData['countInStock'] ??
          productData['stockCount'] ??
          productData['quantity']),
      description: str(productData['description']),
      shortdesc: str(productData['shortDescription']),
      subcategoryName: subcategoryName,
      colorVariations: listOf(productData['colorVariations']),
      variations: listOf(productData['variations']),
      availableModels: listOf(productData['availableModels']),
    );
  }

  static Future<void> _openUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // ignore: avoid_print
      print('PushDeepLink: failed to open url $url: $e');
    }
  }
}
