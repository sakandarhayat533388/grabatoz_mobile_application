import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graba2z/Utils/appextensions.dart';
import '../../../../Controllers/addtocart.dart';
import '../../../../Controllers/bottomController.dart';
import '../../../../Controllers/productcontroller.dart';
import '../../../../Utils/appcolors.dart';
import '../../../../Widgets/customappbar.dart';
import '../../../Product Folder/newProduct_card.dart';
import '../Cart/cart.dart';
import '../Search Screen/searchscreensecond.dart';
import 'shop_category_filter.dart';

const String _homeSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 12L12 4L20 12" />
  <path d="M5 12V20H10V15H14V20H19V12" />
</svg>
''';

class Shop extends StatefulWidget {
  final String? id;
  final String? parentType;
  final String? displayTitle;
  final String? slug;

  const Shop({
    Key? key,
    required this.id,
    required this.parentType,
    this.displayTitle,
    this.slug,
  }) : super(key: key);

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> {
  late final ShopController controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final String _controllerTag;

  static const int pageSize = 12;
  int visibleCount = pageSize;

  // Current title - changes when category is selected
  String? _currentTitle;

  // Filter state
  String? _filterCategoryId;
  String? _filterSubCategoryId;
  List<String> _selectedBrandIds = [];
  List<String> _selectedMakeIds = [];
  List<String> _selectedModelIds = [];
  List<String> _selectedSeriesIds = [];
  List<String> _selectedManufacturerIds = [];
  List<String> _selectedSoldByIds = [];
  double _filterMinPrice = 0;
  double _filterMaxPrice = 100000;
  String? _activeProductId;
  String? _activeParentType;
  int _filterDrawerVersion = 0;
  bool _hasAppliedDrawerSelection = false;

  @override
  void initState() {
    super.initState();

    // Create unique tag for this Shop instance
    _controllerTag =
        'shop_${widget.id ?? 'default'}_${DateTime.now().millisecondsSinceEpoch}';
    controller = Get.put(ShopController(), tag: _controllerTag);
    _activeProductId = widget.id;
    _activeParentType = widget.parentType;
    controller.fetchProducts(
      id: widget.id,
      parentType: widget.parentType,
    );
    log("Fetching products for id=${widget.id}, parentType=${widget.parentType}");
  }

  @override
  void didUpdateWidget(covariant Shop oldWidget) {
    super.didUpdateWidget(oldWidget);

    final routeFilterChanged =
        oldWidget.id != widget.id || oldWidget.parentType != widget.parentType;
    if (!routeFilterChanged) return;

    setState(() {
      visibleCount = pageSize;
      _filterCategoryId = null;
      _filterSubCategoryId = null;
      _selectedBrandIds = [];
      _selectedMakeIds = [];
      _selectedModelIds = [];
      _selectedSeriesIds = [];
      _selectedManufacturerIds = [];
      _selectedSoldByIds = [];
      _activeProductId = widget.id;
      _activeParentType = widget.parentType;
      _currentTitle = null;
      _hasAppliedDrawerSelection = false;
      _filterDrawerVersion++;
    });

    controller.fetchProducts(
      id: widget.id,
      parentType: widget.parentType,
    );
    log("Route category changed, fetching products for id=${widget.id}, parentType=${widget.parentType}");
  }

  @override
  void dispose() {
    // Clean up controller when leaving
    Get.delete<ShopController>(tag: _controllerTag);
    super.dispose();
  }

  double _calcSortMaxWidth(BoxConstraints c) =>
      math.min(220.0, c.maxWidth * 0.38);
  List<dynamic> _sortedLocalProducts = const [];

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
      onSelected: (val) {
        setState(() {
          _sortLabel = val;
          _sortMenuOpen = false;
          visibleCount = pageSize;
        });
        if (_hasSystemFilters) {
          _fetchActiveProducts();
        }
      },
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

  bool get _hasSystemFilters =>
      _selectedMakeIds.isNotEmpty ||
      _selectedModelIds.isNotEmpty ||
      _selectedSeriesIds.isNotEmpty ||
      _selectedManufacturerIds.isNotEmpty ||
      _selectedSoldByIds.isNotEmpty;

  String _sortApiValue() {
    switch (_sortLabel) {
      case 'Price: Low to High':
        return 'price-low';
      case 'Price: High to Low':
        return 'price-high';
      case 'Name: A to Z':
        return 'name';
      case 'Newest First':
      default:
        return 'newest';
    }
  }

  Future<void> _fetchActiveProducts() {
    return controller.fetchProducts(
      id: _activeProductId,
      parentType: _activeParentType,
      makeIds: _selectedMakeIds,
      modelIds: _selectedModelIds,
      seriesIds: _selectedSeriesIds,
      manufacturerIds: _selectedManufacturerIds,
      soldByIds: _selectedSoldByIds,
      sortBy: _sortApiValue(),
    );
  }

  String? get _drawerInitialCategoryId {
    if (_hasAppliedDrawerSelection) return _filterCategoryId;
    return widget.parentType == 'parentCategory' ? widget.id : null;
  }

  String? get _drawerInitialSubCategoryId {
    if (_hasAppliedDrawerSelection) return _filterSubCategoryId;
    return widget.parentType == 'subcategory' ? widget.id : null;
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
        (states) => states.contains(MaterialState.pressed)
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
      // First try to get offerPrice
      final offerPrice = e['offerPrice'];
      num? offerPriceNum;

      if (offerPrice is num) {
        offerPriceNum = offerPrice;
      } else if (offerPrice is String) {
        offerPriceNum = num.tryParse(offerPrice);
      }

      // If offerPrice exists and is greater than 0, use it
      if (offerPriceNum != null && offerPriceNum > 0) {
        return offerPriceNum;
      }

      // Otherwise, fallback to regular price
      final price = e['price'];
      if (price is num) return price;
      if (price is String) {
        final n = num.tryParse(price);
        if (n != null) return n;
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

  // Apply the selected sorting inside stock groups, then combine (Available -> PreOrder -> Out of Stock)
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
        // Preserve incoming order (already grouped)
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
        // Treat all other/unknown as available
        availableItems.add(product);
      }
    }
    // CHANGE: Available -> PreOrder -> Out of Stock
    return [...availableItems, ...preorderItems, ...outOfStockItems];
  }

  // Apply filters from drawer
  void _applyFilters(Map<String, dynamic> filters) {
    final selectedId = filters['selectedId']?.toString() ?? '';
    final parentType = filters['parentType']?.toString() ?? '';
    final title = filters['title']?.toString() ?? '';
    final categoryId = filters['categoryId']?.toString() ?? '';
    final subCategoryId = filters['subCategoryId']?.toString() ?? '';
    final selectedBrandIds = (filters['selectedBrandIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final selectedMakeIds = (filters['selectedMakeIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final selectedModelIds = (filters['selectedModelIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final selectedSeriesIds = (filters['selectedSeriesIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final selectedManufacturerIds =
        (filters['selectedManufacturerIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList() ??
            [];
    final selectedSoldByIds = (filters['selectedSoldByIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    // Reset case: all filters empty.
    if (selectedId.isEmpty &&
        parentType.isEmpty &&
        selectedBrandIds.isEmpty &&
        selectedMakeIds.isEmpty &&
        selectedModelIds.isEmpty &&
        selectedSeriesIds.isEmpty &&
        selectedManufacturerIds.isEmpty &&
        selectedSoldByIds.isEmpty) {
      log('Reset filters detected - restoring original state');

      setState(() {
        visibleCount = pageSize;
        _filterCategoryId = null;
        _filterSubCategoryId = null;
        _selectedBrandIds = [];
        _selectedMakeIds = [];
        _selectedModelIds = [];
        _selectedSeriesIds = [];
        _selectedManufacturerIds = [];
        _selectedSoldByIds = [];
        _activeProductId = widget.id;
        _activeParentType = widget.parentType;
        _currentTitle = null;
        _hasAppliedDrawerSelection = false;
        _filterDrawerVersion++;
      });
      _fetchActiveProducts();
      return;
    }

    final hadSystemFilters = _hasSystemFilters;

    // If a specific category/subcategory is selected, fetch products for that category.
    if (selectedId.isNotEmpty && parentType.isNotEmpty) {
      setState(() {
        visibleCount = pageSize;
        _filterCategoryId = categoryId.isNotEmpty ? categoryId : selectedId;
        _filterSubCategoryId = subCategoryId.isNotEmpty ? subCategoryId : null;
        _selectedBrandIds = selectedBrandIds;
        _selectedMakeIds = selectedMakeIds;
        _selectedModelIds = selectedModelIds;
        _selectedSeriesIds = selectedSeriesIds;
        _selectedManufacturerIds = selectedManufacturerIds;
        _selectedSoldByIds = selectedSoldByIds;
        _activeProductId = selectedId;
        _activeParentType = parentType;
        _currentTitle = title.isNotEmpty ? title : null;
        _hasAppliedDrawerSelection = true;
        _filterDrawerVersion++;
      });

      _fetchActiveProducts();
      log('Fetching products for: id=$selectedId, parentType=$parentType, title=$title, brands=$selectedBrandIds, makes=$selectedMakeIds, models=$selectedModelIds, series=$selectedSeriesIds, manufacturers=$selectedManufacturerIds, soldBy=$selectedSoldByIds');
      return;
    }

    setState(() {
      visibleCount = pageSize;
      _filterCategoryId = null;
      _filterSubCategoryId = null;
      _selectedBrandIds = selectedBrandIds;
      _selectedMakeIds = selectedMakeIds;
      _selectedModelIds = selectedModelIds;
      _selectedSeriesIds = selectedSeriesIds;
      _selectedManufacturerIds = selectedManufacturerIds;
      _selectedSoldByIds = selectedSoldByIds;
      _activeProductId = widget.id;
      _activeParentType = widget.parentType;
      _currentTitle = null;
      _hasAppliedDrawerSelection = true;
      _filterDrawerVersion++;
    });

    if (_hasSystemFilters || hadSystemFilters) {
      _fetchActiveProducts();
      log('System filter applied: makes=$selectedMakeIds, models=$selectedModelIds, series=$selectedSeriesIds, manufacturers=$selectedManufacturerIds, soldBy=$selectedSoldByIds');
      return;
    }

    log('Brand filter applied: $selectedBrandIds');
  }

  // Filter products based on current filter state (brand filter is local)
  List<dynamic> _applyLocalFilters(List<dynamic> products) {
    if (products.isEmpty) return products;

    // If no brand filter, return all products
    if (_selectedBrandIds.isEmpty) {
      return products;
    }

    // Filter by selected brands
    return products.where((product) {
      if (product is! Map<String, dynamic>) return false;

      // Get brand ID from product
      String? productBrandId;
      final brand = product['brand'];
      if (brand is Map<String, dynamic>) {
        productBrandId = brand['_id']?.toString();
      } else if (brand is String) {
        productBrandId = brand;
      }

      // Check if product brand is in selected brands
      if (productBrandId != null &&
          _selectedBrandIds.contains(productBrandId)) {
        return true;
      }

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Get.put(BottomNavigationController());
    return Scaffold(
      key: _scaffoldKey,
      onEndDrawerChanged: (isOpened) {
        if (!isOpened && mounted) {
          setState(() {
            _filterDrawerVersion++;
          });
        }
      },
      endDrawer: ShopCategoryFilter(
        key: ValueKey(
          'shop-filter-$_filterDrawerVersion-${_drawerInitialCategoryId ?? ''}-${_drawerInitialSubCategoryId ?? ''}',
        ),
        onApplyFilters: _applyFilters,
        initialCategoryId: _drawerInitialCategoryId,
        initialSubCategoryId: _drawerInitialSubCategoryId,
        products: controller.productList,
        initialSelectedBrands: _selectedBrandIds,
        initialSelectedMakes: _selectedMakeIds,
        initialSelectedModels: _selectedModelIds,
        initialSelectedSeries: _selectedSeriesIds,
        initialSelectedManufacturers: _selectedManufacturerIds,
        initialSelectedSoldBy: _selectedSoldByIds,
      ),
      appBar: CustomAppBar(
          showLeading: true,
          leadingWidget: Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  if (widget.id == '2') {
                    navigationProvider.setTabIndex(0);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.arrow_back_ios, size: 20),
              );
            },
          ),
          titleText: _currentTitle ?? widget.displayTitle,
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

      // 🔹 BODY
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.productList.isEmpty) {
          return const Center(child: Text("No products found"));
        }

        // Apply local filters first
        final filteredProducts = _applyLocalFilters(controller.productList);

        final base = _sortedLocalProducts.isNotEmpty
            ? _sortedLocalProducts
            : _getSortedDisplayProducts(filteredProducts);

        // Apply UI sort
        final displayable = _applySortOption(base);
        final products = displayable.take(visibleCount).toList();

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
                                _scaffoldKey.currentState?.openEndDrawer();
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
                        SizedBox(
                          height: 8,
                        ),
                        Row(
                          children: [
                            const Icon(Icons.inventory_2,
                                size: 18, color: kPrimaryColor),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              '${filteredProducts.length} products found',
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
                  child: (visibleCount < displayable.length)
                      ? ElevatedButton(
                          style: _webLikeLoadMoreStyle(),
                          onPressed: () {
                            final total = displayable.length;
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
