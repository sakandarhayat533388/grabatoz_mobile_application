import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Utils/image_helper.dart';
import 'package:graba2z/Views/Product%20Folder/newProductDetails.dart';

import '../../../../../../Utils/packages.dart';

class OrderCard extends StatelessWidget {
  final String orderId;
  final String createdDate;
  final String totalPrice;
  final String status;
  final List orderItems;
  final VoidCallback onViewDetails;
  final VoidCallback onDownloadInvoice;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.createdDate,
    required this.totalPrice,
    required this.status,
    required this.orderItems,
    required this.onViewDetails,
    required this.onDownloadInvoice,
  });

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'delivered':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'cancelled':
      case 'deleted':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        icon = Icons.warning_amber_rounded;
        break;
      case 'processing':
      case 'pending':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        icon = Icons.schedule_rounded;
        break;
      case 'confirmed':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        icon = Icons.thumb_up_alt_outlined;
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF4B5563);
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 4),
          Text(
            _localizedStatus(status),
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _localizedStatus(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'orders_status_delivered'.tr;
      case 'cancelled':
      case 'deleted':
        return 'orders_status_cancelled'.tr;
      case 'processing':
      case 'pending':
        return 'orders_status_pending'.tr;
      case 'confirmed':
        return 'orders_status_confirmed'.tr;
      case 'shipped':
        return 'orders_status_shipped'.tr;
      default:
        return status;
    }
  }

  Future<void> _openProductDetails(
    BuildContext context,
    String productId,
    String fallbackName,
    String fallbackImage,
    double fallbackPrice,
  ) async {
    if (productId.isEmpty) {
      Get.snackbar('orders_warning'.tr, 'orders_missing_product_id'.tr);
      return;
    }

    try {
      EasyLoading.show(status: 'orders_loading_product'.tr);
      final uri = Uri.parse('${Configss.baseUrl}/api/products/$productId');
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Failed to fetch product ($productId): ${res.statusCode}');
      }
      final body = json.decode(res.body);
      final product = (body is Map && body['data'] is Map)
          ? body['data'] as Map<String, dynamic>
          : (body is Map && body['product'] is Map)
              ? body['product'] as Map<String, dynamic>
              : (body is Map<String, dynamic> ? body : <String, dynamic>{});

      if (product.isEmpty) throw Exception('Unexpected product payload');

      // Extract/massage data for NewProductDetails
      List images = [];
      final rawImages = product['images'] ??
          product['gallery'] ??
          product['imageUrls'] ??
          product['productImages'] ??
          product['galleryImages'] ??
          product['image'];
      if (rawImages is List) {
        images = rawImages
            .map((e) {
              if (e is String) return e;
              if (e is Map && e['url'] is String) return e['url'];
              return null;
            })
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (rawImages is String && rawImages.isNotEmpty) {
        images = [rawImages];
      }
      if (images.isEmpty) {
        images = [
          fallbackImage.isNotEmpty
              ? fallbackImage
              : "https://i.postimg.cc/SsWYSvq6/noimage.png"
        ];
      }

      List specs = [];
      final rawSpecs = product['specs'] ?? product['specifications'];
      if (rawSpecs is List) specs = rawSpecs;

      List reviews = [];
      final rawReviews = product['reviews'] ?? product['productReviews'];
      if (rawReviews is List) reviews = rawReviews;

      String name = product['name']?.toString() ?? fallbackName;

      String brandName = '';
      final brandField = product['brand'] ?? product['brandName'];
      if (brandField is Map) {
        brandName = brandField['name']?.toString() ?? '';
      } else if (brandField is String) {
        brandName = brandField;
      }

      String categoryName = '';
      String categoryId = '';
      dynamic categoryField = product['parentCategory'] ??
          product['parentCategoryId'] ??
          product['category'] ??
          product['categoryId'] ??
          product['categories'];

      if (categoryField is Map) {
        categoryName = categoryField['name']?.toString() ?? categoryName;
        final catIdVal = categoryField['_id'] ?? categoryField['id'];
        categoryId = (catIdVal ?? '').toString();
      } else if (categoryField is String) {
        categoryId = categoryField;
        if ((product['categoryName'] ?? '').toString().isNotEmpty) {
          categoryName = product['categoryName'].toString();
        }
      } else if (categoryField is List) {
        for (final c in categoryField) {
          if (c is Map) {
            final cid = (c['_id'] ?? c['id'])?.toString();
            if (cid != null && cid.isNotEmpty) {
              categoryId = cid;
              categoryName = c['name']?.toString() ?? categoryName;
              break;
            }
          } else if (c is String && c.isNotEmpty) {
            categoryId = c;
            break;
          }
        }
      }

      if (categoryName.isEmpty) {
        categoryName = product['categoryName']?.toString() ?? categoryName;
      }

      String sku = product['sku']?.toString() ?? product['model']?.toString() ?? '';
      String offerPrice = product['offerPrice']?.toString() ?? product['salePrice']?.toString() ?? '';
      String price = product['price']?.toString() ?? product['regularPrice']?.toString() ?? fallbackPrice.toString();
      String stockStatus = product['stockStatus']?.toString() ??
          ((product['stock'] is num && (product['stock'] as num) > 0)
              ? 'Available'
              : 'Out of Stock');
      String stockCount = (product['stock'] ??
              product['countInStock'] ??
              product['stockCount'] ??
              product['quantity'] ??
              '')
          .toString();
      String description = product['description']?.toString() ?? product['longDescription']?.toString() ?? '';
      String shortdesc = product['shortdesc']?.toString() ?? product['shortDescription']?.toString() ?? '';
      List<dynamic> colorVariations = product['colorVariations'] is List ? List<dynamic>.from(product['colorVariations']) : [];
      List<dynamic> variations = product['variations'] is List ? List<dynamic>.from(product['variations']) : [];
      List<dynamic> availableModels = product['availableModels'] is List ? List<dynamic>.from(product['availableModels']) : [];

      EasyLoading.dismiss();
      Get.to(() => NewProductDetails(
            images: images,
            specs: specs,
            reviews: reviews,
            productId: productId,
            name: name,
            brandName: brandName,
            categoryName: categoryName,
            categoryId: categoryId,
            sku: sku,
            offerPrice: offerPrice,
            price: price,
            stockStatus: stockStatus,
            stockCount: stockCount,
            description: description,
            shortdesc: shortdesc,
            colorVariations: colorVariations,
            variations: variations,
            availableModels: availableModels,
          ));
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('Error fetching product details: $e');
      Get.snackbar('orders_error'.tr, 'orders_product_load_failed'.trParams({'e': '$e'}));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract first product name, image, and ID safely
    Map<String, dynamic>? firstItem;
    if (orderItems.isNotEmpty) {
      try {
        firstItem = Map<String, dynamic>.from(orderItems.first);
      } catch (_) {}
    }

    String productName = 'orders_order_item'.tr;
    String productImage = '';
    String productId = '';
    double itemPrice = 0.0;

    if (firstItem != null) {
      productName = firstItem['name'] ?? '';
      productImage = firstItem['image'] ?? '';
      itemPrice = double.tryParse(firstItem['price']?.toString() ?? '0') ?? 0.0;

      if (firstItem['product'] is Map) {
        final productMap = Map<String, dynamic>.from(firstItem['product']);
        if (productName.isEmpty) productName = productMap['name'] ?? '';
        if (productImage.isEmpty) productImage = productMap['image'] ?? '';
        productId = (productMap['_id'] ?? productMap['id'] ?? '').toString();
        if (itemPrice == 0.0) {
          itemPrice = double.tryParse(productMap['price']?.toString() ?? '0') ?? 0.0;
        }
      } else if (firstItem['product'] != null) {
        productId = firstItem['product'].toString();
      }

      if (productId.isEmpty) {
        productId = (firstItem['productId'] ?? firstItem['_id'] ?? '').toString();
      }
    }

    final hasMoreItems = orderItems.length > 1;

    // Format total price to 2 decimal places to avoid long decimal wrapping
    String formattedPrice = totalPrice;
    try {
      double priceVal = double.parse(totalPrice);
      formattedPrice = priceVal.toStringAsFixed(2);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: kdefwhiteColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section (Metadata and Status)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Order Number
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'orders_number'.tr,
                            style: TextStyle(
                              fontSize: 10,
                              color: kmediumblackColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "#${orderId.length > 6 ? orderId.substring(orderId.length - 6) : orderId}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: kdefblackColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Status Badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'orders_status'.tr,
                            style: TextStyle(
                              fontSize: 10,
                              color: kmediumblackColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildStatusBadge(status),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Date Placed
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'orders_date_placed'.tr,
                              style: TextStyle(
                                fontSize: 10,
                                color: kmediumblackColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              createdDate,
                              style: const TextStyle(
                                fontSize: 13,
                                color: kdefblackColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Divider
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey.withValues(alpha: 0.2),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      // Total Amount
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'orders_total_amount'.tr,
                              style: TextStyle(
                                fontSize: 10,
                                color: kmediumblackColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "AED $formattedPrice",
                              style: const TextStyle(
                                fontSize: 13,
                                color: kdefgreenColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Horizontal Divider
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.withValues(alpha: 0.12),
            ),

            // Bottom Section (Product Info and Buttons)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image Thumbnail
                      GestureDetector(
                        onTap: () => _openProductDetails(
                          context,
                          productId,
                          productName,
                          productImage,
                          itemPrice,
                        ),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.15),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: CachedNetworkImage(
                              imageUrl: ImageHelper.getUrl(productImage),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.withValues(alpha: 0.05),
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.shopping_bag_outlined,
                                color: kmediumblackColor,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Product Details Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _openProductDetails(
                                context,
                                productId,
                                productName,
                                productImage,
                                itemPrice,
                              ),
                              child: Text(
                                productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kdefblackColor,
                                  fontWeight: FontWeight.normal,
                                  decoration: TextDecoration.underline,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            if (hasMoreItems) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  (orderItems.length - 1) == 1 ? 'orders_one_more_item'.tr : 'orders_more_items'.trParams({'count': '${orderItems.length - 1}'}),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: kmediumblackColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons Row (aligned to center for mobile layout)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // View Details Button (Outlined style)
                      OutlinedButton.icon(
                        onPressed: onViewDetails,
                        icon: const Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: kSecondaryColor,
                        ),
                        label: Text(
                          'orders_view_details'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: kSecondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: kdefwhiteColor,
                          foregroundColor: kSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Invoice Button (light green background, green text and border)
                      ElevatedButton.icon(
                        onPressed: onDownloadInvoice,
                        icon: const Icon(
                          Icons.download_outlined,
                          size: 16,
                          color: kdefgreenColor,
                        ),
                        label: Text(
                          'orders_invoice'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: kdefgreenColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          backgroundColor: const Color(0xFFF0FDF4),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          foregroundColor: kdefgreenColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                              color: Color(0xFFDCFCE7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
