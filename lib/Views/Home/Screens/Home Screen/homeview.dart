import 'dart:convert';
import 'package:get/get.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Controllers/brand_controller.dart';
import 'package:graba2z/Controllers/homeSliderController.dart';
import 'package:graba2z/Controllers/home_controller.dart';
import 'package:graba2z/Controllers/language_controller.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Utils/image_helper.dart';
import 'package:graba2z/Views/Home/Screens/Deals%20Screen/dealsview.dart';
import 'package:graba2z/Views/Home/Screens/Search%20Screen/searchscreensecond.dart';
import 'package:graba2z/Views/Home/Screens/banner%20redirect/bannerredirect.dart';
import 'package:graba2z/Widgets/buildCategoryDrawer.dart';
import 'package:http/http.dart' as http;
import 'package:graba2z/Views/Categories%20Folder/allcategoriesscreen.dart';
import 'package:graba2z/Views/Home/Screens/Cart/cart.dart';
import 'package:graba2z/Views/Home/Screens/Home%20Screen/horizontal_scrolling_products.dart';
import 'package:graba2z/Views/Home/Screens/Shop%20Screen/Shop.dart';
import 'package:graba2z/Views/Product%20Folder/new_all_products.dart';
import 'package:graba2z/Views/Brand%20Folder/allbrandscreen.dart';
import 'package:graba2z/Views/Brand%20Folder/brandcard.dart';
import 'package:graba2z/Widgets/homecaresoule.dart';
import '../../../../Utils/packages.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Api/Models/category_slider_item.dart';
import 'package:graba2z/Controllers/dynamic_section_controller.dart';
import 'package:graba2z/Widgets/HomeSections/home_section_builder.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreenView extends StatefulWidget {
  const HomeScreenView({super.key});

  @override
  State<HomeScreenView> createState() => _HomeScreenViewState();
}

enum RedirectType { brand, category, none }

class _HomeScreenViewState extends State<HomeScreenView> {
  final HomeController _homeController = Get.put(HomeController());
  final BrandController _brandController = Get.put(BrandController());
  final DynamicSectionController _dynamicSectionController =
      Get.put(DynamicSectionController());
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _categoriesSectionKey = GlobalKey();
  final HomeSliderController _sliderController =
      Get.put(HomeSliderController());

  static const String _asusSectionBrandId = '687609800de49396755b8ffa';
  static const String _hpSectionBrandId = '687609800de49396755b8ffe';
  static const String _msiSectionBrandId = '687609810de49396755b9002';
  static const String _appleSectionBrandId = '6874de4381c33433c61f9bd4';
  static const String _lenovoSectionBrandId = '687609800de49396755b9000';
  static const String accessoriesCategoryId = '687659fcac482fc1560134d1';
  static const String networkingCategoryId = '68765a76ac482fc156013ad0';

  static const int homeScreenSectionFetchLimit = 20;
  static const int homeScreenSectionDisplayLimit = 5;

  final ScrollController _brandsScrollController = ScrollController();
  bool _brandsAutoLoopStarted = false;
  double _brandStepExtent = 0.0; // one-slot step
  double _brandLoopSpan = 0.0; // full cycle width
  bool _brandsCentered = false; // center only once

