import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:graba2z/Api/Services/apiservices.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Controllers/checkout_controller.dart';
import 'package:graba2z/Controllers/deliveryController.dart';
import 'package:graba2z/Controllers/first_user_discount_controller.dart';
import 'package:graba2z/Controllers/loyalty_controller.dart';
import 'package:graba2z/Controllers/referral_controller.dart';
import 'package:graba2z/Utils/appcolors.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Utils/price_formatter.dart';
import 'package:graba2z/Utils/image_helper.dart';
import 'package:graba2z/Utils/packages.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:graba2z/Views/Product%20Folder/newProductDetails.dart';
import 'package:shimmer/shimmer.dart';

class NewSummaryView extends StatefulWidget {
  String shippingType;
  String phone;
  String companyName;
  String companyAddress;
  String customerEmail;
  String addressCustomer;
  double subtotal;

  NewSummaryView({
    super.key,
    required this.addressCustomer,
    required this.companyAddress,
    required this.companyName,
    required this.customerEmail,
    required this.phone,
    required this.shippingType,
    required this.subtotal,
  });

  @override
  State<NewSummaryView> createState() => _NewSummaryViewState();
}

class _NewSummaryViewState extends State<NewSummaryView> {
  UserController _userController = Get.put(UserController());
  CartNotifier _cartNotifier = Get.put(CartNotifier());
  final cart2provider = Get.put(CartNotifier());
  late DeliveryController _deliveryCtrl;
  final TextEditingController couponController = TextEditingController();
  bool _cartPricesHydrated = false;
  Worker? _loyaltyQuoteWorker;
  Worker? _referralQuoteWorker;
  Worker? _referralSelectionWorker;
  double? _lastQuotedSubtotal;

  double get _cartSubtotal => _cartNotifier.cartOtherInfoList.fold(
        0.0,
        (sum, item) => sum + (item.cartBasePrice * (item.quantity ?? 0)),
      );

  double get _cartOriginalTotal => _cartNotifier.cartOtherInfoList.fold(
        0.0,
        (sum, item) =>
            sum +
            (((item.originalPrice ?? item.productPrice) ?? 0.0) *
                (item.quantity ?? 0)),
      );

  bool get _isHomeDelivery => widget.shippingType == 'Home Delivery';

  double _shippingChargeFor(double subtotal) {
    if (!_isHomeDelivery) return 0.0;
    final fee = _deliveryCtrl.calculateShippingFee(subtotal);
    return fee ?? 0.0;
  }

  double _totalBeforeFirstOrderDiscount(double subtotal) {
    return subtotal + _shippingChargeFor(subtotal);
  }

  double _firstOrderDiscountAmount() {
    if (!Get.isRegistered<FirstUserDiscountController>()) return 0.0;

    final discountController = Get.find<FirstUserDiscountController>();
    if (!discountController.previewApplied.value) return 0.0;

    return discountController.previewDiscountAmount.value;
  }

  double get _loyaltyDiscountAed {
    if (!Get.isRegistered<LoyaltyController>()) return 0.0;
    return Get.find<LoyaltyController>().checkoutDiscountAed;
  }

  double get _referralDiscountAed {
    if (!Get.isRegistered<ReferralController>()) return 0.0;
    return Get.find<ReferralController>().checkoutDiscountAed;
  }

  int _snapPoints(double value, int step, int balance) {
    final effectiveStep = step <= 0 ? 1 : step;
    final snapped = (value / effectiveStep).round() * effectiveStep;
    if (snapped < 0) return 0;
    if (snapped > balance) return balance;
    return snapped;
  }

