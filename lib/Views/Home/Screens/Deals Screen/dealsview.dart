import 'dart:developer';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graba2z/Utils/appextensions.dart';
import '../../../../Controllers/addtocart.dart';
import '../../../../Controllers/bottomController.dart';
import '../../../../Controllers/deals_controller.dart';
import '../../../../Utils/appcolors.dart';
import '../../../../Widgets/customappbar.dart';
import '../../../../Configs/config.dart';
import '../Search Screen/searchscreensecond.dart';
import '../banner redirect/filter_screen.dart';
import 'deals_product_card.dart';
import '../Cart/cart.dart';
import 'package:graba2z/Utils/popup_helper.dart';

class offerDeals extends StatefulWidget {
  final String? slug;
  final String? displayTitle;

  const offerDeals({
    Key? key,
    this.slug,
    this.displayTitle,
  }) : super(key: key);

  @override
  State<offerDeals> createState() => _offerDealsState();
}

class _offerDealsState extends State<offerDeals> {
  late DealsController controller;

  static const int pageSize = 12;
  int visibleCount = pageSize;

  double _calcSortMaxWidth(BoxConstraints c) =>
      math.min(220.0, c.maxWidth * 0.38);

  // Cached sorted products to avoid re-sorting on every build
  List<dynamic> _cachedSortedProducts = [];
  String _lastSortLabel = 'Newest First';
  int _lastProductCount = 0;

  // Filter state
  Map<String, String> _brandLookup = {};
  List<Map<String, String>> _availableBrands = [];
  List<Map<String, String>> _availableCategories = [];
  Set<String> _selectedBrandIds = {};
  Set<String> _selectedCategoryIds = {};

  @override
  void initState() {
    super.initState();
    // Use slug as tag to ensure unique controller instances
    final tag = widget.slug ?? 'default-deals';
    controller = Get.put(DealsController(), tag: tag);

    // Fetch products immediately
    if (widget.slug != null && widget.slug!.isNotEmpty) {
      controller.fetchDealsProducts(slug: widget.slug!);
      log("🔄 Fetching deals products for slug: ${widget.slug}");
    }

    // Fetch all brands from API
    _fetchAllBrands();

    // Listen to product list changes and extract brands/categories automatically
    ever(controller.productList, (_) {
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
      if (mounted && controller.productList.isNotEmpty) {
        _extractBrandsAndCategories();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PopupHelper.showIfNeeded(context, 'offer');
      }
    });
  }

  @override
  void didUpdateWidget(offerDeals oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If slug changed, fetch new products and reset filter
    if (oldWidget.slug != widget.slug) {
      if (mounted) {
        setState(() {
          _selectedBrandIds.clear();
          _selectedCategoryIds.clear();
          _availableBrands.clear();
          _availableCategories.clear();
          visibleCount = pageSize;
        });
      }

      final tag = widget.slug ?? 'default-deals';
      controller = Get.put(DealsController(), tag: tag);

      if (widget.slug != null && widget.slug!.isNotEmpty) {
        controller.fetchDealsProducts(slug: widget.slug!);
      }
    }
  }

  @override
  void dispose() {
    final tag = widget.slug ?? 'default-deals';
    Get.delete<DealsController>(tag: tag);
    super.dispose();
  }