  @override
  void initState() {
    super.initState();
    _sliderController.homeCategorySlider();
    _homeController.fetchFeaturedProducts(
        fetchLimit: homeScreenSectionFetchLimit);
    _brandController.fetchProductsForBrand(_hpSectionBrandId,
        brandNameForLog: 'HP Home Section',
        fetchLimit: homeScreenSectionFetchLimit);
    _brandController.fetchProductsForBrand(_asusSectionBrandId,
        brandNameForLog: 'Asus Home Section',
        fetchLimit: homeScreenSectionFetchLimit);
    _brandController.fetchProductsForBrand(_msiSectionBrandId,
        brandNameForLog: 'MSI Home Section',
        fetchLimit: homeScreenSectionFetchLimit);
    _brandController.fetchProductsForBrand(_appleSectionBrandId,
        brandNameForLog: 'Apple Home Section',
        fetchLimit: homeScreenSectionFetchLimit);
    _brandController.fetchProductsForBrand(_lenovoSectionBrandId,
        brandNameForLog: 'Lenovo Home Section',
        fetchLimit: homeScreenSectionFetchLimit);

    _homeController.fetchProductsForCategory(accessoriesCategoryId,
        categoryNameForLog: 'Accessories Home Section',
        fetchLimit: homeScreenSectionFetchLimit);
    _homeController.fetchProductsForCategory(networkingCategoryId,
        categoryNameForLog: 'Networking Home Section',
        fetchLimit: homeScreenSectionFetchLimit);

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _startBrandsAutoScroll());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _brandsScrollController.dispose();
    super.dispose();
  }

  Map<String, String> detectRedirectType(String? redirectUrl) {
    if (redirectUrl == null || redirectUrl.isEmpty) {
      return {"type": "none"};
    }

    final uri = Uri.tryParse(redirectUrl);
    if (uri == null) {
      return {"type": "none"};
    }

    // 🔹 BRAND CASE
    // /product-category?brand=ASUS
    final brand = uri.queryParameters['brand'];
    if (brand != null && brand.isNotEmpty) {
      return {
        "type": "brand",
        "value": brand, // ASUS
      };
    }

    // 🔹 CATEGORY CASE
    // /product-category/computers/networking
    final segments = uri.pathSegments;

    if (segments.length >= 2 && segments[0] == 'product-category') {
      return {
        "type": "category",
        "value": segments.sublist(1).join('/'),
        // computers/networking
      };
    }

    return {"type": "none"};
  }

  Future<List<Map<String, dynamic>>> fetchAllBanners({
    required String section,
  }) async {
    final response = await http.get(
      Uri.parse(Configss.getBanners),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return data
          .where((item) =>
              item['deviceType'] == 'mobile' &&
              item['section'] == section &&
              item['isActive'] == true)
          .map<Map<String, dynamic>>((item) => {
                "image": item['image'],
                "redirect_url": item['link'],
              })
          .toList();
    } else {
      return [];
    }
  }

  String extractLastWord(String link) {
    // Remove query parameters (? ke baad sab)
    final cleanLink = link.split('?').first;

    // If brand link
    if (link.contains("?brand=")) {
      return link.split("?brand=").last;
    }

    // If search query
    if (link.contains("?search=")) {
      return link.split("?search=").last;
    }

    // If category link
    if (cleanLink.contains("/product-category/")) {
      final parts = cleanLink.split("/product-category/");
      if (parts.length > 1) {
        final subParts = parts[1].split("/");
        return subParts.isNotEmpty ? subParts.last : "";
      }
    }

    return "";
  }

  /// Click Handling Logic for Category Slider Items:
  /// - Agar item Custom hai (redirectUrl present hai) -> Directly redirectUrl open/navigate karein.
  /// - Agar item Category hai (slug present hai) -> App ki Category Products list screen par open karein (slug pass karke).
  void _handleCategorySliderClick(CategorySliderItem item) {
    if (item.type == 'custom' &&
        item.redirectUrl != null &&
        item.redirectUrl!.trim().isNotEmpty) {
      final link = item.redirectUrl!.trim();
      final uri = Uri.tryParse(link);

      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        if (link.contains('/product-category/') ||
            link.contains('/offers/') ||
            link.contains('?brand=')) {
          _navigateInternalLink(link, item.name);
        } else {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        _navigateInternalLink(link, item.name);
      }
    } else {
      final categoryTargetId = (item.slug != null && item.slug!.trim().isNotEmpty)
          ? item.slug!.trim()
          : (item.id != null && item.id!.trim().isNotEmpty)
              ? item.id!.trim()
              : generateSlug(item.name ?? '');

      Get.to(() => bannerProduct(
            brandname: categoryTargetId,
            displayTitle: item.name ?? '',
          ));
    }
  }

  void _navigateInternalLink(String link, String? fallbackTitle) {
    final uri = Uri.tryParse(link);
    final brand = uri?.queryParameters['brand'];

    if (brand != null && brand.isNotEmpty) {
      Get.to(() => bannerProduct(
            brandname: brand,
            displayTitle: brand,
          ));
      return;
    }

    if (link.contains("offers/") || link.contains("/offers/")) {
      String offerSlug = "";
      if (link.contains("/offers/")) {
        offerSlug = link.split("/offers/").last.split("?").first;
      } else {
        offerSlug = link.split("offers/").last.split("?").first;
      }
      offerSlug = offerSlug.replaceAll("/", "");

      String autoTitle = offerSlug
          .replaceAll("-", " ")
          .split(' ')
          .map((word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '')
          .join(' ');

      final isGeneric = fallbackTitle == null ||
          fallbackTitle.trim().isEmpty ||
          fallbackTitle.trim().toLowerCase() == 'test' ||
          fallbackTitle.toLowerCase().contains("section") ||
          fallbackTitle.toLowerCase().contains("banner");

      final displayTitle = isGeneric ? autoTitle : fallbackTitle.trim();

      Get.to(() => offerDeals(
            slug: offerSlug,
            displayTitle: displayTitle,
          ));
      return;
    }

    if (link.contains("/product-category/")) {
      final cleanLink = link.split('?').first;
      final parts = cleanLink.split("/product-category/");
      if (parts.length > 1) {
        final subParts =
            parts[1].split("/").where((p) => p.isNotEmpty).toList();
        if (subParts.isNotEmpty) {
          final catSlug = subParts.last;
          Get.to(() => bannerProduct(
                brandname: catSlug,
                displayTitle: fallbackTitle ?? catSlug,
              ));
          return;
        }
      }
    }

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildDynamicSectionForOrder(int targetOrder) {
    return Obx(() {
      if (_dynamicSectionController.isLoadingSections.value &&
          _dynamicSectionController.activeSections.isEmpty) {
        if (targetOrder == 1) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: AspectRatio(
              aspectRatio: 3.2,
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }

      final matchingSections =
          _dynamicSectionController.activeSections.where((section) {
        if (targetOrder == 1) {
          return section.order <= 1;
        }
        if (targetOrder >= 6) {
          return section.order >= 6;
        }
        return section.order == targetOrder;
      }).toList();

      if (matchingSections.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        children: matchingSections.map((section) {
          return HomeSectionBuilder(
            section: section,
            onCardTap: (linkUrl, cardTitle) {
              _navigateInternalLink(
                linkUrl,
                (cardTitle != null && cardTitle.trim().isNotEmpty)
                    ? cardTitle.trim()
                    : section.name,
              );
            },
          );
        }).toList(),
      );
    });
  }

  String _getSliderImageUrl(String? rawImage) {
    if (rawImage == null || rawImage.isEmpty) return '';
    if (rawImage.startsWith('http://') || rawImage.startsWith('https://')) {
      return rawImage;
    }
    if (rawImage.startsWith('/')) {
      return Configss.baseUrl + rawImage;
    }
    return '${Configss.baseUrl}/$rawImage';
  }

  double getResponsiveProductCardHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 400) {
      return MediaQuery.of(context).size.height * 0.24;
    } else if (screenWidth <= 600) {
      return MediaQuery.of(context).size.height * 0.21;
    } else if (screenWidth <= 900) {
      return MediaQuery.of(context).size.height * 0.18;
    } else {
      return MediaQuery.of(context).size.height * 0.14;
    }
  }

  List<dynamic> _getSortedDisplayProducts(List<dynamic> productList) {
    if (productList.isEmpty) return [];

    List<dynamic> preorderItems = [];
    List<dynamic> availableItems = [];
    List<dynamic> outOfStockItems = [];

    for (var productElement in productList) {
      if (productElement is! Map<String, dynamic>) {
        continue;
      }
      Map<String, dynamic> product = productElement;

      if (product.containsKey('stockStatus')) {
        final status = product['stockStatus'].toString().toLowerCase();
        if (status == 'preorder' || status == 'pre order') {
          preorderItems.add(product);
        } else if (status == 'out of stock') {
          outOfStockItems.add(product);
        } else {
          // Treat others/unknown as available
          availableItems.add(product);
        }
      } else {
        availableItems.add(product);
      }
    }
    // CHANGE: Available -> PreOrder -> Out of Stock
    return [...availableItems, ...preorderItems, ...outOfStockItems];
  }

  void _showAddedToCartPopup() {
    showGeneralDialog(
      context: context,
      barrierLabel: 'home_added_to_cart'.tr,
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
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'home_added_to_cart'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
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

  void _startBrandsAutoScroll() {
    if (_brandsAutoLoopStarted) return;
    _brandsAutoLoopStarted = true;
    _autoScrollBrandsLoop();
  }

  String generateSlug(String text) {
    return text
        .toLowerCase() // CAPITAL → lowercase
        .trim() // start/end spaces remove
        .replaceAll(RegExp(r'[^\w\s-]'), '') // special characters remove
        .replaceAll(RegExp(r'\s+'), '-') // spaces → hyphen
        .replaceAll(RegExp(r'-+'), '-'); // multiple hyphens → single
  }

  Future<void> _autoScrollBrandsLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3)); // wait before each step
      if (!mounted || !_brandsScrollController.hasClients) continue;
      if (_brandStepExtent <= 0 || _brandLoopSpan <= 0) continue;

      double current = _brandsScrollController.offset;

      // If near the end of the middle copy, jump back by one full span (seamless wrap)
      final double wrapThreshold =
          _brandLoopSpan * 2 - (_brandStepExtent * 1.5);
      if (current >= wrapThreshold) {
        try {
          _brandsScrollController.jumpTo(current - _brandLoopSpan);
          current = _brandsScrollController.offset;
        } catch (_) {}
      }

      final double next = current + _brandStepExtent;
      try {
        await _brandsScrollController.animateTo(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } catch (_) {
        // ignore interrupted animations
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildCategoryDrawer(),
      appBar: CustomAppBar(
          // Show Drawer Menu
          showLeading: true,
          leadingWidget: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: kdefwhiteColor),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),

          // Change: always show logo on Home
          titleWidget: Image.asset(
            AppImages.logoicon,
            width: 100,
            height: 100,
            color: kdefwhiteColor,
          ),
          actionicon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SearchScreenSecond()));
                  },
                  icon: const Icon(Icons.search,
                      color: kdefwhiteColor, size: 28)),
              GetBuilder<CartNotifier>(
                builder: (cartNotifier) {
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.route(const Cart());
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: Image.asset(
                            "assets/icons/addcart.png",
                            color: kdefwhiteColor,
                            width: 28,
                            height: 28,
                          ),
                        ),
                      ),
                      if (cartNotifier.cartOtherInfoList.isNotEmpty) ...[
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: kredColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cartNotifier.cartOtherInfoList.length.toString(),
                              style: const TextStyle(
                                color: kdefwhiteColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          )),
      body: SafeArea(
        child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(children: [
              const ImageCarouselSlider(),
              10.0.heightbox,
              Column(
                children: [
                  GestureDetector(
                    key: _categoriesSectionKey,
                    onTap: () {
                      context.route(const AllCategoriesScreen());
                    },
                    child: Padding(
                      padding: defaultPadding(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('categories'.tr,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: kSecondaryColor)),
                          Row(
                            children: [
                              Text('home_show_all'.tr,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: kSecondaryColor)),
                              Icon(Icons.arrow_forward_ios,
                                  size: 12, color: kSecondaryColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GetBuilder<HomeSliderController>(
                    builder: (homeCtrl) {
                      if (homeCtrl.isCateloading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final List<CategorySliderItem> items =
                          homeCtrl.sliderItems.isNotEmpty
                              ? homeCtrl.sliderItems
                              : homeCtrl.category
                                  .map((c) => CategorySliderItem(
                                        id: c.sId,
                                        name: c.name,
                                        nameAr: c.nameAr,
                                        image: c.image,
                                        slug: c.slug,
                                        type: 'category',
                                      ))
                                  .toList();

                      if (items.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return SizedBox(
                        height: 120,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding:
                                  defaultPadding(horizontal: 8, vertical: 5),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth - 16,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children:
                                      List.generate(items.length, (index) {
                                    final item = items[index];
                                    final imageUrl =
                                        _getSliderImageUrl(item.image);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Column(
                                        children: [
                                          GestureDetector(
                                            onTap: () =>
                                                _handleCategorySliderClick(
                                                    item),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: kdefgreyColor,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    offset: const Offset(0, 2),
                                                    blurRadius: 3,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                imageBuilder:
                                                    (context, imageProvider) =>
                                                        Container(
                                                  height: 65,
                                                  width: 60,
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                                placeholder: (context, url) =>
                                                    SizedBox(
                                                  height: 65,
                                                  width: 60,
                                                  child: Shimmer.fromColors(
                                                    baseColor:
                                                        Colors.grey.shade300,
                                                    highlightColor:
                                                        Colors.grey.shade100,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Container(
                                                  height: 65,
                                                  width: 60,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                    image:
                                                        const DecorationImage(
                                                      image: AssetImage(
                                                          'assets/images/noimage.png'),
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          8.0.heightbox,
                                          Builder(builder: (_) {
                                            final bool _isArCat =
                                                Get.isRegistered<LanguageController>() &&
                                                    Get.find<LanguageController>()
                                                        .isArabic;
                                            final String _catName = (_isArCat &&
                                                    (item.nameAr
                                                            ?.trim()
                                                            .isNotEmpty ==
                                                        true))
                                                ? item.nameAr!
                                                : (item.name ?? '');
                                            return Text(
                                              (_catName.characters
                                                      .take(12)
                                                      .toString()) +
                                                  ((_catName.length > 12)
                                                      ? '...': ''),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: kSecondaryColor,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  // --- Dynamic Home Sections (Order 1: Under Categories) ---
                  _buildDynamicSectionForOrder(1),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 8.0),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchAllBanners(section: "top-mobile"),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SizedBox(height: 110);
                        }

                        if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        }

                        final banners = snapshot.data ?? [];

                        // fallback agar API se data nahi aaya
                        final firstBanner = banners.isNotEmpty
                            ? banners[0]
                            : {
                                "image": "assets/images/noimage.png",
                                "redirect_url": ""
                              };

                        final secondBanner = banners.length > 1
                            ? banners[1]
                            : {
                                "image": "assets/images/noimage.png",
                                "redirect_url": ""
                              };

                        final firstImage =
                            ImageHelper.getUrl(firstBanner["image"]);
                        final secondImage =
                            ImageHelper.getUrl(secondBanner["image"]);

                        final firstLink = firstBanner["redirect_url"];
                        final secondLink = secondBanner["redirect_url"];

                        return Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => bannerProduct(
                                                brandname:
                                                    extractLastWord(firstLink),
                                                displayTitle:
                                                    extractLastWord(firstLink),
                                              )));
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    firstImage,
                                    fit: BoxFit.cover,
                                    height: 110,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/noimage.png',
                                        fit: BoxFit.cover,
                                        height: 110,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => bannerProduct(
                                                brandname:
                                                    extractLastWord(secondLink),
                                                displayTitle:
                                                    extractLastWord(secondLink),
                                              )));
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    secondImage,
                                    fit: BoxFit.cover,
                                    height: 110,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/noimage.png',
                                        fit: BoxFit.cover,
                                        height: 110,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Padding(
                  //   padding: const EdgeInsets.symmetric(
                  //       horizontal: 8.0, vertical: 0.0),
                  //   child: ClipRRect(
                  //     borderRadius: BorderRadius.circular(8.0),
                  //     child: Image.asset('assets/images/tamara.png',
                  //         height: 70, fit: BoxFit.fill, width: double.infinity),
                  //   ),
                  // ),

                  const SizedBox(height: 10.0),

                  // START: New Featured Products Section
                  Obx(() {
                    final isLoadingFeatured =
                        _homeController.isLoadingFeaturedProducts.value;
                    final featuredProductList =
                        _homeController.featuredProducts;
                    final sortedFeaturedProducts =
                        _getSortedDisplayProducts(featuredProductList);
                    final displayFeaturedProducts = sortedFeaturedProducts
                        .take(homeScreenSectionDisplayLimit)
                        .toList();

                    if (displayFeaturedProducts.isEmpty && !isLoadingFeatured) {
                      return const SizedBox
                          .shrink(); // Don't show if empty and not loading
                    }

                    return HorizontalProducts(
                      onTap: () {
                        Get.to(() => NewAllProduct(
                            id: "_featured_", parentType: "featured"));
                      },
                      name: 'home_featured_products'.tr,
                      loading: isLoadingFeatured,
                      productList: displayFeaturedProducts,
                      onAddedToCart: _showAddedToCartPopup, // ADD
                    );
                  }),
                  // --- Dynamic Home Sections (Order 2: Under Featured Products) ---
                  _buildDynamicSectionForOrder(2),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 10.0),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchAllBanners(section: "hp-mobile"),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(height: 140);
                        }
                        if (snapshot.hasError) {
                          return const SizedBox(height: 140);
                        }

                        final banners = snapshot.data ?? [];

                        final banner = banners.isNotEmpty
                            ? banners.first
                            : {
                                "image": "assets/images/noimage.png",
                                "redirect_url": ""
                              };

                        final image = ImageHelper.getUrl(banner["image"]);
                        final redirectLink = banner["redirect_url"];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => bannerProduct(
                                          brandname:
                                              extractLastWord(redirectLink),
                                          displayTitle:
                                              extractLastWord(redirectLink),
                                        )));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              image,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/noimage.png',
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.fill,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  Obx(() {
                    final isLoadingHp = _brandController
                            .isLoadingProductsByBrandIdMap[_hpSectionBrandId]
                            ?.value ??
                        true;
                    final hpProductList = _brandController
                            .productsByBrandIdMap[_hpSectionBrandId] ??
                        <dynamic>[].obs;
                    final sortedHpProducts =
                        _getSortedDisplayProducts(hpProductList);
                    final displayHpProducts = sortedHpProducts
                        .take(homeScreenSectionDisplayLimit)
                        .toList();

                    if (displayHpProducts.isEmpty && !isLoadingHp) {
                      return const SizedBox.shrink();
                    }

                    return HorizontalProducts(
                      onTap: () {
                        if (_hpSectionBrandId.isNotEmpty) {
                          Get.to(() => NewAllProduct(
                              id: _hpSectionBrandId, parentType: "brand"));
                        } else {
                          Get.snackbar('home_developer_info'.tr,
                              'home_hp_brand_config_msg'.tr);
                        }
                      },
                      name: 'home_hp_products'.tr,
                      loading: isLoadingHp,
                      productList: displayHpProducts,
                      onAddedToCart: _showAddedToCartPopup, // ADD
                    );
                  }),
                  // --- Dynamic Home Sections (Order 3: Under HP Products) ---
                  _buildDynamicSectionForOrder(3),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 10.0),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchAllBanners(section: "accessories"),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(height: 140);
                        }
                        if (snapshot.hasError) {
                          return const SizedBox(height: 140);
                        }

                        final banners = snapshot.data ?? [];

                        final banner = banners.isNotEmpty
                            ? banners.first
                            : {
                                "image": "assets/images/noimage.png",
                                "redirect_url": ""
                              };

                        final image = ImageHelper.getUrl(banner["image"]);
                        final redirectLink = banner["redirect_url"];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => bannerProduct(
                                          brandname:
                                              extractLastWord(redirectLink),
                                          displayTitle:
                                              extractLastWord(redirectLink),
                                        )));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              image,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/noimage.png',
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.fill,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  Obx(() {
                    final isLoadingAccessories = _homeController
                            .isLoadingProductsByCategoryIdMap[
                                accessoriesCategoryId]
                            ?.value ??
                        true;
                    final accessoriesProductList = _homeController
                            .productsByCategoryIdMap[accessoriesCategoryId] ??
                        <dynamic>[].obs;
                    final sortedAccessoriesProducts =
                        _getSortedDisplayProducts(accessoriesProductList);
                    final displayAccessoriesProducts = sortedAccessoriesProducts
                        .take(homeScreenSectionDisplayLimit)
                        .toList();

                    if (displayAccessoriesProducts.isEmpty &&
                        !isLoadingAccessories) {
                      return const SizedBox.shrink();
                    }

                    return HorizontalProducts(
                      onTap: () {
                        Get.to(() => NewAllProduct(
                            id: accessoriesCategoryId, parentType: "category"));
                      },
                      name: 'home_accessories'.tr,
                      loading: isLoadingAccessories,
                      productList: displayAccessoriesProducts,
                      onAddedToCart: _showAddedToCartPopup, // ADD
                    );
                  }),
                  // --- Dynamic Home Sections (Order 4: Under Accessories) ---
                  _buildDynamicSectionForOrder(4),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 10.0),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchAllBanners(section: "asus-mobile"),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(height: 140);
                        }
                        if (snapshot.hasError) {
                          return const SizedBox(height: 140);
                        }

                        final banners = snapshot.data ?? [];

                        final banner = banners.isNotEmpty
                            ? banners.first
                            : {
                                "image": "assets/images/noimage.png",
                                "redirect_url": ""
                              };

                        final image = ImageHelper.getUrl(banner["image"]);
                        final redirectLink = banner["redirect_url"];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => bannerProduct(
                                          brandname:
                                              extractLastWord(redirectLink),
                                          displayTitle:
                                              extractLastWord(redirectLink),
                                        )));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              image,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/noimage.png',
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.fill,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  Obx(() {
                    final isLoadingAsus = _brandController
                            .isLoadingProductsByBrandIdMap[_asusSectionBrandId]
                            ?.value ??
                        true;
                    final asusProductList = _brandController
                            .productsByBrandIdMap[_asusSectionBrandId] ??
                        <dynamic>[].obs;
                    final sortedAsusProducts =
                        _getSortedDisplayProducts(asusProductList);
                    final displayAsusProducts = sortedAsusProducts
                        .take(homeScreenSectionDisplayLimit)
                        .toList();

                    if (displayAsusProducts.isEmpty && !isLoadingAsus) {
                      return const SizedBox.shrink();
                    }

                    return HorizontalProducts(
                      onTap: () {
                        Get.to(() => NewAllProduct(
                            id: _asusSectionBrandId, parentType: "brand"));
                      },
                      name: 'home_shop_asus'.tr,
                      loading: isLoadingAsus,
                      productList: displayAsusProducts,
                      onAddedToCart: _showAddedToCartPopup, // ADD
                    );
                  }),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 10.0),
                    child: GestureDetector(
                      onTap: () {
                        Get.to(() => NewAllProduct(
                            id: networkingCategoryId,
                            parentType: "subcategory"));
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        // child: Image.asset('assets/images/networking.png', height: 140, fit: BoxFit.fill, width: double.infinity),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Obx(() {
                    final isLoadingNetworking = _homeController
                            .isLoadingProductsByCategoryIdMap[
                                networkingCategoryId]
                            ?.value ??
                        true;
                    final networkingProductList = _homeController
                            .productsByCategoryIdMap[networkingCategoryId] ??
                        <dynamic>[].obs;
                    final sortedNetworkingProducts =
                        _getSortedDisplayProducts(networkingProductList);
                    final displayNetworkingProducts = sortedNetworkingProducts
                        .take(homeScreenSectionDisplayLimit)
                        .toList();

                    if (displayNetworkingProducts.isEmpty &&
                        !isLoadingNetworking) {
                      return const SizedBox.shrink();
                    }

                    return HorizontalProducts(
                      onTap: () {
                        Get.to(() => NewAllProduct(
                            id: networkingCategoryId,
                            parentType: "subcategory"));
                      },
                      name: 'home_networking'.tr,
                      loading: isLoadingNetworking,
                      productList: displayNetworkingProducts,
                      onAddedToCart: _showAddedToCartPopup, // ADD
                    );
                  }),
                  // --- Dynamic Home Sections (Order 5: Under Networking) ---
                  _buildDynamicSectionForOrder(5),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 10.0),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchAllBanners(section: "msi-mobile"),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(height: 140);
                        }
                        if (snapshot.hasError) {
                          return const SizedBox(height: 140);
                        }

                        final banners = snapshot.data ?? [];

                        final banner = banners.isNotEmpty
                            ? banners.first
                            : {
                                "image": "assets/images/noimage.png",
                                "redirect_url": ""
                              };

                        final image = ImageHelper.getUrl(banner["image"]);
                        final redirectLink = banner["redirect_url"];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => bannerProduct(
                                          brandname:
                                              extractLastWord(redirectLink),
                                          displayTitle:
                                              extractLastWord(redirectLink),
                                        )));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              image,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/noimage.png',
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.fill,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  Obx(() {
                    final isLoadingMsi = _brandController
                            .isLoadingProductsByBrandIdMap[_msiSectionBrandId]
                            ?.value ??
                        true;
                    final msiProductList = _brandController
                            .productsByBrandIdMap[_msiSectionBrandId] ??
                        <dynamic>[].obs;
                    final sortedMsiProducts =
                        _getSortedDisplayProducts(msiProductList);
                    final displayMsiProducts = sortedMsiProducts
                        .take(homeScreenSectionDisplayLimit)
                        .toList();

                    if (displayMsiProducts.isEmpty && !isLoadingMsi) {
                      return const SizedBox.shrink();
                    }

                    return HorizontalProducts(
                      onTap: () {
                        if (_msiSectionBrandId.isNotEmpty) {
                          Get.to(() => NewAllProduct(
                              id: _msiSectionBrandId, parentType: "brand"));
                        } else {
                          Get.snackbar(
                              'home_info_title'.tr, 'home_msi_unavailable_msg'.tr);
                        }
                      },
                      name: 'home_shop_msi'.tr,
                      loading: isLoadingMsi,
                      productList: displayMsiProducts,
                      onAddedToCart: _showAddedToCartPopup, // ADD
                    );
                  }),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 10.0),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchAllBanners(section: "apple-mobile"),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(height: 140);
                        }
                        if (snapshot.hasError) {
                          return const SizedBox(height: 140);
                        }

                        final banners = snapshot.data ?? [];

                        final banner = banners.isNotEmpty
                            ? banners.first
                            : {
                                "image": "assets/images/noimage.png",
                                "redirect_url": ""
                              };

                        final image = ImageHelper.getUrl(banner["image"]);
                        final redirectLink = banner["redirect_url"];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => bannerProduct(
                                          brandname:
                                              extractLastWord(redirectLink),
                                          displayTitle:
                                              extractLastWord(redirectLink),
                                        )));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              image,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/noimage.png',
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.fill,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  Obx(() {
                    final isLoadingApple = _brandController
                            .isLoadingProductsByBrandIdMap[_appleSectionBrandId]
                            ?.value ??
                        true;
                    final appleProductList = _brandController
                            .productsByBrandIdMap[_appleSectionBrandId] ??
                        <dynamic>[].obs;
                    final sortedAppleProducts =
                        _getSortedDisplayProducts(appleProductList);
                    final displayAppleProducts = sortedAppleProducts
                        .take(homeScreenSectionDisplayLimit)
                        .toList();

                    if (displayAppleProducts.isEmpty && !isLoadingApple) {
                      return const SizedBox.shrink();
                    }

                    return HorizontalProducts(
                      onTap: () {
                        if (_appleSectionBrandId.isNotEmpty) {
                          Get.to(() => NewAllProduct(
                              id: _appleSectionBrandId, parentType: "brand"));
                        } else {
                          Get.snackbar(
                              'home_info_title'.tr, 'home_apple_unavailable_msg'.tr);
                        }
                      },
                      name: 'home_show_apple'.tr,
                      loading: isLoadingApple,
                      productList: displayAppleProducts,
                      onAddedToCart: _showAddedToCartPopup, // ADD
                    );
                  }),
                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: () {
                      context.route(AllBrandScreen(
                          brandList: _brandController.brandList));
                    },
                    child: Padding(
                      padding: defaultPadding(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('home_featured_brands'.tr,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: kSecondaryColor)),
                          Row(
                            children: [
                              Text('home_show_all'.tr,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: kSecondaryColor)),
                              Icon(Icons.arrow_forward_ios,
                                  size: 12, color: kSecondaryColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Obx(() {
                    // Touch Rx at top-level of Obx to avoid improper use warning
                    final bool isLoadingBrands =
                        _brandController.isbrandLoaded.value;
                    final List<dynamic> brands = _brandController.brandList;

                    // Reduced outer horizontal padding
                    final basePad = defaultPadding();
                    final sectionPad = EdgeInsets.fromLTRB(
                        4.0, basePad.top, 4.0, basePad.bottom);

                    return Padding(
                      padding: sectionPad,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Width inside section padding
                          final double contentWidth = constraints.maxWidth;

                          // Slightly reduced gap between cards
                          final double gap = contentWidth >= 360 ? 10.0 : 6.0;
                          // Smaller equal left/right edge padding inside the scroll
                          final double edgePad = 3.0;

                          // Snap helper to avoid fractional pixel overflow/clipping
                          final double dpr =
                              MediaQuery.of(context).devicePixelRatio;
                          double snap(double v) => (v * dpr).floor() / dpr;

                          // Fit two items exactly with equal edges:
                          // contentWidth = edgePad + itemW + gap + itemW + edgePad
                          final double available =
                              contentWidth - (2 * edgePad) - gap - 0.5;
                          final double itemWidth =
                              snap(available / 2).clamp(80.0, contentWidth);

                          // Slightly reduce shrink so the card is a bit larger (~9%)
                          final double shrink =
                              (itemWidth * 0.09).clamp(6.0, 18.0);
                          final double cardWidth =
                              (itemWidth - shrink).clamp(90.0, itemWidth);

                          // one-slot step and full cycle span
                          final double stepExtent = itemWidth + gap;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _brandStepExtent = stepExtent;
                          });

                          if (!isLoadingBrands && brands.isNotEmpty) {
                            final double span = stepExtent * brands.length;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _brandLoopSpan = span;
                              if (!_brandsCentered &&
                                  _brandsScrollController.hasClients &&
                                  span > 0) {
                                try {
                                  // center on the middle copy
                                  _brandsScrollController.jumpTo(span);
                                  _brandsCentered = true;
                                } catch (_) {}
                              }
                            });
                          }

                          if (isLoadingBrands) {
                            return SingleChildScrollView(
                              controller: _brandsScrollController,
                              scrollDirection: Axis.horizontal,
                              padding:
                                  EdgeInsets.symmetric(horizontal: edgePad),
                              child: Row(
                                children: [
                                  ...List.generate(6, (index) {
                                    return Container(
                                      width: itemWidth, // fixed slot
                                      margin: EdgeInsets.only(
                                          right: index == 5 ? 0 : gap),
                                      child: Center(
                                        child: Container(
                                          width: cardWidth,
                                          height: cardWidth,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          child: Shimmer.fromColors(
                                            baseColor: Colors.grey.shade300,
                                            highlightColor:
                                                Colors.grey.shade100,
                                            child: const SizedBox.expand(),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  SizedBox(width: edgePad),
                                ],
                              ),
                            );
                          } else if (brands.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'home_no_brands'.tr,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            );
                          } else {
                            // Repeat brands 3x to simulate infinite list visually
                            final int total = brands.length * 3;
                            return SingleChildScrollView(
                              controller: _brandsScrollController,
                              scrollDirection: Axis.horizontal,
                              padding:
                                  EdgeInsets.symmetric(horizontal: edgePad),
                              child: Row(
                                children: [
                                  ...List.generate(total, (index) {
                                    final realIndex = index % brands.length;
                                    final brand = brands[realIndex];
                                    final bool isLast = index == total - 1;
                                    return Container(
                                      width: itemWidth,
                                      // fixed slot to keep 2-per-view
                                      margin: EdgeInsets.only(
                                          right: isLast ? 0 : gap),
                                      child: Center(
                                        child: BrandCard(
                                          id: (brand['_id'] ?? '').toString(),
                                          imageUrl:
                                              ImageHelper.getUrl(brand['logo'])
                                                  .toString(),
                                          name: (brand['name'] ?? 'home_no_name'.tr)
                                              .toString(),
                                          width:
                                              cardWidth, // visual size inside the slot
                                        ),
                                      ),
                                    );
                                  }),
                                  SizedBox(width: edgePad),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }),
                  // --- Dynamic Home Sections (Order 6+: Under Brands / Page Bottom) ---
                  _buildDynamicSectionForOrder(6),
                  40.0.heightbox,
                ],
              ),
            ])),
      ),
    );
  }
}
