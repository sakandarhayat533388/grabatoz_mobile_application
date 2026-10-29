import 'dart:developer';

import 'dart:math' as math;

import 'package:flutter/foundation.dart'; // compute

import 'package:graba2z/Utils/product_sorting.dart'; // isolate sorter

import 'package:get/get.dart';


// import 'package:graba2z/Api/Models/productsModel.dart';

import 'package:graba2z/Controllers/searchController.dart';

import 'package:graba2z/Utils/appextensions.dart';

import 'package:graba2z/Views/Filter%20Screen/filter.dart';

import 'package:graba2z/Views/Product%20Folder/newProduct_card.dart';

import 'package:http/http.dart';

import '../../../../Utils/packages.dart';

import 'package:graba2z/Controllers/brand_controller.dart';

import 'package:graba2z/Controllers/home_controller.dart';


class SearchScreen extends StatefulWidget {

  const SearchScreen({super.key});


  @override

  State<SearchScreen> createState() => _SearchScreenState();

}


class _SearchScreenState extends State<SearchScreen> {

  final TextEditingController searchController = TextEditingController();


  double minPrice = 0;

  double maxPrice = 0;


  String brandName = '';

  String brandId = '';

  String firstName = '';

  String firstValue = '';

  String secondName = '';

  String secondValue = '';

  String thirdName = '';

  String thirdValue = '';


  String selectedBrand = '';

  String sortybyselection = '';

  String lastQuery = ''; // added: to prevent duplicate API calls for same query


  final BrandController _brandController =

      Get.put(BrandController(), permanent: true);

  final HomeController _homeController =

      Get.put(HomeController(), permanent: true);


  // Client-side pagination for search results

  static const int _pageSize = 10;

  int _visibleCount = _pageSize;

  bool _loadingMore = false; // NEW: bottom loader state


  // NEW: cache sorted list to avoid re-sorting on every build

  List<dynamic> _sortedProducts = const [];

  late Worker _sortedWorker;


  // Tailwind-like small green button style (same as All Products)