  // Fetch all brands from API
  Future<void> _fetchAllBrands() async {
    try {
      final response = await http.get(
        Uri.parse('${Configss.getallbrands}'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> brandsList = data is List ? data : data['data'] ?? [];

        final Map<String, String> brandLookup = {};
        for (final item in brandsList) {
          if (item is! Map<String, dynamic>) continue;

          final id = (item['_id'] ?? item['id'] ?? '').toString().trim();
          if (id.isEmpty) continue;

          final name = (item['name'] ?? item['nameAr'] ?? item['_name'] ?? 'Unknown Brand')
              .toString()
              .trim();
          brandLookup[id] = name.isEmpty ? 'Unknown Brand' : name;
        }

        if (mounted) {
          setState(() {
            _brandLookup = brandLookup;
          });
          if (controller.productList.isNotEmpty) {
            _extractBrandsAndCategories();
          }
          log("✅ Fetched ${_brandLookup.length} brands from API");
        }
      }
    } catch (e) {
      log("❌ Error fetching brands: $e");
    }
  }

  void _showAddedToCartPopup() {
    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Added to cart',
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
  bool _sortMenuOpen = false;

  Widget _sortMenuButton() {
    return PopupMenuButton<String>(
      onOpened: () => setState(() => _sortMenuOpen = true),
      onCanceled: () => setState(() => _sortMenuOpen = false),
      onSelected: (val) => setState(() {
        _sortLabel = val;
        _sortMenuOpen = false;
      }),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'Newest First', child: Text('Newest First')),
        PopupMenuItem(
            value: 'Price: Low to High', child: Text('Price: Low to High')),
        PopupMenuItem(
            value: 'Price: High to Low', child: Text('Price: High to Low')),
        PopupMenuItem(value: 'Name: A to Z', child: Text('Name: A to Z')),
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
                _sortLabel,
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
    const Color green600 = Color(0xFF16A34A);
    const Color green700 = Color(0xFF15803D);
    return ButtonStyle(
      padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
      minimumSize: MaterialStateProperty.all(const Size(0, 32)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      backgroundColor: MaterialStateProperty.resolveWith<Color>(
        (states) => states.contains(MaterialState.pressed)
            ? green700
            : green600,
      ),
      foregroundColor: MaterialStateProperty.all(Colors.white),
      elevation: MaterialStateProperty.all(4),
      shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.25)),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6)),
      ),
      textStyle: MaterialStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      overlayColor: MaterialStateProperty.all(
          green700.withOpacity(0.12)),
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
        'offerPrice',
        'price',

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
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    return '';
  }

  // Apply the selected sorting inside stock groups
  List<dynamic> _applySortOption(List<dynamic> base) {
    if (base.isEmpty) return base;

    final available = <dynamic>[];
    final preorder = <dynamic>[];
    final outOfStock = <dynamic>[];

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
      case 'Newest First':
      default:
        return base;
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
        availableItems.add(product);
      }
    }
    return [...availableItems, ...preorderItems, ...outOfStockItems];
  }

  // Get cached sorted products - only re-sort when needed
  List<dynamic> _getCachedSortedProducts() {
    final productList = controller.productList;

    // Check if we need to re-sort
    if (_cachedSortedProducts.isEmpty ||
        _lastSortLabel != _sortLabel ||
        _lastProductCount != productList.length) {

      final base = _getSortedDisplayProducts(productList);
      _cachedSortedProducts = _applySortOption(base);
      _lastSortLabel = _sortLabel;
      _lastProductCount = productList.length;
    }

    return _cachedSortedProducts;
  }

  // Extract categories and brands from current products
  void _extractBrandsAndCategories() {
    if (controller.productList.isEmpty) {
      if (mounted) {
        setState(() {
          _availableCategories.clear();
          _availableBrands.clear();
        });
      }
      return;
    }

    final Map<String, String> brandNameMap = {};
    final Map<String, String> categoryNameMap = {};

    for (final product in controller.productList) {
      if (product is! Map<String, dynamic>) {
        continue;
      }

      // Extract brand from either the embedded object or the legacy id string.
      final brand = product['brand'];
      String? brandId;
      String brandName = '';

      if (brand is Map) {
        final brandMap = Map<String, dynamic>.from(brand);
        brandId = (brandMap['_id'] ?? brandMap['id'] ?? '').toString().trim();
        brandName = (brandMap['name'] ?? brandMap['nameAr'] ?? brandMap['_name'] ?? '')
            .toString()
            .trim();
      } else if (brand is String) {
        brandId = brand.trim();
        brandName = _brandLookup[brandId] ?? '';
      }

      if (brandId != null && brandId.isNotEmpty) {
        if (brandName.isEmpty) {
          brandName = _brandLookup[brandId] ?? 'Brand';
        }
        brandNameMap[brandId] = brandName;
      }

      // Extract deepest category level
      final candidates = [
        product['subcategory4'] ?? product['subCategory4'],
        product['subcategory3'] ?? product['subCategory3'],
        product['subcategory2'] ?? product['subCategory2'],
        product['subcategory'] ?? product['subCategory'],
        product['category'],
        product['parentCategory'],
      ];

      Map<String, dynamic>? deepestCategory;
      for (final cat in candidates) {
        if (cat is Map) {
          final id = (cat['_id'] ?? cat['id'])?.toString();
          final name = cat['name']?.toString();
          if (id != null && id.isNotEmpty && name != null && name.isNotEmpty) {
            deepestCategory = {'id': id, 'name': name};
            break; // Stop at deepest level found
          }
        }
      }

      if (deepestCategory != null) {
        categoryNameMap[deepestCategory['id']!] = deepestCategory['name']!;
      }
    }

    // Convert to sorted lists - only brands available in this deals page
    final brandsList = brandNameMap.entries
        .map((e) => {'id': e.key, 'name': e.value})
        .toList();
    brandsList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

    final categoriesList = categoryNameMap.entries
        .map((e) => {'id': e.key, 'name': e.value})
        .toList();
    categoriesList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

    if (mounted) {
      setState(() {
        _availableBrands = brandsList;
        _availableCategories = categoriesList;
      });
      log("✅ Filter updated: ${_availableBrands.length} brands in deals, ${_availableCategories.length} categories");
    }
  }

  // Filter products based on selected brands and categories
  List<dynamic> _filterProductsByBrandsAndCategories(List<dynamic> products) {
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
        if (!brandMatches) continue;
      }

      // Check category filter (matches any of the candidate category levels)
      if (filterByCategory) {
        final catIds = <String>[];
        final checkFields = [
          product['parentCategory'],
          product['category'],
          product['subcategory'] ?? product['subCategory'],
          product['subcategory2'] ?? product['subCategory2'],
          product['subcategory3'] ?? product['subCategory3'],
          product['subcategory4'] ?? product['subCategory4'],
        ];
        for (final cat in checkFields) {
          if (cat is Map) {
            final id = (cat['_id'] ?? cat['id'])?.toString();
            if (id != null && id.isNotEmpty) catIds.add(id);
          } else if (cat is String && cat.isNotEmpty) {
            catIds.add(cat);
          }
        }
        
        final hasMatch = catIds.any((id) => _selectedCategoryIds.contains(id));
        if (!hasMatch) continue;
      }

      filtered.add(product);
    }

    return filtered;
  }

  String get _effectiveDisplayTitle {
    final title = widget.displayTitle?.trim();
    if (title != null &&
        title.isNotEmpty &&
        title.toLowerCase() != 'test' &&
        !title.toLowerCase().contains('section') &&
        !title.toLowerCase().contains('banner')) {
      return title;
    }
    final s = widget.slug ?? '';
    if (s.isNotEmpty) {
      return s
          .replaceAll('-', ' ')
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
    }
    return 'Deals';
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
        titleText: _effectiveDisplayTitle,
          actionicon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder:(context) => SearchScreenSecond()));
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
        availableBrands: _availableBrands,
        availableCategories: _availableCategories,
        selectedBrandIds: _selectedBrandIds,
        selectedCategoryIds: _selectedCategoryIds,
        onApply: (selectedBrands, selectedCategories) {
          setState(() {
            _selectedBrandIds = selectedBrands;
            _selectedCategoryIds = selectedCategories;
            visibleCount = pageSize;
          });
        },
      ),

      // 🔹 BODY
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.productList.isEmpty) {
          return const Center(child: Text("No products found"));
        }

        // Get sorted products
        final base = _getSortedDisplayProducts(controller.productList);

        // Apply filter by brands and categories
        final filtered = _filterProductsByBrandsAndCategories(base);

        // Apply UI sort
        final displayable = _applySortOption(filtered);

        // Only take visible count for display
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
                                      children: const [
                                        Icon(Icons.filter_list,
                                            size: 18, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'Filter',
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
                        SizedBox(height: 8,),
                        Row(
                          children: [
                            const Icon(Icons.inventory_2,
                                size: 18, color: kPrimaryColor),
                            SizedBox(width: 10,),
                            Text(
                              '${filtered.length} products found',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
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
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final crossAxisCount = width >= 900
                      ? 4
                      : width >= 600
                          ? 3
                          : 2;
                  final childAspectRatio = width < 360 ? 0.58 : 0.60;

                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return DealsProductCard(
                          offerName: _effectiveDisplayTitle,
                          productList: product,
                          onAddedToCart: _showAddedToCartPopup,
                        );
                      },
                      childCount: products.length,
                    ),
                  );
                },
              ),
            ),
            // Load More
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
                          child: const Text('Load More'),
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
