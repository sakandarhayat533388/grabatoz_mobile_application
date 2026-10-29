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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:developer' as developer;
import 'package:graba2z/Controllers/review_update_bus.dart';
import 'package:graba2z/Controllers/language_controller.dart';
import 'package:graba2z/Controllers/home_controller.dart';
import 'package:graba2z/Controllers/brand_controller.dart';
import '../../../../../../Utils/packages.dart';

// Add: small white shopping bag SVG for the button
const String _bagSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-shopping-bag">
  <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z"></path>
  <path d="M3 6h18"></path>
  <path d="M16 10a4 4 0 0 1-8 0"></path>
</svg>
''';

class DealsProductCard extends StatefulWidget {
  final productList;
  final maxLines;
  final String offerName;
  final VoidCallback? onAddedToCart;
  final bool showFavoriteIcon; // allow hiding fav icon when embedding

  DealsProductCard({
    super.key,
    required this.offerName,
    required this.productList,
    this.maxLines = 1,
    this.onAddedToCart,
    this.showFavoriteIcon = true,
  });

  @override
  State<DealsProductCard> createState() => _DealsProductCardState();
}

class _DealsProductCardState extends State<DealsProductCard> {
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  bool _hasPositivePrice(dynamic v) => _toDouble(v) > 0;

  String _formatPrice(dynamic v) {
    if (v == null || v.toString().trim().isEmpty) return 'N/A';
    final price = double.tryParse(v.toString());
    return price == null ? v.toString() : price.toStringAsFixed(2);
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
      return ProductCardDeal.none;
    }
    return Get.find<FirstUserDiscountController>()
        .getProductCardDeal(widget.productList);
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
    if (widget.productList is Map) {
      final map = Map<String, dynamic>.from(widget.productList);
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
  void didUpdateWidget(covariant DealsProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update productId if card is rebuilt with a different product
    if (widget.productList is Map) {
      final map = Map<String, dynamic>.from(widget.productList);
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
      if (widget.productList is! Map) return;
      final map = Map<String, dynamic>.from(widget.productList);
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

  Color _getOfferLabelColor() {
    // مختلف colors کی list
    final colors = [
      // const Color(0xFFFEE2E2),
      // const Color(0xFFDCFCE7),
      // const Color(0xFFECFCCB),
      const Color(0xFFFFD900),
      // const Color(0xFFF37021),
      // const Color(0xFFDBB27C),
      // const Color(0xFFFF4500),
    ];

    // Product ID کی بنیاد پر ہیش کریں تاکہ ہر product کو مختلف رنگ ملے
    if (widget.productList is Map) {
      final productId = widget.productList['_id']?.toString() ?? '';
      final hash = productId.hashCode.abs();
      return colors[hash % colors.length];
    }
    return colors[0];
  }

  void _showFavPopup({required bool added}) {
    showGeneralDialog(
      context: context,
      barrierLabel: added ? 'deals_added_to_wishlist'.tr : 'deals_removed_from_wishlist'.tr,
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
                    added ? 'deals_added_to_wishlist'.tr : 'deals_removed_from_wishlist'.tr,
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

  // @override
  // void dispose() {
  //   _reviewUpdateSub?.cancel();
  //   super.dispose();
  // }

  void navigateToDetails() {
    try {
      if (widget.productList == null || widget.productList is! Map) {
        print(
            'DealsProductCard.onTap: Error - productList is null or not a Map.');
        return;
      }
      var productData = widget.productList as Map;

      // Extract images
      final rawOfferPrice = productData['offerPrice'];
      final rawPrice = productData['price'];

      List<String> imagesForDetails = ImageHelper.extractProductImages(productData);

      // Extract specs
      List<dynamic> specsForDetails = [];
      final rawSpecs = productData['specifications'];
      if (rawSpecs is List) {
        try {
          specsForDetails = List<dynamic>.from(rawSpecs);
        } catch (e) {
          print('DealsProductCard.onTap: ERROR converting specs: $e');
        }
      }

      // Extract reviews
      List<dynamic> reviewsForDetails = [];
      final rawReviews = productData['reviews'];
      if (rawReviews is List) {
        try {
          reviewsForDetails = List<dynamic>.from(rawReviews);
        } catch (e) {
          print('DealsProductCard.onTap: ERROR converting reviews: $e');
        }
      }

      String productId = productData['_id']?.toString() ?? '';
      String name =
          productData['name']?.toString() ?? 'deals_product_name_missing'.tr;

      // Extract brand - already enriched by controller
      dynamic brandData = productData['brand'];
      String brandName = '';

      if (brandData is Map) {
        brandName =
            (brandData['name'] ?? brandData['_name'] ?? '').toString().trim();
      }

      developer.log("Brand for details: $brandName", name: "DealsProductCard");

      // Extract parent category
      dynamic parentCategoryData = productData['parentCategory'];
      String categoryName = '';
      String categoryId = '';
      if (parentCategoryData is Map) {
        categoryName = parentCategoryData['name']?.toString() ?? '';
        categoryId = parentCategoryData['_id']?.toString() ?? '';
      }

      // Extract subcategory
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
        Get.to(
          () {
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
                subcategoryName: subcategoryName,
                colorVariations: colorVariations,
                variations: variations,
                availableModels: availableModels,
              );
            } catch (e, s) {
              print(
                  'DealsProductCard.onTap: ERROR INSTANTIATING NewProductDetails: $e');
              print('Stacktrace: $s');
              return const SizedBox.shrink();
            }
          },
          preventDuplicates: false,
        );
      } catch (e, s) {
        print('DealsProductCard.onTap: EXCEPTION DURING Get.to: $e');
        print('Stacktrace: $s');
      }
    } catch (e, s) {
      print('DealsProductCard.onTap: OUTER ERROR: $e');
      print('Stacktrace: $s');
    }
  }

  @override
  Widget build(BuildContext context) {
    const placeholderImage = 'https://i.postimg.cc/SsWYSvq6/noimage.png';

    if (widget.productList == null) {
      print("Error in DealsProductCard build: widget.productList is null.");
      return SizedBox.shrink();
    }

    String imageUrlToDisplay = placeholderImage;
    dynamic galleryImages;
    dynamic mainImage;

    if (widget.productList is Map) {
      galleryImages = widget.productList['galleryImages'];
      mainImage = widget.productList['image'];

      // Set imageUrlToDisplay with proper null checks
      if (mainImage != null && mainImage.toString().isNotEmpty) {
        imageUrlToDisplay = mainImage.toString();
      } else if (galleryImages is List &&
          galleryImages.isNotEmpty &&
          galleryImages[0] != null &&
          galleryImages[0].toString().isNotEmpty) {
        imageUrlToDisplay = galleryImages[0].toString();
      }
    } else {
      print(
          "DealsProductCard build: widget.productList is not a Map, using placeholder image.");
    }

    // Extract subcategory and brand names for display
    String subcategoryNameForCard = '';
    String subcategoryNameArForCard = '';
    String brandNameForCard = '';
    String brandNameArForCard = '';
    String _catLookupId = '';
    String _brandLookupId = '';

    if (widget.productList is Map) {
      final map = widget.productList as Map;

      // Extract brand name
      final brand = map['brand'];
      if (brand is Map) {
        brandNameForCard =
            (brand['name'] ?? brand['_name'] ?? '').toString().trim();
        brandNameArForCard = (brand['nameAr'] ?? '').toString().trim();
        _brandLookupId =
            (brand['_id'] ?? brand['id'] ?? '').toString().trim();
      }

      // Common API keys variations for subcategory
      final sc1 = map['subcategory'];
      final sc2 = map['subCategory'];
      final sc3 = map['childCategory'];
      Map? sc;
      if (sc1 is Map)
        sc = sc1;
      else if (sc2 is Map)
        sc = sc2;
      else if (sc3 is Map) sc = sc3;

      if (sc != null && (sc['name']?.toString().isNotEmpty ?? false)) {
        subcategoryNameForCard = sc['name'].toString();
        subcategoryNameArForCard = sc['nameAr']?.toString() ?? '';
        _catLookupId = sc['_id']?.toString() ?? sc['id']?.toString() ?? '';
      } else {
        final cat = map['category'];
        if (cat is Map && (cat['name']?.toString().isNotEmpty ?? false)) {
          subcategoryNameForCard = cat['name'].toString();
          subcategoryNameArForCard = cat['nameAr']?.toString() ?? '';
          _catLookupId = cat['_id']?.toString() ?? cat['id']?.toString() ?? '';
        } else {
          final pc = map['parentCategory'];
          if (pc is Map && (pc['name']?.toString().isNotEmpty ?? false)) {
            subcategoryNameForCard = pc['name'].toString();
            subcategoryNameArForCard = pc['nameAr']?.toString() ?? '';
            _catLookupId = pc['_id']?.toString() ?? pc['id']?.toString() ?? '';
          }
        }
      }

      // Arabic lookups: embedded objects often lack nameAr, so resolve by ID
      final bool _isArExtract = Get.isRegistered<LanguageController>() &&
          Get.find<LanguageController>().isArabic;
      if (_isArExtract) {
        if (subcategoryNameArForCard.trim().isEmpty &&
            _catLookupId.isNotEmpty) {
          try {
            final hc = Get.find<HomeController>();
            for (final c in hc.category) {
              if (c.sId == _catLookupId &&
                  (c.nameAr?.trim().isNotEmpty ?? false)) {
                subcategoryNameArForCard = c.nameAr!;
                break;
              }
            }
            if (subcategoryNameArForCard.trim().isEmpty) {
              for (final s in hc.subcategory) {
                if (s.sId == _catLookupId &&
                    (s.nameAr?.trim().isNotEmpty ?? false)) {
                  subcategoryNameArForCard = s.nameAr!;
                  break;
                }
              }
            }
          } catch (_) {}
        }
        if (brandNameArForCard.trim().isEmpty && _brandLookupId.isNotEmpty) {
          try {
            if (Get.isRegistered<BrandController>()) {
              final bc = Get.find<BrandController>();
              for (final b in bc.brandList) {
                if (b is Map &&
                    (b['_id']?.toString() ?? '') == _brandLookupId &&
                    (b['nameAr']?.toString().trim().isNotEmpty ?? false)) {
                  brandNameArForCard = b['nameAr'].toString();
                  break;
                }
              }
            }
          } catch (_) {}
        }
      }
    }

    return SizedBox.expand(
      child: Stack(
        children: [
          GestureDetector(
            onTap: navigateToDetails,
            child: SizedBox.expand(
              child: defaultStyledContainer(
                padding: const EdgeInsets.all(6.0),
                width: double.infinity,
                boxShadow: defaultBoxShadow,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxH = constraints.maxHeight.isFinite
                        ? constraints.maxHeight
                        : 220.0;
                    final bool _isAr = Get.isRegistered<LanguageController>() &&
                        Get.find<LanguageController>().isArabic;
                    // Arabic text is taller: shrink image + spacing in Arabic
                    final double _imgScaleBase =
                        maxH < 190 ? 0.38 : (maxH < 210 ? 0.40 : 0.42);
                    final double _imgScale =
                        _isAr ? _imgScaleBase - 0.05 : _imgScaleBase;
                    final imgSize = (maxH * _imgScale).clamp(80.0, 120.0);
                    final gapBelowImage = _isAr ? 4.0 : 6.0;
                    final gapBelowChip = _isAr ? 3.0 : 4.0;
                    final gapTiny = _isAr ? 1.5 : 2.0;
                    final urlForImage = ImageHelper.getUrl(
                        imageUrlToDisplay ?? placeholderImage);
                    final addToCartH = _isAr ? 23.0 : 26.0;
                    return Column(
                      children: [
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Builder(
                            builder: (_) {
                              final status = (widget.productList is Map
                                      ? widget.productList['stockStatus']
                                          ?.toString()
                                      : null) ??
                                  'deals_unknown'.tr;
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
                              return Wrap(
                                spacing: 4,
                                runSpacing: 3,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                      status,
                                      style: const TextStyle(
                                          color: kdefwhiteColor,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (widget.productList is Map &&
                                      widget.productList['discount'] != null &&
                                      widget.productList['discount'] != 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: Color(0xFFFACC15),
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: Text(
                                        'deals_discount_badge'.trParams({
                                          'd': widget.productList['discount']
                                              .toString()
                                        }),
                                        style: const TextStyle(
                                            color: kdefwhiteColor,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  Obx(() {
                                    final deal = _firstUserDeal();
                                    if (!deal.showBadge) {
                                      return const SizedBox.shrink();
                                    }
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                        border:
                                            Border.all(color: kPrimaryColor),
                                      ),
                                      child: Text(
                                        deal.badgeText,
                                        style: const TextStyle(
                                          color: Color(0xFF166534),
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                        ),
                        gapBelowChip.heightbox,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (widget.productList is Map
                                              ? (_isAr &&
                                                      (widget.productList['nameAr']
                                                              ?.toString()
                                                              .trim()
                                                              .isNotEmpty ==
                                                          true)
                                                  ? widget.productList['nameAr']
                                                      ?.toString()
                                                  : widget.productList['name']
                                                      ?.toString())
                                              : null) ??
                                          'deals_product_name'.tr,
                                      maxLines: widget.maxLines,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: kSecondaryColor,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    // Brand name
                                    if (brandNameForCard.isNotEmpty) ...[
                                      gapTiny.heightbox,
                                      Text(
                                        '${'product_detail_brand_label'.tr} ${(_isAr && brandNameArForCard.trim().isNotEmpty) ? brandNameArForCard : brandNameForCard}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFF0EA5E9),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    // Category name
                                    if (subcategoryNameForCard.isNotEmpty) ...[
                                      gapTiny.heightbox,
                                      Text(
                                        '${'product_detail_category_label'.tr} ${(_isAr && subcategoryNameArForCard.trim().isNotEmpty) ? subcategoryNameArForCard : subcategoryNameForCard}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFFCA8A04),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    gapTiny.heightbox,
                                    Builder(builder: (_) {
                                      final hasOffer = widget.productList
                                              is Map &&
                                          _hasPositivePrice(
                                              widget.productList['offerPrice']);
                                      final currentPrice = hasOffer
                                          ? _formatPrice(
                                              widget.productList['offerPrice'])
                                          : _formatPrice(
                                              widget.productList is Map
                                                  ? widget.productList['price']
                                                  : null);
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: 'deals_inclusive_vat'.tr,
                                                  style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF16A34A)),
                                                ),
                                                TextSpan(
                                                  text: "$currentPrice AED",
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: themePriceColor()),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (hasOffer)
                                            Text(
                                              "AED ${_formatPrice(widget.productList is Map ? widget.productList['price'] : null)}",
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: themeOldPriceColor(),
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                decorationColor: kredColor,
                                              ),
                                            ),
                                        ],
                                      );
                                    }),
                                    Padding(
                                      padding: EdgeInsets.only(top: gapTiny),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          () {
                                            double baseAvg = 0;
                                            int baseCount = 0;
                                            if (widget.productList is Map) {
                                              final map =
                                                  widget.productList as Map;
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
                                    (((widget.productList is Map
                                                    ? widget.productList[
                                                            'stockStatus']
                                                        ?.toString()
                                                    : null) ==
                                                'Out of Stock')
                                            ? 6.0
                                            : 2.0)
                                        .heightbox,
                                    if ((widget.productList is Map
                                            ? widget.productList['stockStatus']
                                                ?.toString()
                                            : null) ==
                                        'Out of Stock')
                                      Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            // ...existing WhatsApp code...
                                          },
                                          child: Text(
                                            'deals_check_availability_btn'.tr,
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
                              Center(
                                child:
                                    GetBuilder<CartNotifier>(builder: (cart) {
                                  bool isOutOfStock = (widget.productList is Map
                                          ? widget.productList['stockStatus']
                                              ?.toString()
                                          : null) ==
                                      'Out of Stock';
                                  return GestureDetector(
                                    onTap: () async {
                                      if (isOutOfStock) return;
                                      try {
                                        final map = (widget.productList is Map)
                                            ? Map<String, dynamic>.from(
                                                widget.productList)
                                            : <String, dynamic>{};
                                        final String productId =
                                            (map['_id'] ?? '').toString();
                                        final String productName =
                                            (map['name'] ??
                                                    'deals_unknown_product'.tr)
                                                .toString();
                                        final String productNameAr =
                                            (map['nameAr'] ?? '').toString();

                                        final double offerP =
                                            _toDouble(map['offerPrice']);
                                        final double regularP =
                                            _toDouble(map['price']);
                                        final double finalPrice =
                                            offerP > 0 ? offerP : regularP;

                                        if (finalPrice <= 0) {
                                          Get.snackbar('deals_info_title'.tr,
                                              'deals_price_unavailable_msg'.tr);
                                          return;
                                        }

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

                                        String? userId;
                                        try {
                                          final prefs = await SharedPreferences
                                              .getInstance();
                                          userId = prefs
                                              .getString('userId')
                                              ?.toString();
                                        } catch (_) {}

                                        cart.addItemInfo(
                                          CartOtherInfo(
                                            productId: productId,
                                            productName: productName,
                                            productNameAr: productNameAr,
                                            productImage: productImageForCart,
                                            productPrice: finalPrice,
                                            originalPrice: regularP > finalPrice
                                                ? regularP
                                                : finalPrice,
                                            quantity: 1,
                                          ),
                                          userId,
                                        );

                                        widget.onAddedToCart?.call();
                                      } catch (e) {
                                        Get.snackbar('deals_error_title'.tr,
                                            'deals_add_cart_failed_msg'.tr);
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
                                                    'deals_add_to_cart_btn'.tr,
                                                    style: TextStyle(
                                                      color: kdefblackColor,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
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
          Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getOfferLabelColor(),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.offerName,
                  style: TextStyle(
                    color: kdefblackColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          // Favorite icon overlay
          if (widget.showFavoriteIcon)
            Positioned(
              top: 9,
              right: 9,
              child: GetBuilder<FavoriteController>(
                builder: (favorite) {
                  final productData = widget.productList;
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
                      return SizedBox.shrink();
                    }
                  } catch (e) {
                    return SizedBox.shrink();
                  }

                  return GestureDetector(
                    onTap: () async {
                      final authController = Get.find<AuthController>();
                      if (!authController.userID.value.isNotEmpty) {
                        context.route(Login());
                        return;
                      }

                      if (model.id != null && model.id!.isNotEmpty) {
                        final nowFav = await favorite
                            .toggleFavorite(model, context, silent: true);
                        _showFavPopup(added: nowFav);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ],
                      ),
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
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