  ButtonStyle _webLikeLoadMoreStyle() {

    const Color green600 = Color(0xFF16A34A);

    const Color green700 = Color(0xFF15803D);

    return ButtonStyle(

      padding: MaterialStateProperty.all(

          const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),

      // px-3 py-1

      minimumSize: MaterialStateProperty.all(const Size(0, 32)),

      tapTargetSize: MaterialTapTargetSize.shrinkWrap,

      // fixed

      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),

      backgroundColor: MaterialStateProperty.resolveWith<Color>(

        (states) =>

            states.contains(MaterialState.pressed) ? green700 : green600,

      ),

      foregroundColor: MaterialStateProperty.all(Colors.white),

      elevation: MaterialStateProperty.all(4),

      shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.25)),

      shape: MaterialStateProperty.all(

        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),

      ),

      textStyle: MaterialStateProperty.all(

          const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),

      overlayColor: MaterialStateProperty.all(green700.withOpacity(0.12)),

    );

  }


  late Worker _resetOnFilterWorker; // listen to filter applies to reset UI

  int _drawerInstance = 0; // increments to force new drawer instance


  // Sort button UI state

  String _sortLabel = 'Newest First';

  bool _sortMenuOpen = false;


  // Helper to cap sort button width responsively

  double _calcSortMaxWidth(BoxConstraints c) =>

      math.min(220.0, c.maxWidth * 0.38);


  // Reusable sort menu button

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

        return base; // keep grouped order

    }

    available.sort(cmp);

    preorder.sort(cmp);

    outOfStock.sort(cmp);

    return [...available, ...preorder, ...outOfStock];

  }


  @override

  void initState() {

    super.initState();

    controller.addListener(_onScroll);

    _visibleCount = _pageSize; // show first 10 by default


    // Reset to first page only when filters are applied (val == true)

    _resetOnFilterWorker =

        ever<bool>(_searchScController.hasFilterApplied, (val) {

      if (val == true) {

        searchController.clear();

        lastQuery = '';

        _visibleCount = _pageSize;

        if (mounted) setState(() {});

      }

    });


    // NEW: recompute sorted list only when products change (debounced)

    _sortedWorker = debounce<List<dynamic>>(

      _searchScController.searhProducts,

      (_) => _recomputeSortedFromController(),

      time: const Duration(milliseconds: 60),

    );

  }


  Future<void> _recomputeSortedFromController() async {

    final listCopy = _searchScController.searhProducts.toList(growable: false);

    if (listCopy.isEmpty) {

      _sortedProducts = const [];

      if (mounted) setState(() {});

      return;

    }

    try {

      final sorted = await compute(sortProductsForDisplay, listCopy);

      _sortedProducts = sorted;

      if (mounted) setState(() {});

    } catch (_) {

      // Fallback to inline sort on error

      _sortedProducts = _getSortedDisplayProducts(listCopy);

      if (mounted) setState(() {});

    }

  }


  double _asDouble(dynamic v) {

    if (v == null) return 0;

    if (v is num) return v.toDouble();

    return double.tryParse(v.toString()) ?? 0;

  }


  bool _isSameQuery(String a, String b) =>

      a.toLowerCase() == b.toLowerCase(); // added


  // Stock order: Available -> PreOrder -> Out of Stock

  List<dynamic> _getSortedDisplayProducts(List<dynamic> productList) {

    if (productList.isEmpty) return [];

    final preorder = <dynamic>[];

    final available = <dynamic>[];

    final outOfStock = <dynamic>[];

    for (final e in productList) {

      if (e is! Map<String, dynamic>) {

        available.add(e);

        continue;

      }

      final s = (e['stockStatus'] ?? '').toString().toLowerCase();

      if (s == 'preorder' || s == 'pre order') {

        preorder.add(e);

      } else if (s == 'out of stock') {

        outOfStock.add(e);

      } else {

        available.add(e);

      }

    }

    // CHANGE: Available -> PreOrder -> Out of Stock

    return [...available, ...preorder, ...outOfStock];

  }


  Future<void> _ensureBrandsLoaded() async {

    if (_brandController.brandList.isNotEmpty) return;

    try {

      await _brandController.fetchBrands();

    } catch (_) {}

  }


  // Ensure categories and subcategories are loaded before matching IDs

  Future<void> _ensureCategoriesLoaded() async {

    if (_homeController.filterCategory.isEmpty) {

      try {

        await _homeController.getCategory();

      } catch (_) {}

    }

    if (_homeController.filterSubcategory.isEmpty) {

      try {

        await _homeController.getSubcategory();

      } catch (_) {}

    }

    // Small wait loop to allow GetX to populate lists

    int tries = 0;

    while ((_homeController.filterCategory.isEmpty ||

            _homeController.filterSubcategory.isEmpty) &&

        tries < 10) {

      await Future.delayed(const Duration(milliseconds: 150));

      tries++;

    }

  }


  // Resolve brand info (id + canonical name) for better token filtering

  Future<Map<String, String>?> _resolveBrandInfo(String q) async {

    await _ensureBrandsLoaded();

    if (_brandController.brandList.isEmpty) return null;

    final qq = q.toLowerCase().trim();

    // 1) exact name match

    for (final b in _brandController.brandList) {

      final name = (b?['name'] ?? '').toString();

      if (name.toLowerCase() == qq) {

        final id = (b?['_id'] ?? '').toString();

        if (id.isNotEmpty) return {'id': id, 'name': name};

      }

    }

    // 2) contains (longest)

    String? bestId;

    String? bestName;

    int bestLen = 0;

    for (final b in _brandController.brandList) {

      final name = (b?['name'] ?? '').toString();

      final n = name.toLowerCase();

      if (n.isNotEmpty && qq.contains(n) && n.length > bestLen) {

        bestLen = n.length;

        bestId = (b?['_id'] ?? '').toString();

        bestName = name;

      }

    }

    if (bestId != null && bestId.isNotEmpty)

      return {'id': bestId, 'name': bestName ?? ''};

    return null;

  }


  String _norm(String s) {

    s = s.toLowerCase().trim();

    if (s.endsWith('ies')) return s.substring(0, s.length - 3) + 'y';

    if (s.endsWith('es')) return s.substring(0, s.length - 2);

    if (s.endsWith('s')) return s.substring(0, s.length - 1);

    return s;

  }


  List<String> _tokenize(String s) => s

      .toLowerCase()

      .trim()

      .split(RegExp(r'\s+'))

      .where((t) => t.isNotEmpty)

      .toList();

  final Map<String, List<String>> _categorySynonyms = {

    'mobiles': [

      'mobile',

      'mobiles',

      'phone',

      'phones',

      'smartphone',

      'smartphones'

    ],

    'laptops': ['laptop', 'laptops', 'notebook', 'notebooks'],

    'printers': ['printer', 'printers', 'copier', 'copiers'],

    'desktops': [

      'desktop',

      'desktops',

      'pc',

      'pcs',

      'computer',

      'computers',

      'workstation',

      'workstations',

      'all in one',

      'aio'

    ],

  };


  bool _tokenMatches(String token, String name) {

    final t = _norm(token);

    final n = name.toLowerCase();

    if (n == t || n.startsWith(t) || t.startsWith(n) || n.contains(t))

      return true;

    for (final e in _categorySynonyms.entries) {

      final base = e.key;

      final aliases = e.value;

      if ((aliases.contains(token.toLowerCase()) || _norm(base) == t) &&

          (n == base || n.contains(base))) return true;

    }

    return false;

  }


  // Matchers from provided tokens (brand tokens can be removed before calling)

  String? _matchCategoryIdFromTokens(Iterable<String> tokens) {

    if (_homeController.filterCategory.isEmpty) return null;

    String? best;

    int bestLen = 0;

    for (final cat in _homeController.filterCategory) {

      final name = (cat.name ?? '');

      if (name.isEmpty) continue;

      for (final t in tokens) {

        if (_tokenMatches(t, name) && name.length > bestLen) {

          bestLen = name.length;

          best = (cat.sId ?? '');

        }

      }

    }

    return best;

  }


  String? _matchSubCategoryIdFromTokens(Iterable<String> tokens) {

    if (_homeController.filterSubcategory.isEmpty) return null;

    String? best;

    int bestLen = 0;

    for (final sub in _homeController.filterSubcategory) {

      final name = (sub.name ?? '');

      if (name.isEmpty) continue;

      for (final t in tokens) {

        if (_tokenMatches(t, name) && name.length > bestLen) {

          bestLen = name.length;

          best = (sub.sId ?? '');

        }

      }

    }

    return best;

  }


  // added: central search logic with tiered related queries

  Future<void> _performSearch(String raw) async {

    final q = raw.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Guard: too short, clear results and skip API

    if (q.length < 2) {

      _searchScController.searhProducts.clear();

      _searchScController.fetchedIds.clear();

      _searchScController.limit.value = 13;

      _searchScController.isMoreDataAvailableForShop.value = true;

      _searchScController.hasFilterApplied.value = false;

      _searchScController.setSearchQuery('');

      lastQuery = '';

      _visibleCount = _pageSize; // reset page size on clear

      setState(() {});

      return;

    }


    if (_isSameQuery(q, lastQuery)) return;


    // Reset state for new search

    _searchScController.searhProducts.clear();

    _searchScController.fetchedIds.clear();

    _visibleCount = _pageSize;

    setState(() {});


    // Show shimmer until single full fetch completes

    _searchScController.isrequesting.value = 1;


    // Fetch up to 2.5k for accurate total count

    _searchScController.limit.value = 2500;

    _searchScController.isMoreDataAvailableForShop.value = true;

    _searchScController.hasFilterApplied.value = false;


    await _ensureCategoriesLoaded();

    final brandInfo = await _resolveBrandInfo(q);

    final brandIdResolved = brandInfo?['id'] ?? '';

    final brandNameResolved = (brandInfo?['name'] ?? '').toLowerCase();

    final allTokens = _tokenize(q);

    final brandTokens = brandNameResolved.isNotEmpty

        ? _tokenize(brandNameResolved)

        : const <String>[];

    final remainingTokens =

        allTokens.where((t) => !brandTokens.contains(t)).toList();

    final matchedSubCategoryId = _matchSubCategoryIdFromTokens(remainingTokens);

    final matchedCategoryId = _matchCategoryIdFromTokens(remainingTokens);


    // 1) Brand + Subcategory

    if (brandIdResolved.isNotEmpty &&

        (matchedSubCategoryId?.isNotEmpty ?? false)) {

      await _searchScController.fetchAdsbysearchWithFilters(

        sortybyselection,

        'subcategory',

        matchedSubCategoryId!,

        'brand',

        brandIdResolved,

        '',

        '',

        0,

        0,

      );

      _searchScController.setSearchQuery(q);

      firstName = 'brand';

      firstValue = brandIdResolved;

      secondName = 'subcategory';

      secondValue = matchedSubCategoryId!;

      thirdName = '';

      thirdValue = '';

      lastQuery = q;

      _searchScController.isrequesting.value = 0;

      _searchScController.isMoreDataAvailableForShop.value =

          false; // stop further paging

      _visibleCount = _pageSize;

      setState(() {});

      return;

    }


    // 2) Brand + Category

    if (brandIdResolved.isNotEmpty &&

        (matchedCategoryId?.isNotEmpty ?? false)) {

      await _searchScController.fetchAdsbysearchWithFilters(

        sortybyselection,

        'parentCategory',

        matchedCategoryId!,

        '',

        '',

        'brand',

        brandIdResolved,

        0,

        0,

      );

      _searchScController.setSearchQuery(q);

      firstName = 'parentCategory';

      firstValue = matchedCategoryId!;

      secondName = 'brand';

      secondValue = brandIdResolved;

      thirdName = '';

      thirdValue = '';

      lastQuery = q;

      _searchScController.isrequesting.value = 0;

      _searchScController.isMoreDataAvailableForShop.value =

          false; // stop further paging

      _visibleCount = _pageSize;

      setState(() {});

      return;

    }


    // 3) Brand only

    if (brandIdResolved.isNotEmpty) {

      await _searchScController.fetchAdsbysearchWithFilters(

        sortybyselection,

        'brand',

        brandIdResolved,

        '',

        '',

        '',

        '',

        0,

        0,

      );

      _searchScController.setSearchQuery(q);

      firstName = 'brand';

      firstValue = brandIdResolved;

      secondName = '';

      secondValue = '';

      thirdName = '';

      thirdValue = '';

      lastQuery = q;

      _searchScController.isrequesting.value = 0;

      _searchScController.isMoreDataAvailableForShop.value =

          false; // stop further paging

      _visibleCount = _pageSize;

      setState(() {});

      return;

    }


    // 4) Category only

    if (matchedCategoryId?.isNotEmpty ?? false) {

      await _searchScController.fetchAdsbysearchWithFilters(

        sortybyselection,

        'parentCategory',

        matchedCategoryId!,

        '',

        '',

        '',

        '',

        0,

        0,

      );

      _searchScController.setSearchQuery(q);

      firstName = 'parentCategory';

      firstValue = matchedCategoryId!;

      secondName = '';

      secondValue = '';

      thirdName = '';

      thirdValue = '';

      lastQuery = q;

      _searchScController.isrequesting.value = 0;

      _searchScController.isMoreDataAvailableForShop.value =

          false; // stop further paging

      _visibleCount = _pageSize;

      setState(() {});

      return;

    }


    // 5) Subcategory only

    if (matchedSubCategoryId?.isNotEmpty ?? false) {

      await _searchScController.fetchAdsbysearchWithFilters(

        sortybyselection,

        'subcategory',

        matchedSubCategoryId!,

        '',

        '',

        '',

        '',

        0,

        0,

      );

      _searchScController.setSearchQuery(q);

      firstName = 'subcategory';

      firstValue = matchedSubCategoryId!;

      secondName = '';

      secondValue = '';

      thirdName = '';

      thirdValue = '';

      lastQuery = q;

      _searchScController.isrequesting.value = 0;

      _searchScController.isMoreDataAvailableForShop.value =

          false; // stop further paging

      _visibleCount = _pageSize;

      setState(() {});

      return;

    }


    // Primary: full query

    await _searchScController.fetchAdsbysearchWithFilters(

      sortybyselection,

      'search',

      q,

      '',

      '',

      '',

      '',

      0,

      0,

    );

    _searchScController.setSearchQuery(q);


    firstName = 'search';

    firstValue = q;

    secondName = '';

    secondValue = '';

    thirdName = '';

    thirdValue = '';

    lastQuery = q;


    _searchScController.isrequesting.value = 0;

    _searchScController.isMoreDataAvailableForShop.value =

        false; // stop further paging

    _visibleCount = _pageSize;

    setState(() {});

  }


  // Centered "Added to cart" overlay popup

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

                children: [

                  const Icon(Icons.shopping_cart, color: Colors.white, size: 24),

                  const SizedBox(width: 8),

                  Text(

                    'common_added_to_cart'.tr,

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


  final controller = ScrollController();


  void _onScroll() {

    // Skip pagination if we've fetched all

    if (!_searchScController.isMoreDataAvailableForShop.value) return;

    if (controller.position.maxScrollExtent == controller.offset) {

      _searchScController.fetchAdsbysearchWithFilters(

        sortybyselection,

        firstName,

        firstValue,

        secondName,

        secondValue,

        thirdName,

        thirdValue,

        minPrice,

        maxPrice,

      );

    }

  }


  Timer? _debounce;


  // Ensure a controller exists even if none was globally registered

  late final SearchScController _searchScController =

      Get.isRegistered<SearchScController>()

          ? Get.find<SearchScController>()

          : Get.put(SearchScController(), permanent: true);


  // Helper to drain pagination until all pages are fetched

  Future<void> _fetchAllWithSameParams(

    String sort,

    String p1n,

    String p1v,

    String p2n,

    String p2v,

    String p3n,

    String p3v,

    double minP,

    double maxP,

  ) async {

    // ...existing code...

  }


  // Apply filters using the same priority/params as _performSearch (brand/subcategory/category mapping)

  Future<void> _applyFiltersUsingUnifiedLogic(

      Map<String, dynamic> filters) async {

    // Reset/prepare for fetch and show immediate loading feedback

    _visibleCount = _pageSize;

    searchController.clear();

    _searchScController

        .setSearchQuery(''); // do not use clearSearchQuery() here

    _searchScController.limit.value = 2500; // fetch up to 2.5k

    _searchScController.searhProducts.clear();

    _searchScController.fetchedIds.clear();

    _searchScController.isMoreDataAvailableForShop.value = true;


    // Ensure shimmer renders

    if (_searchScController.itemCountsd.value <= 0) {

      _searchScController.itemCountsd.value = 12;

    }

    _searchScController.hasFilterApplied.value =

        true; // keep true so screen doesn't show empty-state

    _searchScController.isrequesting.value = 1;

    lastQuery = '';

    if (mounted) setState(() {});


    // Normalize inputs

    minPrice = _asDouble(filters['minPrice']);

    maxPrice = _asDouble(filters['maxPrice']);

    sortybyselection = (filters['sortBy'] ?? '').toString();


    // Use 0,0 when default range to mimic search behavior

    final bool isDefaultPrice = (minPrice <= 1) && (maxPrice >= 100000);

    final double apiMin = isDefaultPrice ? 0 : minPrice;

    final double apiMax = isDefaultPrice ? 0 : maxPrice;


    String sanitize(dynamic v) {

      final s = (v ?? '').toString().trim();

      final low = s.toLowerCase();

      if (s.isEmpty || low == 'all' || low == 'null' || low == 'none')

        return '';

      return s;

    }


    final String catId = sanitize(filters['parentCategoryId']);

    final String subId = sanitize(filters['subcategoryId']);

    final String brId = sanitize(filters['brandId']);


    // Helper: single fetch then stop pagination flags

    Future<void> _fetchOnce({

      required String p1n,

      required String p1v,

      String p2n = '',

      String p2v = '',

      String p3n = '',

      String p3v = '',

    }) async {

      await _searchScController.fetchAdsbysearchWithFilters(

        sortybyselection,

        p1n,

        p1v,

        p2n,

        p2v,

        p3n,

        p3v,

        apiMin,

        apiMax,

      );

      _searchScController.isrequesting.value = 0;

      _searchScController.isMoreDataAvailableForShop.value =

          false; // stop further paging

      _visibleCount = _pageSize;

      if (mounted) setState(() {});

    }


    try {

      if (brId.isNotEmpty && subId.isNotEmpty) {

        firstName = 'brand';

        firstValue = brId;

        secondName = 'subcategory';

        secondValue = subId;

        thirdName = '';

        thirdValue = '';

        await _fetchOnce(

            p1n: 'subcategory', p1v: subId, p2n: 'brand', p2v: brId);

        return;

      }


      if (brId.isNotEmpty && catId.isNotEmpty) {

        firstName = 'parentCategory';

        firstValue = catId;

        secondName = 'brand';

        secondValue = brId;

        thirdName = '';

        thirdValue = '';

        await _fetchOnce(

            p1n: 'parentCategory', p1v: catId, p3n: 'brand', p3v: brId);

        return;

      }


      if (brId.isNotEmpty) {

        firstName = 'brand';

        firstValue = brId;

        secondName = '';

        secondValue = '';

        thirdName = '';

        thirdValue = '';

        await _fetchOnce(p1n: 'brand', p1v: brId);

        return;

      }


      if (catId.isNotEmpty) {

        firstName = 'parentCategory';

        firstValue = catId;

        secondName = '';

        secondValue = '';

        thirdName = '';

        thirdValue = '';

        await _fetchOnce(p1n: 'parentCategory', p1v: catId);

        return;

      }


      if (subId.isNotEmpty) {

        firstName = 'subcategory';

        firstValue = subId;

        secondName = '';

        secondValue = '';

        thirdName = '';

        thirdValue = '';

        await _fetchOnce(p1n: 'subcategory', p1v: subId);

        return;

      }


      // No brand/category/subcategory: fetch by price/sort only

      firstName = '';

      firstValue = '';

      secondName = '';

      secondValue = '';

      thirdName = '';

      thirdValue = '';

      await _fetchOnce(p1n: '', p1v: '');

    } catch (_) {

      _searchScController.isrequesting.value = 0;

      _searchScController.isMoreDataAvailableForShop.value = false;

      if (mounted) setState(() {});

    }

  }


  @override

  void dispose() {

    // Cancel any pending debounce

    _debounce?.cancel();


    // Remove scroll listener and dispose controllers

    controller.removeListener(_onScroll);

    controller.dispose();

    searchController.dispose();


    // Dispose GetX worker

    _resetOnFilterWorker.dispose();

    // NEW: dispose debounce worker

    _sortedWorker.dispose();


    // Reset SearchScController state so the screen opens fresh next time

    try {

      _searchScController.limit.value = 13;

      _searchScController.isrequesting.value = 0;

      _searchScController.isMoreDataAvailableForShop.value = true;

      _searchScController.hasFilterApplied.value = false;

      _searchScController.searhProducts.clear();

      _searchScController.fetchedIds.clear();

      _searchScController.clearSearchQuery();

    } catch (_) {}


    // Reset local state holders

    firstName = '';

    firstValue = '';

    secondName = '';

    secondValue = '';

    thirdName = '';

    thirdValue = '';

    minPrice = 0;

    maxPrice = 0;

    brandName = '';

    brandId = '';

    lastQuery = '';

    _visibleCount = _pageSize;


    super.dispose();

  }

  @override

  Widget build(BuildContext context) {

    return SafeArea(

        child: GestureDetector(

      onTap: () {

        hideKeyboard(context);

      },

      child: Scaffold(

        endDrawer: FilterScreen(

          key: ValueKey(_drawerInstance), // force dispose/recreate on close

          onApplyFilters: (filters) async {

            // Use unified flow identical to search behavior

            await _applyFiltersUsingUnifiedLogic(filters);

          },

        ),

        onEndDrawerChanged: (isOpened) {

          if (!isOpened) {

            // Drawer just closed -> dispose current drawer subtree next build

            setState(() => _drawerInstance++);

          }

        },

        backgroundColor: context.colorScheme.surface,

        appBar: PreferredSize(

          preferredSize: const Size.fromHeight(130),

          child: Column(

            children: [

              Row(

                children: [

                  Padding(

                    padding: const EdgeInsets.only(left: 15),

                    child: GestureDetector(

                      onTap: () {

                        Navigator.pop(context);

                      },

                      child: Icon(

                        Icons.arrow_back_ios,

                      ),

                    ),

                  ),

                  Expanded(

                    child: Container(

                        height: 45,

                        width: searchController.text.isNotEmpty

                            ? Get.width * 0.8

                            : Get.width * 0.94,

                        decoration: BoxDecoration(

                          color: context.colorScheme.surface,

                          boxShadow: [

                            BoxShadow(

                              color: Colors.grey.withOpacity(.2),

                              spreadRadius: 2,

                              blurRadius: 1,

                              offset: const Offset(0, 1),

                            ),

                          ],

                          borderRadius: BorderRadius.circular(60),

                        ),

                        margin: const EdgeInsets.symmetric(

                            horizontal: 12, vertical: 10),

                        child: TextFormField(

                          // autofocus: true,

                          controller: searchController,

                          onChanged: (value) {

                            final trimmedValue = value.trim();

                            log('onChanged: "$trimmedValue"');


                            if (trimmedValue.isEmpty) {

                              log('Text is empty');

                              searchController.clear();

                              _searchScController.limit.value = 13;

                              _searchScController.isrequesting.value = 0;

                              _searchScController

                                  .isMoreDataAvailableForShop.value = true;

                              _searchScController.searhProducts.clear();

                              _searchScController.fetchedIds.clear();

                              Get.find<SearchScController>().clearSearchQuery();

                              lastQuery = '';

                              _visibleCount =

                                  _pageSize; // reset page size on clear

                            } else {

                              log('Text is NOT empty');

                              // Ensure next search starts from first 10 items

                              _visibleCount = _pageSize;


                              if (_debounce?.isActive ?? false)

                                _debounce!.cancel();


                              _debounce = Timer(

                                const Duration(milliseconds: 550),

                                () => _performSearch(

                                    trimmedValue), // pass trimmed

                              );

                            }


                            setState(() {});

                          },

                          decoration: InputDecoration(

                            hintText: 'search_hint'.tr,

                            border: InputBorder.none,

                            prefixIcon: const Icon(Icons.search),

                          ),

                        )),

                  ),

                  Visibility(

                    visible: searchController.text.isNotEmpty ? true : false,

                    child: Padding(

                      padding: const EdgeInsets.only(right: 10.0),

                      child: InkWell(

                        onTap: () {

                          searchController.clear();

                          _searchScController.limit.value = 13;

                          _searchScController.isrequesting.value = 0;

                          _searchScController.isMoreDataAvailableForShop.value =

                              true;

                          _searchScController.searhProducts.clear();

                          _searchScController.fetchedIds.clear();

                          Get.find<SearchScController>().clearSearchQuery();

                          firstName = '';

                          firstValue = '';

                          secondName = '';

                          secondValue = '';

                          thirdName = '';

                          thirdValue = '';

                          minPrice = 0;

                          maxPrice = 0;

                          brandName = '';

                          brandId = '';

                          lastQuery = ''; // added

                          _visibleCount = _pageSize; // reset page size on clear

                        },

                        child: Container(

                          height: 45,

                          width: 45,

                          decoration: BoxDecoration(

                            color: context.colorScheme.surface,

                            boxShadow: [

                              BoxShadow(

                                color: Colors.grey.withOpacity(0.2),

                                spreadRadius: 2,

                                blurRadius: 1,

                                offset: const Offset(0, 1),

                              ),

                            ],

                            borderRadius: BorderRadius.circular(80),

                          ),

                          child: Icon(

                            Icons.close,

                            color: context.colorScheme.onSurface,

                          ),

                        ),

                      ),

                    ),

                  ),

                ],

              ),

              Builder(builder: (context) {

                return GestureDetector(

                  onTap: () async {

                    // Forcefully unfocus any active TextField

                    FocusManager.instance.primaryFocus?.unfocus();

                    Scaffold.of(context).openEndDrawer();

                    log('its clicked');

                    // Wait for focus to clear properly

                    // await Future.delayed(Duration(milliseconds: 150));


                    // // Now safely navigate

                    // await _navigateAndApplyFilters();

                  },

                  child: Container(

                    width: Get.width,

                    padding: const EdgeInsets.symmetric(vertical: 10),

                    decoration: BoxDecoration(

                      gradient: LinearGradient(

                        begin: Alignment.topLeft,

                        end: Alignment.bottomRight,

                        colors: [

                          kSecondaryColor.withOpacity(.5),

                          kPrimaryColor,

                        ],

                      ),

                      boxShadow: [

                        BoxShadow(

                          color: context.colorScheme.primary.withOpacity(.3),

                          blurRadius: 8,

                          offset: const Offset(0, 3),

                        ),

                      ],

                    ),

                    child: Row(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        Image.asset(

                          "assets/icons/filter.png",

                          color: context.colorScheme.onPrimary,

                          width: 20,

                          height: 20,

                        ),

                        const SizedBox(width: 6),

                        Text(

                          'search_filter_by'.tr,

                          style: TextStyle(

                            fontSize: 16,

                            fontWeight: FontWeight.bold,

                            color: context.colorScheme.onPrimary,

                          ),

                        ),

                      ],

                    ),

                  ),

                );

              }),

            ],

          ),

        ),

        body: Obx(() {

          final controller1 = _searchScController;


          // 1️⃣ Search bar is empty

          if (controller1.searchQuery.trim().isEmpty &&

              controller1.hasFilterApplied.value == false) {

            return Padding(

              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),

              child: Column(

                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  Text(

                    'search_empty_title'.trParams({'dmy': controller1.dmy.value}),

                    textAlign: TextAlign.center,

                    style: TextStyle(

                      fontSize: 16,

                      fontWeight: FontWeight.bold,

                      color: context.colorScheme.primary,

                    ),

                  ),

                  const SizedBox(height: 10),

                  Text(

                    'search_empty_subtitle'.tr,

                    textAlign: TextAlign.center,

                    style: TextStyle(fontSize: 14),

                  ),

                ],

              ),

            );

          }


          // 2️⃣ Show shimmer while draining pages (regardless of current list length)

          if (controller1.isrequesting.value == 1) {

            return Padding(

              padding: const EdgeInsets.symmetric(horizontal: 5),

              child: GridView.builder(

                itemCount: controller1.itemCountsd.value,

                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(

                  crossAxisCount: 2,

                  childAspectRatio: 0.64,

                ),

                itemBuilder: (context, index) {

                  return Shimmer.fromColors(

                    baseColor: Colors.grey.shade300,

                    highlightColor: Colors.grey.shade100,

                    child: Container(

                      margin: const EdgeInsets.all(8.0),

                      decoration: BoxDecoration(

                        color: Colors.white,

                        borderRadius: BorderRadius.circular(12.0),

                      ),

                    ),

                  );

                },

              ),

            );

          }


          // 3️⃣ No results found

          if (controller1.searhProducts.isEmpty &&

              controller1.isrequesting.value == 0) {

            return Center(

              child: Column(

                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  const Icon(Icons.search_off, size: 60, color: Colors.grey),

                  const SizedBox(height: 10),

                  Text(

                    'search_no_results'.trParams({'dmy': controller1.dmy.value}),

                    style: const TextStyle(fontSize: 16, color: Colors.grey),

                  ),

                ],

              ),

            );

          }

          // 4️⃣ Show fetched products with accurate total count

          // NEW: use cached sorted products; if cache is empty, fall back to inline sort

          final base = _sortedProducts.isNotEmpty

              ? _sortedProducts

              : _getSortedDisplayProducts(controller1.searhProducts);

          final sortedForView = _applySortOption(base);

          final visibleProducts = sortedForView.take(_visibleCount).toList();


          return SafeArea(

            child: CustomScrollView(

              // Do NOT attach the infinite scroll controller here to avoid API pagination

              slivers: [

                // Header with responsive sort button

                SliverToBoxAdapter(

                  child: Padding(

                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),

                    child: LayoutBuilder(

                      builder: (context, constraints) {

                        final maxW = _calcSortMaxWidth(constraints);

                        return Row(

                          children: [

                            Icon(Icons.inventory_2,

                                size: 18, color: kPrimaryColor),

                            const SizedBox(width: 6),

                            Expanded(

                              child: Row(

                                children: [

                                  Text(

                                    'search_products_count'.trParams({'count': sortedForView.length.toString()}),

                                    style: const TextStyle(

                                        fontSize: 14,

                                        fontWeight: FontWeight.w700),

                                    overflow: TextOverflow.ellipsis,

                                  ),

                                  if (controller1.searchQuery

                                      .trim()

                                      .isNotEmpty) ...[

                                    const SizedBox(width: 6),

                                    Flexible(

                                      child: Text(

                                        'search_for_query'.trParams({'query': controller1.searchQuery.trim()}),

                                        style: const TextStyle(

                                            fontSize: 14,

                                            color: kSecondaryColor,

                                            fontWeight: FontWeight.w600),

                                        overflow: TextOverflow.ellipsis,

                                      ),

                                    ),

                                  ],

                                ],

                              ),

                            ),

                            const SizedBox(width: 8),

                            SizedBox(

                              width: maxW,

                              child: _sortMenuButton(),

                            ),

                          ],

                        );

                      },

                    ),

                  ),

                ),

                SliverPadding(

                  padding: const EdgeInsets.symmetric(horizontal: 5),

                  sliver: SliverGrid(

                    gridDelegate:

                        const SliverGridDelegateWithFixedCrossAxisCount(

                      crossAxisCount: 2,

                      childAspectRatio: 0.64,

                    ),

                    delegate: SliverChildBuilderDelegate(

                      (context, index) {

                        final item = visibleProducts[index];

                        return NewProductCard(

                          prdouctList: item,

                          onAddedToCart: _showAddedToCartPopup,

                        );

                      },

                      childCount: visibleProducts.length,

                      addAutomaticKeepAlives: false, // perf: less overhead

                      addRepaintBoundaries: true,

                      addSemanticIndexes: false,

                    ),

                  ),

                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                SliverToBoxAdapter(

                  child: Padding(

                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),

                    child: Center(

                      child: (controller1.isMoreDataAvailableForShop.value ||

                              _visibleCount < sortedForView.length)

                          ? ElevatedButton(

                              style: _webLikeLoadMoreStyle(),

                              onPressed: () async {

                                if (controller1

                                    .isMoreDataAvailableForShop.value) {

                                  if (_loadingMore) return;

                                  setState(() => _loadingMore = true);

                                  try {

                                    await _searchScController

                                        .fetchAdsbysearchWithFilters(

                                      sortybyselection,

                                      firstName,

                                      firstValue,

                                      secondName,

                                      secondValue,

                                      thirdName,

                                      thirdValue,

                                      minPrice,

                                      maxPrice,

                                    );

                                  } finally {

                                    if (mounted)

                                      setState(() => _loadingMore = false);

                                  }

                                } else {

                                  final total = sortedForView.length;

                                  final next = _visibleCount + _pageSize;

                                  setState(() {

                                    _visibleCount = next > total ? total : next;

                                  });

                                }

                              },

                              child: _loadingMore

                                  ? Row(

                                      mainAxisSize: MainAxisSize.min,

                                      children: [

                                        const SizedBox(

                                            width: 14,

                                            height: 14,

                                            child: CircularProgressIndicator(

                                                strokeWidth: 2,

                                                color: Colors.white)),

                                        const SizedBox(width: 8),

                                        Text('loading'.tr),

                                      ],

                                    )

                                  : Text('common_load_more'.tr),

                            )

                          : const SizedBox.shrink(),

                    ),

                  ),

                ),

                const SliverToBoxAdapter(child: SizedBox(height: 60)),

              ],

            ),

          );

        }),

      ),

    ));

  }

}