  void _maybeQuoteReferral(double subtotal) {
    if (!Get.isRegistered<ReferralController>()) return;
    final last = _lastQuotedSubtotal;
    if (last != null && (subtotal - last).abs() <= 0.01) return;
    // Set BEFORE calling so a build/quote feedback loop cannot form.
    _lastQuotedSubtotal = subtotal;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!Get.isRegistered<ReferralController>()) return;
      Get.find<ReferralController>().quoteCheckout(subtotal);
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<void> _openProductDetailsFromSummary(CartOtherInfo cartItem) async {
    final String productId = cartItem.productId?.toString() ?? '';
    if (productId.isEmpty) {
      Get.snackbar('checkout_warning_title'.tr, 'cart_missing_product_id'.tr);
      return;
    }

    try {
      EasyLoading.show(status: 'checkout_loading_details'.tr);
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
        final fallback = (cartItem.productImage?.isNotEmpty ?? false)
            ? cartItem.productImage!
            : "https://i.postimg.cc/SsWYSvq6/noimage.png";
        images = [fallback];
      }

      List specs = [];
      final rawSpecs = product['specs'] ?? product['specifications'];
      if (rawSpecs is List) specs = rawSpecs;

      List reviews = [];
      final rawReviews = product['reviews'] ?? product['productReviews'];
      if (rawReviews is List) reviews = rawReviews;

      String name = product['name']?.toString() ?? cartItem.productName ?? 'cart_unknown_product'.tr;

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
      String price = product['price']?.toString() ?? product['regularPrice']?.toString() ?? cartItem.cartBasePrice.toString();
      String stockStatus = product['stockStatus']?.toString() ??
          ((product['stock'] is num && (product['stock'] as num) > 0)
              ? 'cart_stock_available'.tr
              : 'cart_stock_out'.tr);
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
      Get.snackbar('checkout_error_title'.tr, 'checkout_failed_open_details'.tr);
    }
  }

  Future<void> _hydrateCartPricesFromProducts() async {
    if (_cartPricesHydrated || _cartNotifier.cartOtherInfoList.isEmpty) return;
    _cartPricesHydrated = true;

    var changed = false;
    for (final item in _cartNotifier.cartOtherInfoList) {
      final productId = item.productId?.toString() ?? '';
      if (productId.isEmpty) continue;

      try {
        final response = await http.get(
          Uri.parse('${Configss.baseUrl}/api/products/$productId'),
        );
        if (response.statusCode != 200) continue;

        final decoded = jsonDecode(response.body);
        final product = decoded is Map && decoded['data'] is Map
            ? Map<String, dynamic>.from(decoded['data'] as Map)
            : decoded is Map && decoded['product'] is Map
                ? Map<String, dynamic>.from(decoded['product'] as Map)
                : decoded is Map
                    ? Map<String, dynamic>.from(decoded)
                    : <String, dynamic>{};

        final regularPrice = _toDouble(
          product['price'] ?? product['regularPrice'] ?? product['mrp'],
        );
        final offerPrice = _toDouble(
          product['offerPrice'] ??
              product['salePrice'] ??
              product['discountPrice'],
        );
        final currentPrice = offerPrice > 0 ? offerPrice : regularPrice;
        if (currentPrice <= 0) continue;

        final originalPrice =
            regularPrice > currentPrice ? regularPrice : currentPrice;
        if ((item.productPrice ?? 0.0) != currentPrice ||
            (item.originalPrice ?? 0.0) != originalPrice) {
          item.productPrice = currentPrice;
          item.originalPrice = originalPrice;
          changed = true;
        }
      } catch (_) {}
    }

    if (!changed || !mounted) return;

    _syncSummaryTotals();
    _cartNotifier.update();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId')?.toString();
      await _cartNotifier.saveCartToPrefs(userId);
    } catch (_) {}
    if (Get.isRegistered<FirstUserDiscountController>()) {
      Get.find<FirstUserDiscountController>()
          .previewCart(_cartNotifier.cartOtherInfoList);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _deliveryCtrl = Get.find<DeliveryController>();
    if (Get.isRegistered<LoyaltyController>()) {
      _loyaltyQuoteWorker =
          ever(Get.find<LoyaltyController>().checkoutQuote, (_) {
        _syncSummaryTotals();
      });
    }
    if (Get.isRegistered<ReferralController>()) {
      final referralCtrl = Get.find<ReferralController>();
      _referralQuoteWorker = ever(referralCtrl.checkoutQuote, (_) {
        _syncSummaryTotals();
      });
      _referralSelectionWorker = ever(referralCtrl.checkoutRewardId, (_) {
        _syncSummaryTotals();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncSummaryTotals();
      if (Get.isRegistered<ReferralController>()) {
        // Set BEFORE calling (see _maybeQuoteReferral) so build() does
        // not immediately fire a duplicate quote for the same subtotal.
        _lastQuotedSubtotal = _cartSubtotal;
        Get.find<ReferralController>().quoteCheckout(_cartSubtotal);
      }
      _hydrateCartPricesFromProducts();
      if (!mounted || !Get.isRegistered<FirstUserDiscountController>()) return;
      final discountController = Get.find<FirstUserDiscountController>();
      discountController.loadStatus().then((_) {
        discountController.previewCart(_cartNotifier.cartOtherInfoList);
      });
    });
  }

  @override
  void didUpdateWidget(covariant NewSummaryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSummaryTotals();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _loyaltyQuoteWorker?.dispose();
    _referralQuoteWorker?.dispose();
    _referralSelectionWorker?.dispose();
    super.dispose();
  }

  void _syncSummaryTotals() {
    final subtotal = _cartSubtotal;
    _userController.subtotalAmount.value = subtotal;
    _cartNotifier.deliveryFeeCharge.value = _shippingChargeFor(subtotal);
    final total = (_totalBeforeFirstOrderDiscount(subtotal) -
            _loyaltyDiscountAed -
            _referralDiscountAed)
        .clamp(0.0, double.infinity)
        .toDouble();
    _cartNotifier.totalAmount.value = total;
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _cartSubtotal;
    _maybeQuoteReferral(subtotal);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 6),
          child: Row(
            children: [
              Text(
                'checkout_delivery_details'.tr,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 0),
          child: defaultStyledContainer(
            child: widget.shippingType == 'Home Delivery'
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'checkout_home_delivery'.tr,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(),
                      Text(widget.customerEmail),
                      Text("${widget.phone}"),
                      Text(widget.addressCustomer),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'checkout_store_pickup'.tr,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(),
                      Text('checkout_phone_colon'.trParams({'phone': widget.phone})),
                      Text(widget.companyName),
                      Text(widget.companyAddress),
                    ],
                  ),
          ),
        ),
        if (_isHomeDelivery && subtotal <= 500)
          Obx(() {
            final method = _deliveryCtrl.selectedMethod;
            if (method == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 6),
              child: defaultStyledContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (method.deliveryTime.isNotEmpty)
                          Text(method.deliveryTime,
                              style: const TextStyle(
                                  fontSize: 12, color: kmediumblackColor)),
                      ],
                    ),
                    Text(
                      formatPriceForSelected(method.charge),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          }),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 6),
          child: Row(
            children: [
              Text(
                'checkout_order_notes'.tr,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: _userController.optionalNote,
          decoration: InputDecoration(
              labelText: 'checkout_note_label'.tr,
              hintStyle: TextStyle(color: Colors.grey),
              hintText: 'checkout_note_hint'.tr,
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey)),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey))),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 10),
          child: Row(
            children: [
              Text(
                'checkout_your_order'.tr,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cart2provider.cartOtherInfoList.length,
          itemBuilder: (context, index) {
            var cartItem = cart2provider.cartOtherInfoList[index];

            String formattedDate = cartItem.addedToCartTime != null
                ? DateFormat('MMM dd, yyyy h:mm a')
                    .format(cartItem.addedToCartTime!)
                : 'cart_no_date'.tr;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6),
              child: InkWell(
                onTap: () => _openProductDetailsFromSummary(cartItem),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CachedNetworkImage(
                            imageUrl: cartItem.productImage?.isNotEmpty ?? false
                                ? ImageHelper.getUrl(
                                    cartItem.productImage.toString())!
                                : "https://i.postimg.cc/SsWYSvq6/noimage.png",
                            imageBuilder: (context, imageProvider) => Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: Colors.grey.shade200,
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            placeholder: (context, url) => SizedBox(
                              width: 55,
                              height: 55,
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 55,
                              width: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    'https://i.postimg.cc/SsWYSvq6/noimage.png',
                                  ),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cartItem.productName ?? "",
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  formatPriceForSelected(cartItem.cartBasePrice * (cartItem.quantity ?? 0)),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: themePriceColor(),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'cart_dated'.trParams({'date': formattedDate}),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            (cartItem.quantity == 1 ? 'checkout_quantity_pc'.trParams({'quantity': cartItem.quantity.toString()}) : 'checkout_quantity_pcs'.trParams({'quantity': cartItem.quantity.toString()})),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loyalty points redemption (checkout)
            Obx(() {
              if (!Get.isRegistered<LoyaltyController>()) {
                return const SizedBox.shrink();
              }
              final loyaltyCtrl = Get.find<LoyaltyController>();
              final loyaltyAccount = loyaltyCtrl.account.value;
              if (!loyaltyCtrl.isEnabled || loyaltyAccount == null) {
                return const SizedBox.shrink();
              }
              final loyaltySettings = loyaltyCtrl.settings.value;
              if (!loyaltyAccount.canRedeem) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: defaultStyledContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.stars,
                                size: 20, color: kPrimaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${loyaltyCtrl.pointsName}: ${loyaltyAccount.balance}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'loyalty_below_min'.trParams({
                            'points':
                                '${loyaltySettings?.minPointsToRedeem ?? 0}'
                          }),
                          style: const TextStyle(
                              fontSize: 12, color: kmediumblackColor),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final redeemStep = loyaltySettings?.redeemStep ?? 1;
              final quote = loyaltyCtrl.checkoutQuote.value;
              final sliderMax = max(1, loyaltyAccount.balance).toDouble();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: defaultStyledContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.stars,
                              size: 20, color: kPrimaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${'loyalty_use_points'.tr} (${loyaltyCtrl.pointsName})',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: min(
                            loyaltyCtrl.checkoutPoints.value.toDouble(),
                            sliderMax),
                        min: 0,
                        max: sliderMax,
                        onChanged: (value) {
                          loyaltyCtrl.checkoutPoints.value = _snapPoints(
                              value, redeemStep, loyaltyAccount.balance);
                        },
                        onChangeEnd: (value) {
                          final snapped = _snapPoints(
                              value, redeemStep, loyaltyAccount.balance);
                          loyaltyCtrl.checkoutPoints.value = snapped;
                          loyaltyCtrl.quoteCheckout(_cartSubtotal, snapped);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${loyaltyCtrl.checkoutPoints.value} ${loyaltyCtrl.pointsName}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          if (quote != null &&
                              loyaltyCtrl.checkoutPoints.value > 0)
                            Text(
                              '= -${formatPriceForSelected(quote.discountAed)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32)),
                            ),
                        ],
                      ),
                      if (quote != null &&
                          loyaltyCtrl.checkoutPoints.value > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'max ${quote.maxPoints}',
                            style: const TextStyle(
                                fontSize: 11, color: kmediumblackColor),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            // Referral reward selection (checkout)
            Obx(() {
              if (!Get.isRegistered<ReferralController>()) {
                return const SizedBox.shrink();
              }
              final referralCtrl = Get.find<ReferralController>();
              if (!referralCtrl.isEnabled) {
                return const SizedBox.shrink();
              }
              final referralQuote = referralCtrl.checkoutQuote.value;
              if (referralQuote == null) {
                return const SizedBox.shrink();
              }
              final activeRewards = referralQuote.rewards
                  .where((reward) => reward.isActive)
                  .toList();
              if (activeRewards.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: defaultStyledContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'referral_reward_line'.tr,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      RadioListTile<String>(
                        value: '',
                        groupValue: referralCtrl.checkoutRewardId.value,
                        onChanged: (value) {
                          referralCtrl.checkoutRewardId.value = value ?? '';
                          _syncSummaryTotals();
                        },
                        title: Text('referral_none'.tr),
                      ),
                      for (final reward in activeRewards)
                        RadioListTile<String>(
                          value: reward.id,
                          groupValue: referralCtrl.checkoutRewardId.value,
                          onChanged: (value) {
                            referralCtrl.checkoutRewardId.value =
                                value ?? '';
                            _syncSummaryTotals();
                          },
                          title: Text(reward.description.isNotEmpty
                              ? reward.description
                              : reward.referralTypeName),
                          subtitle: Text(
                              '-${formatPriceForSelected(reward.quoteDiscountAed)}'),
                        ),
                    ],
                  ),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: defaultStyledContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'payment_order_summary'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Original Price
                    _buildSummaryRowWithStyle(
                      'payment_original_price'.tr,
                      formatPriceForSelected(_cartOriginalTotal),
                      valueStyle: TextStyle(
                        fontSize: 13,
                        color: themeOldPriceColor(),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Discounted Price
                    _buildSummaryRowWithStyle(
                      'payment_discounted_price'.tr,
                      formatPriceForSelected(subtotal),
                      valueStyle: TextStyle(
                        fontSize: 13,
                        color: themePriceColor(), // Red/Orange color
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Total Savings
                    _buildSummaryRowWithStyle(
                      'payment_total_savings'.tr,
                      "- ${formatPriceForSelected((_cartOriginalTotal - subtotal).clamp(0.0, double.infinity))}",
                      titleStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                      valueStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.black12, height: 1),
                    const SizedBox(height: 12),
                    // Subtotal
                    _buildSummaryRowWithStyle(
                      'payment_subtotal'.tr,
                      formatPriceForSelected(subtotal),
                      valueStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Shipping (Only show if home delivery AND backend has active delivery charges)
                    Obx(() {
                      final fee = _shippingChargeFor(subtotal);
                      if (!_isHomeDelivery || !_deliveryCtrl.hasActiveDeliveryCharges) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryRowWithStyle(
                            'checkout_shipping'.tr,
                            fee > 0
                                ? formatPriceForSelected(fee)
                                : 'checkout_free'.tr,
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                    Obx(() {
                      final firstOrderDiscount = _firstOrderDiscountAmount();
                      if (firstOrderDiscount <= 0) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: [
                          _buildSummaryRowWithStyle(
                            'payment_first_order_discount'.tr,
                            "- ${formatPriceForSelected(firstOrderDiscount)}",
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                            ),
                            valueStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                    Obx(() {
                      if (!Get.isRegistered<LoyaltyController>()) {
                        return const SizedBox.shrink();
                      }
                      final loyaltyCtrl = Get.find<LoyaltyController>();
                      final loyaltyDiscount = loyaltyCtrl.checkoutDiscountAed;
                      if (loyaltyDiscount <= 0) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _buildSummaryRowWithStyle(
                            'loyalty_redeem_line'.trParams(
                                {'name': loyaltyCtrl.pointsName}),
                            "- ${formatPriceForSelected(loyaltyDiscount)}",
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                            ),
                            valueStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                    Obx(() {
                      if (!Get.isRegistered<ReferralController>()) {
                        return const SizedBox.shrink();
                      }
                      final referralDiscount =
                          Get.find<ReferralController>().checkoutDiscountAed;
                      if (referralDiscount <= 0) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _buildSummaryRowWithStyle(
                            'referral_reward_line'.tr,
                            "- ${formatPriceForSelected(referralDiscount)}",
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                            ),
                            valueStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                    // VAT Included
                    _buildSummaryRowWithStyle(
                      'payment_vat_included'.tr,
                      "✓",
                      valueStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.black12, height: 1),
                    const SizedBox(height: 16),
                    // Total Amount
                    Obx(() {
                      final currentShipping = _shippingChargeFor(subtotal);
                      final currentTotalBeforeDiscount = subtotal + currentShipping;
                      final firstUserDiscount = _firstOrderDiscountAmount();
                      final displayTotal = (currentTotalBeforeDiscount -
                              firstUserDiscount -
                              _loyaltyDiscountAed -
                              _referralDiscountAed)
                          .clamp(0.0, double.infinity);
                      return _buildSummaryRowWithStyle(
                        'payment_total_amount'.tr,
                        formatPriceForSelected(displayTotal),
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        valueStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Free shipping applied banner (Only show if active delivery charges exist AND free shipping threshold met)
            Obx(() {
              if (_isHomeDelivery &&
                  _deliveryCtrl.hasActiveDeliveryCharges &&
                  _deliveryCtrl.isFreeShippingApplied(subtotal)) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9), // Light green background
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFC8E6C9), // Light green border
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'checkout_free_shipping_applied'.tr,
                          style: TextStyle(
                            color: Color(0xFF2E7D32), // Dark green text
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            Padding(
              padding: defaultPadding(vertical: 10),
              child: GetBuilder<ApiServiceController>(builder: (
                provider,
              ) {
                return PrimaryButton(
                  buttonText: 'checkout_continue_to_payment'.tr,
                  onPressFunction: () async {
                    _userController.activeStep.value = 2;
                  },
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRowWithStyle(String title, String value,
      {TextStyle? titleStyle, TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: titleStyle ??
              const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
        ),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
        ),
      ],
    );
  }
}
