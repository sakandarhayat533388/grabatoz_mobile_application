import 'package:get/get.dart';
import 'package:graba2z/Utils/image_helper.dart';
import 'package:graba2z/Utils/packages.dart';
import 'package:intl/intl.dart';
import 'package:graba2z/Views/Home/Screens/Settings/Modules/Order%20History/invoice_preview_screen.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Views/Home/Screens/Cart/cart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Views/Product%20Folder/newProductDetails.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  Future<Map<String, dynamic>> _fetchProductById(String productId) async {
    final uri = Uri.parse('${Configss.baseUrl}/api/products/$productId');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to fetch product ($productId): ${res.statusCode}');
    }
    final body = json.decode(res.body);
    final product = (body is Map && body['data'] is Map)
        ? body['data'] as Map<String, dynamic>
        : (body is Map && body['product'] is Map)
            ? body['product'] as Map<String, dynamic>
            : (body is Map<String, dynamic> ? body : <String, dynamic>{});
    if (product.isEmpty) throw Exception('Unexpected product payload');
    return product;
  }

  Future<void> _openProductDetails(
      BuildContext context,
      String productId,
      String fallbackName,
      String fallbackImage,
      double fallbackPrice) async {
    if (productId.isEmpty) {
      Get.snackbar('orders_warning'.tr, 'orders_missing_product_id'.tr);
      return;
    }

    try {
      EasyLoading.show(status: 'orders_loading_product'.tr);
      final product = await _fetchProductById(productId);

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

      String sku =
          product['sku']?.toString() ?? product['model']?.toString() ?? '';
      String offerPrice = product['offerPrice']?.toString() ??
          product['salePrice']?.toString() ??
          '';
      String price = product['price']?.toString() ??
          product['regularPrice']?.toString() ??
          fallbackPrice.toString();
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
      String description = product['description']?.toString() ??
          product['longDescription']?.toString() ??
          '';
      String shortdesc = product['shortdesc']?.toString() ??
          product['shortDescription']?.toString() ??
          '';
      List<dynamic> colorVariations = product['colorVariations'] is List
          ? List<dynamic>.from(product['colorVariations'])
          : [];
      List<dynamic> variations = product['variations'] is List
          ? List<dynamic>.from(product['variations'])
          : [];
      List<dynamic> availableModels = product['availableModels'] is List
          ? List<dynamic>.from(product['availableModels'])
          : [];

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

  Future<void> _handleOrderAgain(BuildContext context) async {
    try {
      EasyLoading.show(status: 'orders_reconstructing_cart'.tr);

      final cartNotifier = Get.find<CartNotifier>();

      // Resolve userId
      String? userId;
      try {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('userId')?.toString();
      } catch (_) {}

      final orderItems = List<Map<String, dynamic>>.from(order['orderItems'] ?? []);

      // Filter out protection items
      final nonProtectionItems = orderItems.where((item) => item['isProtection'] != true).toList();

      if (nonProtectionItems.isEmpty) {
        EasyLoading.dismiss();
        Get.snackbar('orders_info'.tr, 'orders_no_reorder_items'.tr);
        return;
      }

      // Map and add each item to local cart
      for (final item in nonProtectionItems) {
        final product = item['product'] is Map ? Map<String, dynamic>.from(item['product']) : null;
        final productId = product?['_id'] ?? product?['id'] ?? item['product']?.toString() ?? '';

        if (productId.isEmpty) continue;

        final productName = item['name'] ?? product?['name'] ?? 'orders_order_item'.tr;
        final productImage = item['image'] ?? product?['image'] ?? '';

        final double itemPrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
        final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

        // Parse selected color and DOS data
        final int? selectedColorIndex = item['selectedColorIndex'] != null
            ? int.tryParse(item['selectedColorIndex'].toString())
            : null;
        final Map<String, dynamic>? selectedColorData = item['selectedColorData'] is Map
            ? Map<String, dynamic>.from(item['selectedColorData'])
            : null;
        final int? selectedDosIndex = item['selectedDosIndex'] != null
            ? int.tryParse(item['selectedDosIndex'].toString())
            : null;

        final cartItem = CartOtherInfo(
          productId: productId,
          productName: productName,
          productImage: productImage,
          productPrice: itemPrice,
          originalPrice: itemPrice,
          quantity: qty,
          selectedColorIndex: selectedColorIndex,
          selectedColorData: selectedColorData,
          selectedDosIndex: selectedDosIndex,
          isProtection: false,
        );

        // Add to local cart via notifier, suppress intermediate notification popups
        await cartNotifier.addItemInfo(cartItem, userId, showNotification: false);
      }

      EasyLoading.dismiss();
      EasyLoading.showSuccess('orders_cart_reconstructed'.tr);

      // Navigate to Cart screen
      Get.to(() => const Cart());
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar('orders_error'.tr, 'orders_cart_reconstruct_failed'.trParams({'e': '$e'}));
    }
  }

  String formatPlacedDate(String dateStr) {
    try {
      DateTime parsed = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMMM d, yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status.toLowerCase()) {
      case 'delivered':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        text = 'orders_paid'.tr;
        break;
      case 'cancelled':
      case 'deleted':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        text = 'orders_cancelled'.tr;
        break;
      default:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        text = 'orders_pending'.tr;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: kmediumblackColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kdefblackColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderItems = List<Map<String, dynamic>>.from(order['orderItems']);
    final status = order['status'] ?? 'Pending';
    final paymentMethod = order['paymentMethod'] ?? 'card';
    final totalPrice = order['totalPrice']?.toString() ?? '0';

    // Parse and calculate prices safely
    double subtotal = 0;
    for (final item in orderItems) {
      final double price =
          double.tryParse(item['price']?.toString() ?? '0') ?? 0;
      final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      subtotal += price * qty;
    }

    double totalVal = double.tryParse(totalPrice) ?? subtotal;
    double shippingFee = totalVal - subtotal;
    if (shippingFee < 0) {
      shippingFee = 0;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        titleText: 'orders_details_title'.tr,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placed Date Subtitle Header
              Text(
                'orders_placed_on'.trParams({'date': formatPlacedDate(order['createdAt'] ?? '')}),
                style: const TextStyle(
                  fontSize: 14,
                  color: kmediumblackColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Order Items Header
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: kdefgreenColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'orders_items'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kdefblackColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Product Items List
              ...orderItems.map((item) {
                final product =
                    Map<String, dynamic>.from(item['product'] ?? {});

                // Safe name and image extraction
                String productName =
                    item['name'] ?? product['name'] ?? 'orders_order_item'.tr;
                String productImage = item['image'] ?? product['image'] ?? '';

                double itemPrice =
                    double.tryParse(item['price']?.toString() ?? '0') ?? 0;
                String itemPriceFormatted = itemPrice.toStringAsFixed(2);

                final productId =
                    product['_id'] ?? product['id'] ?? item['product']?.toString() ?? '';

                return InkWell(
                  onTap: () => _openProductDetails(
                    context,
                    productId,
                    productName,
                    productImage,
                    itemPrice,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Image
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.15)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.network(
                              ImageHelper.getUrl(productImage),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.shopping_bag_outlined,
                                color: kmediumblackColor,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Details (Name + Qty + Price)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  decoration: TextDecoration.underline,
                                  color: kdefblackColor,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'orders_qty'.trParams({'qty': '${item['quantity']}'}),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: kmediumblackColor,
                                    ),
                                  ),
                                  Text(
                                    "AED $itemPriceFormatted",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: kdefblackColor,
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
              }),
              const SizedBox(height: 16),

              // Payment Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'orders_payment_summary'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kdefblackColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'orders_subtotal'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: kmediumblackColor,
                          ),
                        ),
                        Text(
                          "AED ${subtotal.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kdefblackColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'orders_shipping_fee'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: kmediumblackColor,
                          ),
                        ),
                        Text(
                          shippingFee > 0
                              ? "AED ${shippingFee.toStringAsFixed(2)}"
                              : "AED 0",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kdefblackColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'orders_total'.tr,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kdefblackColor,
                          ),
                        ),
                        Text(
                          "AED ${totalVal.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kdefgreenColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.payment_rounded,
                                size: 18,
                                color: kmediumblackColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                paymentMethod.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kdefblackColor,
                                ),
                              ),
                            ],
                          ),
                          _buildPaymentStatusBadge(status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Order Additional Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'orders_delivery_details'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kdefblackColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoRow('orders_tracking_id'.tr,
                        "#${order['_id']?.toString().substring((order['_id']?.toString().length ?? 6) - 6) ?? ''}"),
                    _infoRow('orders_delivery_type'.tr,
                        "${order['deliveryType'] ?? 'Standard'}"),
                    _infoRow(
                        'orders_customer_note'.tr,
                        order['customerNotes'] != null &&
                                order['customerNotes']
                                    .toString()
                                    .trim()
                                    .isNotEmpty
                            ? "${order['customerNotes']}"
                            : 'orders_na'.tr),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, -2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleOrderAgain(context),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: Text(
                    'orders_order_again'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.to(() => InvoicePreviewScreen(order: order));
                  },
                  icon: const Icon(Icons.print_outlined, color: kdefgreenColor),
                  label: Text(
                    'orders_print_invoice'.tr,
                    style: TextStyle(
                      color: kdefgreenColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kdefgreenColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
