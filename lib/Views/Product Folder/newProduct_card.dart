// import 'package:custom_rating_bar/custom_rating_bar.dart';

import 'package:get/get.dart';
import 'package:graba2z/Api/Models/newProductModel.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Controllers/favController.dart';
import 'package:graba2z/Controllers/first_user_discount_controller.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Utils/image_helper.dart';
import 'package:graba2z/Utils/price_formatter.dart';
import 'package:graba2z/Views/Product%20Folder/newProductDetails.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg; // added
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:graba2z/Controllers/review_update_bus.dart';

import '../../Utils/packages.dart';

// Add: small white shopping bag SVG for the button
const String _bagSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-shopping-bag">
  <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z"></path>
  <path d="M3 6h18"></path>
  <path d="M16 10a4 4 0 0 1-8 0"></path>
</svg>
''';

class NewProductCard extends StatefulWidget {
  final prdouctList;
  final maxLines;
  final VoidCallback? onAddedToCart;
  final bool showFavoriteIcon; // allow hiding fav icon when embedding

  NewProductCard({
    super.key,
    required this.prdouctList,
    this.maxLines = 1,
    this.onAddedToCart,
    this.showFavoriteIcon = true,
  });

  @override
  State<NewProductCard> createState() => _NewProductCardState();
}

class _NewProductCardState extends State<NewProductCard> {
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  bool _hasPositivePrice(dynamic v) => _toDouble(v) > 0;

  String _formatPrice(dynamic v) {
    if (v == null || v.toString().trim().isEmpty) return 'N/A';
    final price = double.tryParse(v.toString());
    // Display-only conversion: AED -> selected country currency.
    return price == null ? v.toString() : formatPriceForSelected(price);
  }

  String _detailsPrice(dynamic v) {
    final price = double.tryParse(v?.toString() ?? '');
    return price == null ? '0' : price.toStringAsFixed(2);
  }

  double _avgRatingFromMap(Map m) {
    // Prefer explicit average fields if provided
    if (m.containsKey('averageRating')) return _toDouble(m['averageRating']);
    if (m.containsKey('rating')) return _toDouble(m['rating']);
    // Fallback: compute from reviews list
    final revs = m['reviews'];
    if (revs is List && revs.isNotEmpty) {
      double sum = 0;
      int cnt = 0;
      for (final r in revs) {
        if (r is Map && r['rating'] != null) {
          sum += _toDouble(r['rating']);
          cnt++;
        }
      }
      if (cnt > 0) return sum / cnt;
    }
    return 0.0;
  }

  int _reviewsCountFromMap(Map m) {
    final revs = m['reviews'];
    if (revs is List) return revs.length;
    if (m['reviewsCount'] is num) return (m['reviewsCount'] as num).toInt();
    return 0;
  }

  Widget _buildStars(double avg, {double size = 20}) {
    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      final threshold = i + 1;
      if (avg >= threshold) {
        stars.add(Icon(Icons.star, color: Colors.amber, size: size));
      } else if (avg > i && avg < threshold) {
        stars.add(Icon(Icons.star_half, color: Colors.amber, size: size));
      } else {
        stars.add(Icon(Icons.star_border, color: Colors.amber, size: size));
      }
    }
    return Row(children: stars);
  }

  ProductCardDeal _firstUserDeal() {
    if (!Get.isRegistered<FirstUserDiscountController>()) {
      // Controller not loaded yet — still show badge, no price cut
      return const ProductCardDeal(showBadge: true, showPriceCut: false);
    }
    return Get.find<FirstUserDiscountController>()
        .getProductCardDeal(widget.prdouctList);
  }

  // --- Added: API-driven review stats for this product
  double? _apiAvgRating;
  int? _apiReviewsCount;
  bool _loadingStats = false;
  String? _productId; // track this card's product id
  StreamSubscription<String>? _reviewUpdateSub;

  @override
  void initState() {
    super.initState();
    // Resolve productId
    if (widget.prdouctList is Map) {
      final map = Map<String, dynamic>.from(widget.prdouctList);
      _productId = (map['_id'] ?? '').toString();
    }
    _fetchReviewStats(); // initial fetch

    // Listen for global "reviews updated" events
    _reviewUpdateSub = ReviewUpdateBus.instance.stream.listen((pid) {
      if (!mounted) return;
      if (_productId != null && _productId!.isNotEmpty && pid == _productId) {
        _fetchReviewStats();
      }
    });
  }

  @override
  void didUpdateWidget(covariant NewProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update productId if card is rebuilt with a different product
    if (widget.prdouctList is Map) {
      final map = Map<String, dynamic>.from(widget.prdouctList);
      final newId = (map['_id'] ?? '').toString();
      if (newId != _productId) {
        _productId = newId;
        _fetchReviewStats();
      }
    }
  }

  @override
  void dispose() {
    _reviewUpdateSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchReviewStats() async {
    try {
      if (widget.prdouctList is! Map) return;
      final map = Map<String, dynamic>.from(widget.prdouctList);
      final String productId = (map['_id'] ?? '').toString();
      if (productId.isEmpty) return;

      setState(() => _loadingStats = true);
      final endpoint = Configss.getReview.replaceFirst(':productId', productId);
      final url = '$endpoint?page=1';
      final res = await http.get(Uri.parse(url));
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final stats = (data['stats'] is Map)
            ? Map<String, dynamic>.from(data['stats'])
            : null;
        setState(() {
          _apiAvgRating = (stats?['averageRating'] is num)
              ? (stats!['averageRating'] as num).toDouble()
              : null;
          _apiReviewsCount = (stats?['totalReviews'] is num)
              ? (stats!['totalReviews'] as num).toInt()
              : null;
        });
      }
    } catch (_) {
      // swallow; fallback to local data
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  void _showFavPopup({required bool added}) {
    showGeneralDialog(
      context: context,
      barrierLabel: added ? 'product_wishlist_added'.tr : 'product_wishlist_removed'.tr,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final scale = Curves.easeOutBack.transform(anim.value);
        return Center(
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(40)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    added ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    added ? 'product_wishlist_added'.tr : 'product_wishlist_removed'.tr,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    Future.delayed(const Duration(milliseconds: 900), () {
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) nav.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    const placeholderImage = 'https://i.postimg.cc/SsWYSvq6/noimage.png';

    if (widget.prdouctList == null) {
      print("Error in NewProductCard build: widget.prdouctList is null.");
      return SizedBox.shrink();
    }

    String? imageUrlToDisplay;
    dynamic galleryImages;
    dynamic mainImage;

    if (widget.prdouctList is Map) {
      galleryImages = widget.prdouctList['galleryImages'];
      mainImage = widget.prdouctList['image'];
    } else {
      print(
          "NewProductCard build: widget.prdouctList is not a Map, using placeholder image.");
      imageUrlToDisplay = placeholderImage;
    }

    if (imageUrlToDisplay == null) {
      if (mainImage != null && mainImage.toString().isNotEmpty) {
        imageUrlToDisplay = mainImage.toString();
      } else if (galleryImages != null &&
          galleryImages is List &&
          galleryImages.isNotEmpty &&
          galleryImages[0] != null &&
          galleryImages[0].toString().isNotEmpty) {
        imageUrlToDisplay = galleryImages[0].toString();
      } else {
        imageUrlToDisplay = placeholderImage;
      }
    }

    // Extract subcategory name for display under product name (fallbacks to category/parentCategory)
    String subcategoryNameForCard = '';
    if (widget.prdouctList is Map) {
      final map = widget.prdouctList as Map;
      // Common API keys variations
      final sc1 = map['subcategory'];
      final sc2 = map['subCategory'];
      final sc3 = map['childCategory']; // optional extra fallback if exists
      Map? sc;
      if (sc1 is Map)
        sc = sc1;
      else if (sc2 is Map)
        sc = sc2;
      else if (sc3 is Map) sc = sc3;

      if (sc != null && (sc['name']?.toString().isNotEmpty ?? false)) {
        subcategoryNameForCard = sc['name'].toString();
      } else {
        // Fallbacks to keep UI populated if subcategory is missing
        final cat = map['category'];
        if (cat is Map && (cat['name']?.toString().isNotEmpty ?? false)) {
          subcategoryNameForCard = cat['name'].toString();
        } else {
          final pc = map['parentCategory'];
          if (pc is Map && (pc['name']?.toString().isNotEmpty ?? false)) {
            subcategoryNameForCard = pc['name'].toString();
          }
        }
      }
    }

    // Define the onTap logic once to avoid duplication
    void navigateToDetails() {
      if (widget.prdouctList == null || widget.prdouctList is! Map) {
        print(
            'NewProductCard.onTap: Error - productList is null or not a Map. Cannot navigate.');
        return;
      }
      var productData = widget.prdouctList as Map;

      final rawOfferPrice = productData['offerPrice'];
      final rawPrice = productData['price'];

      List<String> imagesForDetails = ImageHelper.extractProductImages(productData);

      List<dynamic> specsForDetails = [];
      final rawSpecs = productData['specifications'];
      if (rawSpecs is List) {
        try {
          specsForDetails = List<dynamic>.from(rawSpecs);
        } catch (e) {
          print(
              'NewProductCard.onTap: ERROR converting specifications to List<dynamic>: $e');
        }
      }

      List<dynamic> reviewsForDetails = [];
      final rawReviews = productData['reviews'];
      if (rawReviews is List) {
        try {
          reviewsForDetails = List<dynamic>.from(rawReviews);
        } catch (e) {
          print(
              'NewProductCard.onTap: ERROR converting reviews to List<dynamic>: $e');
        }
      }

      String productId = productData['_id']?.toString() ?? '';
      String name =
          productData['name']?.toString() ?? 'Product Name Not Available';

      dynamic brandData = productData['brand'];
      String brandName = '';
      if (brandData is Map) {
        brandName = brandData['name']?.toString() ?? '';
      }

      dynamic parentCategoryData = productData['parentCategory'];
      String categoryName = '';
      String categoryId = '';
      if (parentCategoryData is Map) {
        categoryName = parentCategoryData['name']?.toString() ?? '';
        categoryId = parentCategoryData['_id']?.toString() ?? '';
      }

      // NEW: Extract subcategory name
      String subcategoryName = '';
      final sc1 = productData['subcategory'];
      final sc2 = productData['subCategory'];
      final sc3 = productData['childCategory'];
      Map? sc;
      if (sc1 is Map)
        sc = sc1;
      else if (sc2 is Map)
        sc = sc2;
      else if (sc3 is Map) sc = sc3;

      if (sc != null && (sc['name']?.toString().isNotEmpty ?? false)) {
        subcategoryName = sc['name'].toString();
      } else {
        // Fallback to category if subcategory not found
        final cat = productData['category'];
        if (cat is Map && (cat['name']?.toString().isNotEmpty ?? false)) {
          subcategoryName = cat['name'].toString();
        }
      }

      String sku = productData['sku']?.toString() ?? '';
      String stockStatus = productData['stockStatus']?.toString() ?? 'Unknown';
      String stockCount = (productData['stock'] ??
              productData['countInStock'] ??
              productData['stockCount'] ??
              productData['quantity'] ??
              '')
          .toString();
      String description = productData['description']?.toString() ?? '';
      String shortdesc = productData['shortDescription']?.toString() ?? '';
      List<dynamic> colorVariations = productData['colorVariations'] is List
          ? List<dynamic>.from(productData['colorVariations'])
          : [];
      List<dynamic> variations = productData['variations'] is List
          ? List<dynamic>.from(productData['variations'])
          : [];
      List<dynamic> availableModels = productData['availableModels'] is List
          ? List<dynamic>.from(productData['availableModels'])
          : [];

      try {
        Get.to(() {
          try {
            return NewProductDetails(
              specs: specsForDetails,
              reviews: reviewsForDetails,
              images: imagesForDetails,
              productId: productId,
              name: name,
              brandName: brandName,
              categoryName: categoryName,
              categoryId: categoryId,
              sku: sku,
              offerPrice: _detailsPrice(rawOfferPrice),
              price: _detailsPrice(rawPrice),
              stockStatus: stockStatus,
              stockCount: stockCount,
              description: description,
              shortdesc: shortdesc,
              subcategoryName: subcategoryName, // NEW: Pass subcategory
              colorVariations: colorVariations,
              variations: variations,
              availableModels: availableModels,
            );
          } catch (e, s) {
            print(
                'NewProductCard.onTap: CATCH within Get.to lambda - ERROR INSTANTIATING NewProductDetails: $e');
            print(
                'NewProductCard.onTap: Stacktrace for NewProductDetails instantiation error: $s');
            return const SizedBox.shrink(); // Fallback UI
          }
        }, preventDuplicates: false);
      } catch (e, s) {
        print(
            'NewProductCard.onTap: CATCH in outer try block - EXCEPTION DURING Get.to or its setup: $e');
        print(
            'NewProductCard.onTap: Stacktrace for outer Get.to exception: $s');
      }
    }

    return Stack(
      children: [
        GestureDetector(
          // WRAPPER FOR THE ENTIRE CARD CONTENT
          onTap: navigateToDetails, // Use the extracted onTap logic
          child: SizedBox.expand(
            // ensure card fills the exact slot (matches shimmer)
            child: defaultStyledContainer(
              padding: const EdgeInsets.all(6.0),
              // Fill available width from Grid/Horizontal item
              width: double.infinity,
              boxShadow: defaultBoxShadow,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Make content adapt to available height to avoid tiny overflows
                  final maxH = constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : 220.0;
                  // Slightly smaller image on tighter cards
                  final double _imgScale =
                      maxH < 190 ? 0.38 : (maxH < 210 ? 0.40 : 0.42);
                  final imgSize = (maxH * _imgScale).clamp(90.0, 120.0);
                  final gapBelowImage = 6.0; // was 8.0
                  final gapBelowChip = 4.0; // was 6.0
                  final gapTiny = 2.0;
                  final urlForImage =
                      ImageHelper.getUrl(imageUrlToDisplay ?? placeholderImage);
                  final addToCartH =
                      26.0; // shave a bit to prevent 5px overflow
                  return Column(
                    children: [
                      // Image

                      CachedNetworkImage(
                        imageUrl: urlForImage,
                        imageBuilder: (context, imageProvider) => Container(
                          height: imgSize.toDouble(),
                          width: imgSize.toDouble(),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            image: DecorationImage(
                                image: imageProvider, fit: BoxFit.contain),
                          ),
                        ),
                        placeholder: (context, url) => SizedBox(
                          height: imgSize.toDouble(),
                          width: imgSize.toDouble(),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: imgSize.toDouble(),
                          width: imgSize.toDouble(),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/noimage.png'),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      gapBelowImage.heightbox,
                      // Stock status chip
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Builder(
                          builder: (_) {
                            final status = (widget.prdouctList is Map
                                    ? widget.prdouctList['stockStatus']
                                        ?.toString()
                                    : null) ??
                                'Unknown';
                            final s = status.toLowerCase();
                            final Color bg = (s == 'out of stock')
                                ? kredColor
                                : (s == 'preorder' || s == 'pre order')
                                    ? Colors.orange
                                    : (s == 'available product' ||
                                            s == 'available' ||
                                            s == 'in stock')
                                        ? kdefgreenColor
                                        : kSecondaryColor;
                            return Obx(() {
                              final deal = _firstUserDeal();
                              return Row(
                                children: [
                                  Flexible(
                                    flex: deal.showBadge ? 5 : 1,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: bg,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: Text(
                                        status,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: kdefwhiteColor,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  if (deal.showBadge)
                                    Flexible(
                                      flex: 6,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 5),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: kPrimaryColor),
                                          ),
                                          child: Text(
                                            deal.badgeText,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF166534),
                                              fontSize: 7,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            });
                          },
                        ),
                      ),
                      gapBelowChip.heightbox,
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top info block (flexible to avoid overflow)
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (widget.prdouctList is Map
                                            ? widget.prdouctList['name']
                                                ?.toString()
                                            : null) ??
                                        'product_name_fallback'.tr,
                                    maxLines: widget.maxLines,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: kSecondaryColor,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (subcategoryNameForCard.isNotEmpty) ...[
                                    gapTiny.heightbox,
                                    Text(
                                      'product_card_category'.trParams({'category': subcategoryNameForCard}),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFFCA8A04), // #ca8a04
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  gapTiny.heightbox,
                                  Builder(builder: (_) {
                                    final hasOffer = widget.prdouctList
                                            is Map &&
                                        _hasPositivePrice(
                                            widget.prdouctList['offerPrice']);
                                    final currentPrice = hasOffer
                                        ? _formatPrice(
                                            widget.prdouctList['offerPrice'])
                                        : _formatPrice(widget.prdouctList is Map
                                            ? widget.prdouctList['price']
                                            : null);
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'product_card_inclusive_vat'.tr,
                                                style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF16A34A)),
                                              ),
                                              TextSpan(
                                                text: currentPrice,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: kredColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (hasOffer)
                                          Text(
                                            "${_formatPrice(widget.prdouctList is Map ? widget.prdouctList['price'] : null)}",
                                            style: const TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: kSecondaryColor,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              decorationColor: kredColor,
                                            ),
                                          ),
                                      ],
                                    );
                                  }),
                                  // Rating stars + count
                                  Padding(
                                    padding: EdgeInsets.only(top: gapTiny),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        () {
                                          double baseAvg = 0;
                                          int baseCount = 0;
                                          if (widget.prdouctList is Map) {
                                            final map =
                                                widget.prdouctList as Map;
                                            baseAvg = _avgRatingFromMap(map);
                                            baseCount =
                                                _reviewsCountFromMap(map);
                                          }
                                          final double avg =
                                              _apiAvgRating ?? baseAvg;
                                          final int count =
                                              _apiReviewsCount ?? baseCount;

                                          return Row(
                                            children: [
                                              _buildStars(avg, size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                '(${count.toString()})',
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: klightblackColor),
                                              ),
                                            ],
                                          );
                                        }(),
                                      ],
                                    ),
                                  ),
                                  (((widget.prdouctList is Map
                                                  ? widget.prdouctList[
                                                          'stockStatus']
                                                      ?.toString()
                                                  : null) ==
                                              'Out of Stock')
                                          ? 6.0
                                          : 2.0)
                                      .heightbox,
                                  if ((widget.prdouctList is Map
                                          ? widget.prdouctList['stockStatus']
                                              ?.toString()
                                          : null) ==
                                      'Out of Stock')
                                    Center(
                                      child: GestureDetector(
                                        onTap: () {
                                          // ...existing WhatsApp code...
                                        },
                                        child: Text(
                                          'product_card_check_availability'.tr,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: kPrimaryColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Bottom: Add to cart button
                            Center(
                              child: GetBuilder<CartNotifier>(builder: (cart) {
                                bool isOutOfStock = (widget.prdouctList is Map
                                        ? widget.prdouctList['stockStatus']
                                            ?.toString()
                                        : null) ==
                                    'Out of Stock';
                                return GestureDetector(
                                  onTap: () async {
                                    if (isOutOfStock) return;
                                    try {
                                      // Resolve minimal product info
                                      final map = (widget.prdouctList is Map)
                                          ? Map<String, dynamic>.from(
                                              widget.prdouctList)
                                          : <String, dynamic>{};
                                      final String productId =
                                          (map['_id'] ?? '').toString();
                                      final String productName =
                                          (map['name'] ?? 'Unknown Product')
                                              .toString();

                                      // Price: prefer offerPrice if > 0
                                      final double offerP =
                                          _toDouble(map['offerPrice']);
                                      final double regularP =
                                          _toDouble(map['price']);
                                      final double finalPrice =
                                          offerP > 0 ? offerP : regularP;

                                      if (finalPrice <= 0) {
                                        Get.snackbar('product_card_info'.tr,
                                            'product_card_price_unavailable'.tr);
                                        return;
                                      }

                                      // Image: main image -> first gallery -> placeholder
                                      const placeholderImage =
                                          'https://i.postimg.cc/SsWYSvq6/noimage.png';
                                      String productImageForCart =
                                          placeholderImage;
                                      final mainImage =
                                          map['image']?.toString();
                                      final gallery = map['galleryImages'];
                                      if (mainImage != null &&
                                          mainImage.isNotEmpty) {
                                        productImageForCart = mainImage;
                                      } else if (gallery is List &&
                                          gallery.isNotEmpty &&
                                          (gallery.first
                                                  ?.toString()
                                                  .isNotEmpty ??
                                              false)) {
                                        productImageForCart =
                                            gallery.first.toString();
                                      }

                                      // Optional userId
                                      String? userId;
                                      try {
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        userId = prefs
                                            .getString('userId')
                                            ?.toString();
                                      } catch (_) {}

                                      // Add to cart
                                      cart.addItemInfo(
                                        CartOtherInfo(
                                          productId: productId,
                                          productName: productName,
                                          productImage: productImageForCart,
                                          productPrice: finalPrice,
                                          originalPrice: regularP > finalPrice
                                              ? regularP
                                              : finalPrice,
                                          quantity: 1,
                                        ),
                                        userId,
                                      );

                                      // Feedback
                                      widget.onAddedToCart?.call();
                                    } catch (e) {
                                      Get.snackbar('product_error_title'.tr,
                                          'product_add_to_cart_failed'.tr);
                                    }
                                  },
                                  child: isOutOfStock
                                      ? const SizedBox.shrink()
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 1),
                                          width: Get.width / 2.8,
                                          height: addToCartH,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            color: kPrimaryColor,
                                          ),
                                          child: Center(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                svg.SvgPicture.string(
                                                  _bagSvg,
                                                  width: 12,
                                                  height: 12,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'product_add_to_cart'.tr,
                                                  style: TextStyle(
                                                    color: kdefblackColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.fade,
                                                  softWrap: false,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        if (widget.prdouctList is Map &&
            widget.prdouctList['discount'] != null &&
            widget.prdouctList['discount'] != 0)
          Positioned(
            top: 6,
            left: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              decoration: BoxDecoration(
                color: Colors
                    .white, // Consider defining this color in your constants
              ),
              child: Text(
                'product_card_discount_off'.trParams({'discount': widget.prdouctList['discount'].toString()}),
                style: const TextStyle(
                  color: kSecondaryColor,
                  fontSize: 6,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Optional favorite icon overlay (can be hidden by parent)
        if (widget.showFavoriteIcon)
          GetBuilder<FavoriteController>(
            builder: (favorite) {
              final productData = widget.prdouctList;
              if (productData == null) {
                return SizedBox.shrink();
              }

              Newproductmodel model;
              try {
                if (productData is Newproductmodel) {
                  model = productData;
                } else if (productData is Map<String, dynamic>) {
                  model = Newproductmodel.fromJson(productData);
                } else if (productData is Map) {
                  model = Newproductmodel.fromJson(
                      Map<String, dynamic>.from(productData));
                } else {
                  print(
                      "FavoriteController: Cannot convert productData to Newproductmodel. Type: ${productData.runtimeType}");
                  return SizedBox.shrink();
                }
              } catch (e) {
                print(
                    "FavoriteController: Error converting to Newproductmodel: $e");
                return SizedBox.shrink();
              }

              return Positioned(
                top: 9,
                right: 9,
                child: GestureDetector(
                  onTap: () async {
                    final authController = Get.find<AuthController>();
                    if (!authController.userID.value.isNotEmpty) {
                      // Navigate to login screen if user is not logged in
                      context.route(Login());
                      return;
                    }

                    if (model.id != null && model.id!.isNotEmpty) {
                      final nowFav = await favorite
                          .toggleFavorite(model, context, silent: true);
                      _showFavPopup(added: nowFav);
                    } else {
                      print(
                          "FavoriteController: Cannot toggle favorite, model or model.id is not valid.");
                    }
                  },
                  child: Icon(
                    (model.id != null &&
                            model.id!.isNotEmpty &&
                            favorite.isExist(model))
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: (model.id != null &&
                            model.id!.isNotEmpty &&
                            favorite.isExist(model))
                        ? kredColor
                        : klightblackColor,
                    size: 20,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
