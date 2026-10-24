import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:graba2z/Utils/appextensions.dart';
import '../../../../Controllers/addtocart.dart';
import '../../../../Controllers/bannerProductController.dart';
import 'package:graba2z/Controllers/home_controller.dart';
import 'package:graba2z/Controllers/brand_controller.dart';
import 'package:graba2z/Controllers/language_controller.dart';
import '../../../../Controllers/bottomController.dart';
import '../../../../Utils/appcolors.dart';
import '../../../../Widgets/customappbar.dart';
import '../../../Product Folder/newProduct_card.dart';
import '../Cart/cart.dart';
import '../Search Screen/searchscreensecond.dart';
import 'filter_screen.dart';

const String _homeSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 12L12 4L20 12" />
  <path d="M5 12V20H10V15H14V20H19V12" />
</svg>
''';

class bannerProduct extends StatefulWidget {
  final String? brandname;
  final String? displayTitle;

  const bannerProduct({
    Key? key,
    this.brandname,
    this.displayTitle,
  }) : super(key: key);

  @override
  State<bannerProduct> createState() => _bannerProductState();
}

class _bannerProductState extends State<bannerProduct> {

  final bannerProductController controller = Get.put(bannerProductController());

  static const int pageSize = 12;
  int visibleCount = pageSize;

  // Filter state
  Map<String, String> _allBrandsMap = {}; // All brands from API: {id: name}
  List<Map<String, String>> _availableBrands = []; // Brands in current products
  List<Map<String, String>> _availableCategories = []; // Categories in current products
  Set<String> _selectedBrandIds = {};
  Set<String> _selectedCategoryIds = {};
  bool _isBrandsLoading = true;

  double _calcSortMaxWidth(BoxConstraints c) =>
      math.min(220.0, c.maxWidth * 0.38);
  List<dynamic> _sortedLocalProducts = const [];

  // Filter products based on selected brands and categories - OPTIMIZED
  List<dynamic> _filterProductsByBrandsAndCategories(List<dynamic> products) {
    // If no filters selected, return all products (early exit)
    if (_selectedBrandIds.isEmpty && _selectedCategoryIds.isEmpty) {
      return products;
    }

    final List<dynamic> filtered = [];
    final bool filterByBrand = _selectedBrandIds.isNotEmpty;
    final bool filterByCategory = _selectedCategoryIds.isNotEmpty;

    for (final product in products) {
      if (product is! Map<String, dynamic>) {
        continue;
      }

      // Check brand filter
      bool brandMatches = true;
      if (filterByBrand) {
        final brand = product['brand'];
        String? brandId;

        if (brand is Map<String, dynamic>) {
          brandId = brand['_id']?.toString();
        } else if (brand is String) {
          brandId = brand;
        }

        brandMatches = brandId != null && _selectedBrandIds.contains(brandId);
        if (!brandMatches) continue; // Skip if brand doesn't match
      }

      // Check category filter
      if (filterByCategory) {
        final category = product['category'];
        String? categoryId;

        if (category is Map<String, dynamic>) {
          categoryId = category['_id']?.toString();
        } else if (category is String) {
          categoryId = category;
        }

        final categoryMatches = categoryId != null && _selectedCategoryIds.contains(categoryId);
        if (!categoryMatches) continue; // Skip if category doesn't match
      }

      // Both filters passed, add to filtered list
      filtered.add(product);
    }

    return filtered;
  }

  void _showAddedToCartPopup() {
    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) =>
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
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
                        'shop_added_to_cart'.tr,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (entry.mounted) entry.remove();
    });
  }

  String _sortLabel = 'Newest First';

  /// Translated label for the sort button (internal value stays English for logic).
  String get _sortDisplayLabel {
    switch (_sortLabel) {
      case 'Price: Low to High':
        return 'shop_sort_price_low'.tr;
      case 'Price: High to Low':
        return 'shop_sort_price_high'.tr;
      case 'Name: A to Z':
        return 'shop_sort_name_az'.tr;
      default:
        return 'shop_sort_newest'.tr;
    }
  }
  bool _sortMenuOpen = false;

  Widget _sortMenuButton() {
    return PopupMenuButton<String>(
      onOpened: () => setState(() => _sortMenuOpen = true),
      onCanceled: () => setState(() => _sortMenuOpen = false),
      onSelected: (val) =>
          setState(() {
            _sortLabel = val;
            _sortMenuOpen = false;
          }),
      itemBuilder: (_) => [
        PopupMenuItem(
            value: 'Newest First', child: Text('shop_sort_newest'.tr)),
        PopupMenuItem(
            value: 'Price: Low to High',
            child: Text('shop_sort_price_low'.tr)),
        PopupMenuItem(
            value: 'Price: High to Low',
            child: Text('shop_sort_price_high'.tr)),
        PopupMenuItem(
            value: 'Name: A to Z', child: Text('shop_sort_name_az'.tr)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                _sortDisplayLabel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(width: 6),
            Transform.rotate(
              angle: _sortMenuOpen ? 3.14159 : 0,
              child:
              const Icon(Icons.expand_more, size: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _webLikeLoadMoreStyle() {
    const Color green600 = Color(0xFF16A34A); // Tailwind green-600
    const Color green700 = Color(0xFF15803D); // Tailwind green-700
    return ButtonStyle(
      padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
      // smaller px-3 py-1
      minimumSize: MaterialStateProperty.all(const Size(0, 32)),
      // compact height
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      // FIX: was MaterialStateProperty.shrinkWrap
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (states) =>
        states.contains(MaterialState.pressed)
            ? green700
            : green600, // hover/pressed -> green-700
      ),
      foregroundColor: MaterialStateProperty.all(Colors.white),
      // text-white
      elevation: MaterialStateProperty.all(4),
      // shadow
      shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.25)),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6)), // rounded-md
      ),
      textStyle: MaterialStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      // text-sm
      overlayColor: MaterialStateProperty.all(
          green700.withOpacity(0.12)), // transition-colors feedback
    );
  }

  // Extractors for sorting
  num _priceOf(dynamic e) {
    if (e is Map) {
      final keys = [
        'finalPrice',
        'discountedPrice',
        'salePrice',
        'sellingPrice',
        'price'
      ];
      for (final k in keys) {
        final v = e[k];
        if (v is num) return v;
        if (v is String) {
          final n = num.tryParse(v);
          if (n != null) return n;
        }
      }
    }
    return 0;
  }

  String _nameOf(dynamic e) {
    if (e is Map) {
      final keys = ['name', 'productName', 'title'];
      for (final k in keys) {
        final v = e[k];
        if (v is String && v
            .trim()
            .isNotEmpty) return v.trim();
      }
    }
    return '';
  }

  // Apply the selected sorting inside stock groups, then combine (Available -> PreOrder -> Out of Stock)
  List<dynamic> _applySortOption(List<dynamic> base) {
    if (base.isEmpty) return base;

    // For "Newest First", return as-is (no sorting needed)
    if (_sortLabel == 'Newest First') {
      return base;
    }

    final available = <dynamic>[];
    final preorder = <dynamic>[];
    final outOfStock = <dynamic>[];

    // Categorize by stock status in single pass
    for (final e in base) {
      if (e is Map) {
        final s = (e['stockStatus'] ?? '').toString().toLowerCase();
        if (s == 'preorder' || s == 'pre order') {
          preorder.add(e);
        } else if (s == 'out of stock') {
          outOfStock.add(e);
        } else {
          available.add(e);
        }
      } else {
        available.add(e);
      }
    }

    // Only sort if needed
    int Function(dynamic, dynamic)? cmp;
    switch (_sortLabel) {
      case 'Price: Low to High':
        cmp = (a, b) => _priceOf(a).compareTo(_priceOf(b));
        break;
      case 'Price: High to Low':
        cmp = (a, b) => _priceOf(b).compareTo(_priceOf(a));
        break;
      case 'Name: A to Z':
        cmp = (a, b) =>
            _nameOf(a).toLowerCase().compareTo(_nameOf(b).toLowerCase());
        break;
      default:
        return [...available, ...preorder, ...outOfStock];
    }

    available.sort(cmp);
    preorder.sort(cmp);
    outOfStock.sort(cmp);

    return [...available, ...preorder, ...outOfStock];
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
      final product = productElement as Map<String, dynamic>;
      final s = (product['stockStatus'] ?? '').toString().toLowerCase();
      if (s == 'preorder' || s == 'pre order') {
        preorderItems.add(product);
      } else if (s == 'out of stock') {
        outOfStockItems.add(product);
      } else {
        // Treat all other/unknown as available
        availableItems.add(product);
      }
    }
    // CHANGE: Available -> PreOrder -> Out of Stock
    return [...availableItems, ...preorderItems, ...outOfStockItems];
  }

  @override
  void initState() {
    super.initState();
    controller.fetchProductsByName(
      name: widget.brandname,
    );

    // Listen to product list changes and extract brands/categories automatically
    ever(controller.bannerProductList, (_) {
      // Reset filters when product list changes
      if (mounted) {
        setState(() {
          _selectedBrandIds.clear();
          _selectedCategoryIds.clear();
          visibleCount = pageSize;
        });
        _extractBrandsAndCategories();
      }
    });

    // Also try extracting after initial delay in case products already loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && controller.bannerProductList.isNotEmpty) {
        _extractBrandsAndCategories();
      }
    });
  }

  @override
  void didUpdateWidget(bannerProduct oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If brandname changed, fetch new products and reset filter
    if (oldWidget.brandname != widget.brandname) {
      if (mounted) {
        setState(() {
          _selectedBrandIds.clear();
          _selectedCategoryIds.clear();
          _availableBrands.clear();
          _availableCategories.clear();
          visibleCount = pageSize;
        });
      }

      controller.fetchProductsByName(
        name: widget.brandname,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Extract brands and categories from current products - OPTIMIZED
  void _extractBrandsAndCategories() {
    if (controller.bannerProductList.isEmpty) {
      if (mounted) {
        setState(() {
          _availableBrands.clear();
          _availableCategories.clear();
        });
      }
      return;
    }

    final Map<String, String> brandNameMap = {};
    final Map<String, String> brandNameArMap = {};
    final Map<String, String> categoryNameMap = {};
    final Map<String, String> categoryNameArMap = {};

    for (final product in controller.bannerProductList) {
      if (product is! Map<String, dynamic>) {
        continue;
      }

      // Extract brand
      final brand = product['brand'];
      if (brand is Map<String, dynamic>) {
        final brandId = brand['_id']?.toString();
        final brandName = brand['name']?.toString();
        if (brandId != null && brandId.isNotEmpty && brandName != null && brandName.isNotEmpty) {
          brandNameMap[brandId] = brandName;
          final bAr = brand['nameAr']?.toString() ?? '';
          if (bAr.trim().isNotEmpty) brandNameArMap[brandId] = bAr;
        }
      } else if (brand is String && brand.isNotEmpty) {
        final brandName = product['brandName']?.toString() ?? 'Unknown Brand';
        brandNameMap[brand] = brandName;
      }

      // Extract category
      final category = product['category'];
      if (category is Map<String, dynamic>) {
        final categoryId = category['_id']?.toString();
        final categoryName = category['name']?.toString();
        if (categoryId != null && categoryId.isNotEmpty && categoryName != null && categoryName.isNotEmpty) {
          categoryNameMap[categoryId] = categoryName;
          final cAr = category['nameAr']?.toString() ?? '';
          if (cAr.trim().isNotEmpty) categoryNameArMap[categoryId] = cAr;
        }
      } else if (category is String && category.isNotEmpty) {
        final categoryName = product['categoryName']?.toString() ?? 'Unknown Category';
        categoryNameMap[category] = categoryName;
      }
    }

    // Arabic fallbacks: product embeds usually lack nameAr, resolve by ID
    final bool isArBanner = Get.isRegistered<LanguageController>() &&
        Get.find<LanguageController>().isArabic;
    if (isArBanner) {
      try {
        final hc = Get.find<HomeController>();
        for (final id in categoryNameMap.keys) {
          if (categoryNameArMap.containsKey(id)) continue;
          for (final c in hc.category) {
            if (c.sId == id && (c.nameAr?.trim().isNotEmpty ?? false)) {
              categoryNameArMap[id] = c.nameAr!;
              break;
            }
          }
          if (!categoryNameArMap.containsKey(id)) {
            for (final s in hc.subcategory) {
              if (s.sId == id && (s.nameAr?.trim().isNotEmpty ?? false)) {
                categoryNameArMap[id] = s.nameAr!;
                break;
              }
            }
          }
        }
      } catch (_) {}
      try {
        if (Get.isRegistered<BrandController>()) {
          final bc = Get.find<BrandController>();
          for (final id in brandNameMap.keys) {
            if (brandNameArMap.containsKey(id)) continue;
            for (final b in bc.brandList) {
              if (b is Map &&
                  (b['_id']?.toString() ?? '') == id &&
                  (b['nameAr']?.toString().trim().isNotEmpty ?? false)) {
                brandNameArMap[id] = b['nameAr'].toString();
                break;
              }
            }
          }
        }
      } catch (_) {}
    }

    // Convert to sorted lists
    final brandsList = brandNameMap.entries
        .map((e) => {
              'id': e.key,
              'name': e.value,
              'nameAr': brandNameArMap[e.key] ?? '',
            })
        .toList();
    brandsList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

    final categoriesList = categoryNameMap.entries
        .map((e) => {
              'id': e.key,
              'name': e.value,
              'nameAr': categoryNameArMap[e.key] ?? '',
            })
        .toList();
    categoriesList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

    if (mounted) {
      setState(() {
        _availableBrands = brandsList;
        _availableCategories = categoriesList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Get.put(BottomNavigationController());
    return Scaffold(
      appBar: CustomAppBar(
          showLeading: true,
          leadingWidget: Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back_ios, size: 20),
              );
            },
          ),
          titleText: widget.displayTitle,
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
          )
      ),
      endDrawer: FilterDrawer(
        key: const ValueKey('filter_drawer'),
        availableBrands: _availableBrands,
        availableCategories: _availableCategories,
        selectedBrandIds: _selectedBrandIds,
        selectedCategoryIds: _selectedCategoryIds,
        onApply: (selectedBrands, selectedCategories) {
          setState(() {
            _selectedBrandIds = selectedBrands;
            _selectedCategoryIds = selectedCategories;
            visibleCount = pageSize; // Reset to first page
          });
        },
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.bannerProductList.isEmpty) {
          return Center(child: Text('shop_no_products_found'.tr));
        }

        // Get sorted products first
        final base = _sortedLocalProducts.isNotEmpty
            ? _sortedLocalProducts
            : _getSortedDisplayProducts(controller.bannerProductList);

        // Apply filter by brands and categories (fast operation with early exit)
        final filtered = _filterProductsByBrandsAndCategories(base);

        // Apply UI sort
        final displayable = _applySortOption(filtered);

        // Only take visible count for display (efficient pagination)
        final products = displayable.length > visibleCount
            ? displayable.sublist(0, visibleCount)
            : displayable;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = _calcSortMaxWidth(constraints);
                    return Column(
                      children: [
                        Row(
                          children: [
                            // Filter button
                            InkWell(
                              onTap: () {
                                Scaffold.of(context).openEndDrawer();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.filter_list,
                                            size: 18, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'shop_filter_btn'.tr,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(child: Container()), // Spacer
                            SizedBox(
                              width: maxW,
                              child: _sortMenuButton(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.inventory_2,
                                size: 18, color: kPrimaryColor),
                            const SizedBox(width: 10),
                            Text(
                              '${filtered.length} products',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final product = products[index];
                    return NewProductCard(
                      prdouctList: product,
                      onAddedToCart: _showAddedToCartPopup,
                    );
                  },
                  childCount: products.length,
                ),
              ),
            ),
            // Load More reveals locally (server paging disabled when fetching 2.5k)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Center(
                  child: (visibleCount < filtered.length)
                      ? ElevatedButton(
                    style: _webLikeLoadMoreStyle(),
                    onPressed: () {
                      final total = filtered.length;
                      final next = visibleCount + pageSize;
                      setState(() {
                        visibleCount = next > total ? total : next;
                      });
                    },
                    child: Text('shop_load_more_btn'.tr),
                  )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        );
      }),
    );
  }
}

