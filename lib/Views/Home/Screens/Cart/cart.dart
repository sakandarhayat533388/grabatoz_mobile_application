// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
// ADD: imports for local fetch
import 'dart:convert';
import 'package:graba2z/Utils/image_helper.dart';
import 'package:http/http.dart' as http;
import 'package:graba2z/Configs/config.dart';
import 'package:get/get.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Controllers/first_user_discount_controller.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Utils/guest_checkout_storage.dart';
import 'package:graba2z/Views/Auth/signup.dart';
import 'package:graba2z/Views/Home/Screens/Cart/new_checkout_view.dart';
import 'package:graba2z/Views/Home/home.dart';
import 'package:intl/intl.dart';
import '/Utils/packages.dart';
import 'package:graba2z/Views/Product%20Folder/newProductDetails.dart';
import 'package:flutter_svg/flutter_svg.dart';

const String _homeSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 12L12 4L20 12" />
  <path d="M5 12V20H10V15H14V20H19V12" />
</svg>
''';

const Color _discountBrandColor = kPrimaryColor;
const Color _discountGold = Color(0xFFF5B51B);
const Color _discountSoftBrandColor = Color(0xFFF0FBE0);
const Color _discountSoftGold = Color(0xFFFFF7E4);

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final TextEditingController couponController = TextEditingController();
  @override
  void initState() {
    super.initState();
    final cartNotifier = Get.find<CartNotifier>();

    _loadUserIdAndCart(cartNotifier).then((_) {
      if (!mounted || !Get.isRegistered<FirstUserDiscountController>()) return;
      final discountController = Get.find<FirstUserDiscountController>();
      discountController.loadStatus().then((__) {
        discountController.previewCart(cartNotifier.cartOtherInfoList);
      });
    });
  }

  /// **New method to load `userId` from `SharedPreferences`**
  Future<void> _loadUserIdAndCart(CartNotifier cartNotifier) async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserId =
        prefs.getString('userId'); // Get user ID from shared prefs

    String? userId = storedUserId?.toString();
    cartNotifier.loadCartFromPrefs(userId); // Pass userId to load cart
  }

  double _couponAdjustedCartTotal(CartNotifier cartNotifier) {
    return cartNotifier.discountAmountApplied.value == 0.0
        ? cartNotifier.cartTotalPriceF()
        : cartNotifier.totalAmount.value;
  }

  double _guestRegistrationDiscountAmount(
    CartNotifier cartNotifier,
    AuthController authProvider,
  ) {
    if (authProvider.userID.value.isNotEmpty ||
        cartNotifier.cartOtherInfoList.isEmpty) {
      return 0.0;
    }

    final cartTotal = _couponAdjustedCartTotal(cartNotifier);
    final discount = cartTotal *
        (FirstUserDiscountController.guestCardDiscountPercent / 100);
    return double.parse(discount.clamp(0.0, cartTotal).toStringAsFixed(2));
  }

  double _appOrderDiscountAmount(
    CartNotifier cartNotifier,
    AuthController authProvider,
  ) {
    if (Get.isRegistered<FirstUserDiscountController>()) {
      final discountController = Get.find<FirstUserDiscountController>();
      if (discountController.previewApplied.value &&
          discountController.previewDiscountAmount.value > 0) {
        return discountController.previewDiscountAmount.value;
      }
    }

    return _guestRegistrationDiscountAmount(cartNotifier, authProvider);
  }

  // ADD: Local product fetch to avoid undefined ApiServices error
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

  Future<void> _openProductDetailsFromCart(CartOtherInfo cartItem) async {
    final String pid = cartItem.productId?.toString() ?? '';
    if (pid.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Missing product ID')));
      return;
    }

    try {
      // ...existing fetch and parsing code...
      final product = await _fetchProductById(pid);

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

      String name = product['name']?.toString() ??
          cartItem.productName ??
          'Unknown Product';

      // FIX: brand/category extraction without map?['key']
      String brandName = '';
      final brandField = product['brand'] ?? product['brandName'];
      if (brandField is Map) {
        brandName = brandField['name']?.toString() ?? '';
      } else if (brandField is String) {
        brandName = brandField;
      }

      // UPDATED: Robust category extraction to ensure categoryId is set for related products
      String categoryName = '';
      String categoryId = '';

      dynamic categoryField = product['parentCategory'] ??
          product['parentCategoryId'] ??
          product['category'] ??
          product['categoryId'] ??
          product['categories']; // sometimes array

      if (categoryField is Map) {
        // Common shape: { _id, name, ... }
        categoryName = categoryField['name']?.toString() ?? categoryName;
        final catIdVal = categoryField['_id'] ?? categoryField['id'];
        categoryId = (catIdVal ?? '').toString();
      } else if (categoryField is String) {
        // Could be an ID or a name; prefer treating it as ID
        categoryId = categoryField;
        // If you also expose categoryName as string in your API, set it too
        if ((product['categoryName'] ?? '').toString().isNotEmpty) {
          categoryName = product['categoryName'].toString();
        }
      } else if (categoryField is List) {
        // Some payloads include categories as a list; pick the first with an ID
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

      // Fallback to explicit categoryName if still empty
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
          cartItem.cartBasePrice.toString();
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

      Get.to(() => NewProductDetails(
            images: images,
            specs: specs,
            reviews: reviews,
            productId: pid,
            name: name,
            brandName: brandName,
            categoryName: categoryName,
            categoryId: categoryId, // now reliably populated
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
      debugPrint('Error fetching product details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load product details')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartNotifier = Get.find<CartNotifier>();

    return Scaffold(
      appBar: CustomAppBar(
        titleText: "My Cart",
        actionicon: GestureDetector(
          onTap: () async {
            // Update the bottom navigation index safely
            Get.put(BottomNavigationController()).setTabIndex(0);

            Get.offAll(() => Home());
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: SvgPicture.string(
              _homeSvg,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              semanticsLabel: 'Home',
            ),
          ),
        ),
      ),
      body: cartNotifier.cartOtherInfoList.isEmpty
          ? SafeArea(
              child: Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/emptycart.png',
                  ),
                  20.0.heightbox,
                  const Text(
                    "Your cart is empty\nYou haven't added any product yet.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kSecondaryColor,
                    ),
                  ),
                ],
              )),
            )
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  10.0.heightbox,
                  Padding(
                    padding: defaultPadding(),
                    child: Row(
                      children: [
                        Badge(
                          label: Text(
                            cartNotifier.cartOtherInfoList.length.toString(),
                            style: const TextStyle(
                              color: kdefwhiteColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: kPrimaryColor,
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: kPrimaryColor,
                            ),
                            child: const Icon(
                              Icons.shopify,
                              color: kdefwhiteColor,
                              size: 16,
                            ),
                          ),
                        ),
                        10.0.widthbox,
                        Text(
                            "${cartNotifier.cartOtherInfoList.length} products in your cart",
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: kdefblackColor)),
                      ],
                    ),
                  ),
                  10.0.heightbox,
                  cartNotifier.cartOtherInfoList.isNotEmpty
                      ? Expanded(
                          child: ListView.builder(
                            itemCount: cartNotifier.cartOtherInfoList.length,
                            itemBuilder: (context, index) {
                              var cartItem =
                                  cartNotifier.cartOtherInfoList[index];
                              return Dismissible(
                                key: Key(cartItem.productName!),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) async {
                                  // CHANGED: only confirm, do not remove here
                                  return await _confirmRemoveDialog(
                                        context,
                                        cartItem.productName!,
                                        cartItem.productImage!,
                                        cartItem.cartBasePrice.toString(),
                                        cartItem.quantity.toString(),
                                      ) ==
                                      true;
                                },
                                onDismissed: (direction) async {
                                  // CHANGED: perform actual removal here so Dismissible and data stay in sync
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  String? userId =
                                      prefs.getString('userId')?.toString();
                                  cartNotifier.removeItemInfo(
                                      cartItem.productName!, userId);
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration:
                                          const Duration(milliseconds: 400),
                                      content: Text(
                                          "${cartItem.productName} removed"),
                                    ),
                                  );
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: kredColor.withValues(alpha: 0.6),
                                  ),
                                  child: Image.asset(
                                    'assets/icons/trash.png',
                                    width: 30,
                                    height: 30,
                                  ),
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    await _openProductDetailsFromCart(cartItem);
                                  },
                                  child: CartItemWidget(
                                      cartItem: cartItem,
                                      onIncrease: () async {
                                        setState(() {});
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        String? userId = prefs
                                            .getString('userId')
                                            ?.toString(); // Retrieve user ID
                                        cartNotifier.increaseQuantity(
                                            index, userId);
                                      },
                                      onDecrease: () async {
                                        setState(() {});
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        String? userId = prefs
                                            .getString('userId')
                                            ?.toString(); // Retrieve user ID
                                        if (cartNotifier
                                                .cartOtherInfoList[index]
                                                .quantity ==
                                            1) {
                                          _showRemoveDialog(
                                            context,
                                            cartItem.productName ?? "",
                                            cartItem.productImage?.isNotEmpty ??
                                                    false
                                                ? ImageHelper.getUrl(cartItem
                                                    .productImage
                                                    .toString())
                                                : "https://i.postimg.cc/SsWYSvq6/noimage.png",
                                            cartItem.cartBasePrice.toString(),
                                            cartItem.quantity.toString(),
                                            cartNotifier,
                                          );
                                        } else {
                                          cartNotifier.decreaseQuantity(
                                              index, userId);
                                        }
                                      },
                                      onRemove: () {
                                        _showRemoveDialog(
                                          context,
                                          cartItem.productName ?? "",
                                          cartItem.productImage?.isNotEmpty ??
                                                  false
                                              ? ImageHelper.getUrl(cartItem
                                                  .productImage
                                                  .toString())
                                              : "https://i.postimg.cc/SsWYSvq6/noimage.png",
                                          cartItem.cartBasePrice.toString(),
                                          cartItem.quantity.toString(),
                                          cartNotifier,
                                        );
                                      }),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/icons/cart.png',
                                color: kPrimaryColor,
                                width: 100,
                                height: 100,
                              ),
                              20.0.heightbox,
                              const Text(
                                "Your cart is empty\nYou haven't added any product yet.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              10.0.heightbox,
              Container(
                padding: defaultPadding(vertical: 8),
                decoration: BoxDecoration(
                  color: kdefgreyColor,
                  borderRadius: defaultBorderRadious,
                  boxShadow: defaultBoxShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Quantity:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${cartNotifier.totalItems} pcs',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kSecondaryColor),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Products Price:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${cartNotifier.cartTotalPriceF().toStringAsFixed(2)} AED',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kredColor),
                        ),
                      ],
                    ),
                    10.0.heightbox,
                    // Coupon Input Field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: PrimaryTextField(
                            cursorColor: kSecondaryColor,
                            backgroundColor: kdefwhiteColor,
                            textColor: kSecondaryColor,
                            hinttextColor: kmediumblackColor,
                            controller: couponController,
                            hintText: 'Enter coupon code',
                          ),
                        ),
                        10.0.widthbox,
                        PrimaryButton(
                          fontSize: 10,
                          height: 40,
                          width: Get.width / 3.5,
                          onPressFunction: () async {
                            FocusScope.of(context).unfocus();
                            final couponCode = couponController.text.trim();
                            if (couponCode.isNotEmpty) {
                              for (var i = 0;
                                  i < cartNotifier.cartOtherInfoList.length;
                                  i++) {
                                cartNotifier.postCouponList.add({
                                  "product": cartNotifier
                                      .cartOtherInfoList[i].productId,
                                  "qty": cartNotifier
                                      .cartOtherInfoList[i].quantity,
                                });
                              }
                              log('the list in cart ${cartNotifier.cartOtherInfoList[0].productName}');

                              await cartNotifier.addCoupon(
                                  couponCode,
                                  couponController,
                                  cartNotifier.postCouponList,
                                  context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Enter a valid coupon!")),
                              );
                            }
                          },
                          buttonText: "Grab Coupon",
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Discount Applied Row
                    Obx(
                      () => cartNotifier.discountAmountApplied.value > 0
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Discount Applied:',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '- ${cartNotifier.discountAmountApplied.value.toStringAsFixed(2)} AED',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red),
                                ),
                              ],
                            )
                          : SizedBox.shrink(),
                    ),
                    Obx(() {
                      final authProvider = Get.find<AuthController>();
                      final appDiscountAmount =
                          _appOrderDiscountAmount(cartNotifier, authProvider);
                      if (appDiscountAmount <= 0) {
                        return const SizedBox.shrink();
                      }

                      final isGuestPreview = authProvider.userID.value.isEmpty;
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isGuestPreview
                                    ? 'App registration discount:'
                                    : 'First app order discount:',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '- ${appDiscountAmount.toStringAsFixed(2)} AED',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              ),
                            ],
                          ),
                          if (isGuestPreview)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Register before checkout to get this discount.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: kmediumblackColor,
                                ),
                              ),
                            ),
                        ],
                      );
                    }),

                    // Final Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Final Price:',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Obx(
                          () {
                            final authProvider = Get.find<AuthController>();
                            final couponAdjustedTotal =
                                _couponAdjustedCartTotal(cartNotifier);
                            final appDiscountAmount = _appOrderDiscountAmount(
                                cartNotifier, authProvider);
                            final displayTotal =
                                (couponAdjustedTotal - appDiscountAmount)
                                    .clamp(0.0, double.infinity);
                            return Text(
                              "${displayTotal.toStringAsFixed(2)} AED",
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor),
                            );
                          },
                        )
                      ],
                    ),

                    // Remove Coupon Button
                    Obx(
                      () => cartNotifier.discountAmountApplied.value > 0
                          ? TextButton(
                              onPressed: () {
                                cartNotifier.removeCoupon();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Coupon Removed")),
                                );
                              },
                              child: const Text("Remove Coupon",
                                  style: TextStyle(color: Colors.red)),
                            )
                          : SizedBox.shrink(),
                    ),
                    20.0.heightbox,
                    GetBuilder<AuthController>(builder: (
                      authProvider,
                    ) {
                      return PrimaryButton(
                        width: 190,
                        buttonColor: cartNotifier.cartOtherInfoList.isNotEmpty
                            ? kPrimaryColor
                            : kPrimaryColor.withValues(alpha: 0.5),
                        onPressFunction:
                            cartNotifier.cartOtherInfoList.isNotEmpty
                                ? () async {
                                    if (authProvider.userID.value.isNotEmpty) {
                                      // Navigate to checkout screen if the user is logged in
                                      Get.to(() => CheckoutStepper(
                                            isforguest: false,
                                          ));
                                      // context.route(CheckOutScreen());
                                    } else {
                                      // Show login/signup dialog if the user is not logged in
                                      showCheckoutDialog(context);
                                    }
                                  }
                                : null,
                        buttonText: cartNotifier.cartOtherInfoList.isNotEmpty
                            ? 'Checkout'
                            : 'Cart is Empty',
                      );
                    }),
                    10.0.heightbox,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showRemoveDialog(
    BuildContext context,
    String itemName,
    String image,
    String price,
    String quantity,
    CartNotifier cartNotifier,
  ) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Remove from Cart?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedNetworkImage(
                    imageUrl: image,
                    imageBuilder: (context, imageProvider) => Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: kPrimaryColor.withValues(alpha: 0.9),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: kdefgreyColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        image: const DecorationImage(
                          image: NetworkImage(
                              'https://i.postimg.cc/SsWYSvq6/noimage.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(itemName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Get.textTheme.titleSmall),
                        const SizedBox(height: 6),
                        Text(
                          "Quantity: $quantity pcs",
                          style: const TextStyle(
                              color: kmediumblackColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(double.tryParse(price) ?? 0.0).toStringAsFixed(2)} AED',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kPrimaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.padded,
                foregroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(60),
                  side: const BorderSide(color: kPrimaryColor),
                ),
              ),
              child: const Text('Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                String? userId = prefs.getString('userId')?.toString();
                // Remove and force rebuild so list reflects the change immediately
                cartNotifier.removeItemInfo(itemName, userId);
                setState(() {}); // ADD: rebuild Cart screen
                Navigator.of(dialogContext)
                    .pop(true); // let Dismissible animate
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.padded,
                backgroundColor: kPrimaryColor,
                foregroundColor: kdefwhiteColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(60)),
              ),
              child: const Text('Yes, Remove',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}

// NEW: pure confirmation dialog for Dismissible (does NOT remove)
Future<bool?> _confirmRemoveDialog(
  BuildContext context,
  String itemName,
  String image,
  String price,
  String quantity,
) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove from Cart?',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
        ),
        // content mirrors _showRemoveDialog's summary UI
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedNetworkImage(
                  imageUrl: image,
                  // ...same builder/placeholder/error as _showRemoveDialog...
                  imageBuilder: (context, imageProvider) => Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: kPrimaryColor.withValues(alpha: 0.9),
                      image: DecorationImage(
                          image: imageProvider, fit: BoxFit.contain),
                    ),
                  ),
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                          color: kdefgreyColor,
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      image: const DecorationImage(
                        image: NetworkImage(
                            'https://i.postimg.cc/SsWYSvq6/noimage.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(itemName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Get.textTheme.titleSmall),
                      const SizedBox(height: 6),
                      Text("Quantity: $quantity pcs",
                          style: const TextStyle(
                              color: kmediumblackColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text(
                          '${(double.tryParse(price) ?? 0.0).toStringAsFixed(2)} AED',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kPrimaryColor)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(0, 44),
              tapTargetSize: MaterialTapTargetSize.padded,
              foregroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(60),
                side: const BorderSide(color: kPrimaryColor),
              ),
            ),
            child: const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              minimumSize: const Size(0, 44),
              tapTargetSize: MaterialTapTargetSize.padded,
              backgroundColor: kPrimaryColor,
              foregroundColor: kdefwhiteColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(60)),
            ),
            child: const Text('Yes, Remove',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      );
    },
  );
}

Future<bool?> showGuestDiscountWarning(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: kredColor),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Discount not available',
                style: TextStyle(
                  color: kredColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'If you place the order as a guest, the app registration discount will not be applied. Please register or log in to get the discount.',
          style: TextStyle(
            color: kSecondaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              foregroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: kPrimaryColor),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: kredColor,
              foregroundColor: kdefwhiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Continue as Guest',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}

class CartItemWidget extends StatefulWidget {
  final CartOtherInfo cartItem;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.cartItem,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  @override
  Widget build(BuildContext context) {
    String formattedDate = widget.cartItem.addedToCartTime != null
        ? DateFormat('MMM dd, yyyy h:mm a')
            .format(widget.cartItem.addedToCartTime!)
        : 'No Date';
    return Padding(
      padding: defaultPadding(),
      child: defaultStyledContainer(
        backgroundColor: kdefgreyColor,
        child: Column(
          children: [
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl: widget.cartItem.productImage?.isNotEmpty ?? false
                      ? ImageHelper.getUrl(
                          widget.cartItem.productImage.toString())
                      : "https://i.postimg.cc/SsWYSvq6/noimage.png",
                  imageBuilder: (context, imageProvider) => Container(
                    padding: const EdgeInsets.all(5),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: kdefwhiteColor,
                      boxShadow: defaultBoxShadow,
                      borderRadius: BorderRadius.circular(6),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: kdefgreyColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      image: const DecorationImage(
                        image: NetworkImage(
                            'https://i.postimg.cc/SsWYSvq6/noimage.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                10.0.widthbox,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(
                            widget.cartItem.productName ?? 'Unknown Product',
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: kSecondaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )),
                          GestureDetector(
                            onTap: widget.onRemove,
                            child: const Icon(Icons.delete,
                                size: 20, color: kredColor),
                          ),
                        ],
                      ),
                      5.0.heightbox,
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${(widget.cartItem.cartBasePrice * (widget.cartItem.quantity ?? 0)).toStringAsFixed(2)} AED",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: kredColor,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: widget.onDecrease,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: kPrimaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.remove,
                                      size: 15, color: kSecondaryColor),
                                ),
                              ),
                              5.0.widthbox,
                              Text(
                                widget.cartItem.quantity?.toString() ?? '0',
                                style: const TextStyle(
                                    color: kSecondaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                              5.0.widthbox,
                              GestureDetector(
                                onTap: widget.onIncrease,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: kPrimaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 15,
                                    color: kSecondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            10.0.heightbox,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Dated: $formattedDate",
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Quantity: ${widget.cartItem.quantity?.toString() ?? '0'} pcs",
                  style: const TextStyle(
                    color: kSecondaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showCheckoutDialog(BuildContext context) {
  final rootContext = context;
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
              decoration: BoxDecoration(
                color: kdefwhiteColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _discountBrandColor.withValues(alpha: .14),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 76,
                    width: 76,
                    decoration: const BoxDecoration(
                      color: _discountSoftBrandColor,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/images/gift_image.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _discountSoftGold,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            color: _discountGold, size: 16),
                        SizedBox(width: 5),
                        Text(
                          'WELCOME NEW USERS!',
                          style: TextStyle(
                            color: _discountGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'New User Discount',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _discountBrandColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const Text(
                    'Available!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _discountGold,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Register or log in to unlock your exclusive new user discount and enjoy special offers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kSecondaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: kdefwhiteColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE7ECF6)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: _CheckoutBenefitItem(
                            icon: Icons.local_offer_rounded,
                            title: 'Discount',
                            subtitle: 'First order',
                          ),
                        ),
                        _CheckoutBenefitDivider(),
                        Expanded(
                          child: _CheckoutBenefitItem(
                            icon: Icons.redeem_rounded,
                            title: 'Offers',
                            subtitle: 'Member deals',
                          ),
                        ),
                        _CheckoutBenefitDivider(),
                        Expanded(
                          child: _CheckoutBenefitItem(
                            icon: Icons.speed_rounded,
                            title: 'Fast',
                            subtitle: 'Checkout',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CheckoutActionButton(
                    label: 'Login',
                    icon: Icons.login_rounded,
                    backgroundColor: _discountBrandColor,
                    foregroundColor: kdefwhiteColor,
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      rootContext.route(Login());
                    },
                  ),
                  const SizedBox(height: 10),
                  _CheckoutActionButton(
                    label: 'Register',
                    icon: Icons.person_add_alt_1_rounded,
                    backgroundColor: _discountBrandColor,
                    foregroundColor: kdefwhiteColor,
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      rootContext.route(SignUp());
                    },
                  ),
                  const SizedBox(height: 10),
                  _CheckoutActionButton(
                    label: 'Continue as Guest',
                    icon: Icons.person_outline_rounded,
                    backgroundColor: kdefwhiteColor,
                    foregroundColor: _discountBrandColor,
                    borderColor: _discountBrandColor,
                    onTap: () async {
                      Navigator.of(dialogContext).pop();
                      await clearGuestCheckoutData();

                      final auth = Get.find<AuthController>();
                      auth.isGuest.value = true;
                      if (Get.isRegistered<FirstUserDiscountController>()) {
                        Get.find<FirstUserDiscountController>().clearAll();
                      }

                      Get.to(() => CheckoutStepper(isforguest: true));
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: _discountSoftGold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: _discountGold, size: 19),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Continue as Guest, you will lose your New User Discount.',
                            style: TextStyle(
                              color: kSecondaryColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -12,
              right: -8,
              child: Material(
                color: kdefwhiteColor,
                shape: const CircleBorder(),
                elevation: 5,
                shadowColor: _discountBrandColor,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.close_rounded,
                      color: kSecondaryColor,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _CheckoutActionButton extends StatelessWidget {
  const _CheckoutActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.borderColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor ?? backgroundColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foregroundColor, size: 21),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  color: foregroundColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutBenefitItem extends StatelessWidget {
  const _CheckoutBenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: const BoxDecoration(
            color: _discountSoftBrandColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _discountBrandColor, size: 21),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _discountBrandColor,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: kSecondaryColor,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CheckoutBenefitDivider extends StatelessWidget {
  const _CheckoutBenefitDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFE7ECF6),
    );
  }
}
