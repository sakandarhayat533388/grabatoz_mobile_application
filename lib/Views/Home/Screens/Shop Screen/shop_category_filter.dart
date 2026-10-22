import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:graba2z/Api/Models/menumodel.dart';
import 'package:graba2z/Controllers/menuController.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Utils/appcolors.dart';

class ProductSystemOption {
  final String id;
  final String name;

  const ProductSystemOption({
    required this.id,
    required this.name,
  });
}

class _SystemOptionsCacheEntry {
  final List<ProductSystemOption> makeOptions;
  final List<ProductSystemOption> modelOptions;
  final List<ProductSystemOption> seriesOptions;
  final List<ProductSystemOption> manufacturerOptions;
  final List<ProductSystemOption> soldByOptions;

  _SystemOptionsCacheEntry({
    required List<ProductSystemOption> makeOptions,
    required List<ProductSystemOption> modelOptions,
    required List<ProductSystemOption> seriesOptions,
    required List<ProductSystemOption> manufacturerOptions,
    required List<ProductSystemOption> soldByOptions,
  })  : makeOptions = List<ProductSystemOption>.unmodifiable(makeOptions),
        modelOptions = List<ProductSystemOption>.unmodifiable(modelOptions),
        seriesOptions = List<ProductSystemOption>.unmodifiable(seriesOptions),
        manufacturerOptions =
            List<ProductSystemOption>.unmodifiable(manufacturerOptions),
        soldByOptions = List<ProductSystemOption>.unmodifiable(soldByOptions);
}

class ShopCategoryFilter extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;
  final String? initialCategoryId;
  final String? initialSubCategoryId;
  final List<dynamic> products; // Products list to extract brands
  final List<String>? initialSelectedBrands; // Initially selected brands
  final List<String>? initialSelectedMakes;
  final List<String>? initialSelectedModels;
  final List<String>? initialSelectedSeries;
  final List<String>? initialSelectedManufacturers;
  final List<String>? initialSelectedSoldBy;

  const ShopCategoryFilter({
    super.key,
    required this.onApplyFilters,
    this.initialCategoryId,
    this.initialSubCategoryId,
    this.products = const [],
    this.initialSelectedBrands,
    this.initialSelectedMakes,
    this.initialSelectedModels,
    this.initialSelectedSeries,
    this.initialSelectedManufacturers,
    this.initialSelectedSoldBy,
  });

  @override
  State<ShopCategoryFilter> createState() => _ShopCategoryFilterState();
}

class _ShopCategoryFilterState extends State<ShopCategoryFilter> {
  static String? _cachedSystemOptionsKey;
  static _SystemOptionsCacheEntry? _cachedSystemOptions;

  final menuController _menuController = Get.find<menuController>();

  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedTitle; // Store selected category/subcategory title
  final Set<String> _expandedCategories = {};
  bool _isCategorySectionExpanded = true;

  // Brand filter
  final Map<String, String> _allBrandsMap =
      {}; // All brands from API: {id: name}
  List<Map<String, String>> _availableBrands = []; // Brands in current products
  Set<String> _selectedBrandIds = {};
  bool _isBrandSectionExpanded = true;
  bool _isBrandsLoading = true;

  // Make/model filters
  List<ProductSystemOption> _makeOptions = [];
  List<ProductSystemOption> _modelOptions = [];
  List<ProductSystemOption> _seriesOptions = [];
  List<ProductSystemOption> _manufacturerOptions = [];
  List<ProductSystemOption> _soldByOptions = [];
  Set<String> _selectedMakeIds = {};
  Set<String> _selectedModelIds = {};
  Set<String> _selectedSeriesIds = {};
  Set<String> _selectedManufacturerIds = {};
  Set<String> _selectedSoldByIds = {};
  bool _isMakeSectionExpanded = true;
  bool _isModelSectionExpanded = true;
  bool _isSeriesSectionExpanded = true;
  bool _isManufacturerSectionExpanded = true;
  bool _isSoldBySectionExpanded = true;
  bool _isMakesLoading = false;
  bool _isModelsLoading = false;
  bool _isSeriesLoading = false;
  bool _isManufacturersLoading = false;
  bool _isSoldByLoading = false;
  int _systemOptionRequestId = 0;

  @override
  void initState() {
    super.initState();
    _syncStateFromWidget();

    // Fetch all brands from API, then extract brands from products
    _fetchAllBrands();
    _refreshSystemOptionsForSelection();
  }

  @override
  void didUpdateWidget(covariant ShopCategoryFilter oldWidget) {
    super.didUpdateWidget(oldWidget);

    final selectionChanged =
        oldWidget.initialCategoryId != widget.initialCategoryId ||
            oldWidget.initialSubCategoryId != widget.initialSubCategoryId;
    final filterSelectionsChanged = !_sameStringSet(
          oldWidget.initialSelectedBrands,
          widget.initialSelectedBrands,
        ) ||
        !_sameStringSet(
          oldWidget.initialSelectedMakes,
          widget.initialSelectedMakes,
        ) ||
        !_sameStringSet(
          oldWidget.initialSelectedModels,
          widget.initialSelectedModels,
        ) ||
        !_sameStringSet(
          oldWidget.initialSelectedSeries,
          widget.initialSelectedSeries,
        ) ||
        !_sameStringSet(
          oldWidget.initialSelectedManufacturers,
          widget.initialSelectedManufacturers,
        ) ||
        !_sameStringSet(
          oldWidget.initialSelectedSoldBy,
          widget.initialSelectedSoldBy,
        );

    if (selectionChanged || filterSelectionsChanged) {
      setState(() {
        _syncStateFromWidget();
      });
    }

    if (selectionChanged) {
      _refreshSystemOptionsForSelection();
    }
  }

  void _syncStateFromWidget() {
    _selectedCategoryId = widget.initialCategoryId ?? 'all';
    _selectedSubCategoryId = widget.initialSubCategoryId;
    _selectedTitle = null;
    _expandedCategories.clear();
    _selectedBrandIds = Set<String>.from(widget.initialSelectedBrands ?? []);
    _selectedMakeIds = Set<String>.from(widget.initialSelectedMakes ?? []);
    _selectedModelIds = Set<String>.from(widget.initialSelectedModels ?? []);
    _selectedSeriesIds = Set<String>.from(widget.initialSelectedSeries ?? []);
    _selectedManufacturerIds =
        Set<String>.from(widget.initialSelectedManufacturers ?? []);
    _selectedSoldByIds = Set<String>.from(widget.initialSelectedSoldBy ?? []);

    if (_selectedCategoryId != null && _selectedCategoryId != 'all') {
      _expandedCategories.add(_selectedCategoryId!);
    }

    if (_selectedSubCategoryId != null && _selectedSubCategoryId!.isNotEmpty) {
      final parentCategoryId =
          _findParentCategoryIdForSubcategory(_selectedSubCategoryId!);
      if (parentCategoryId != null && parentCategoryId.isNotEmpty) {
        _selectedCategoryId = parentCategoryId;
      }

      if (_selectedCategoryId != null && _selectedCategoryId != 'all') {
        _expandedCategories.add(_selectedCategoryId!);
      }
      _expandedCategories.add(_selectedSubCategoryId!);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _expandParentCategoriesForSubcategory(_selectedSubCategoryId!);
        }
      });
    }
  }

  String? _findParentCategoryIdForSubcategory(String subcategoryId) {
    for (final category in _menuController.categories) {
      if (_containsChildCategory(category.children, subcategoryId)) {
        return category.id;
      }
    }
    return null;
  }

  bool _containsChildCategory(List<Child> children, String targetId) {
    for (final child in children) {
      if (child.id == targetId) return true;
      if (_containsChildCategory(child.children, targetId)) return true;
    }
    return false;
  }

  bool _sameStringSet(List<String>? a, List<String>? b) {
    final left = Set<String>.from(a ?? const []);
    final right = Set<String>.from(b ?? const []);
    return left.length == right.length && left.containsAll(right);
  }

  // Find and expand all parent categories for a given subcategory
  void _expandParentCategoriesForSubcategory(String subcategoryId) {
    bool found = false;
    // Search through all categories to find the path to this subcategory
    for (final category in _menuController.categories) {
      final categoryId = category.id;
      if (_findAndExpandPath(category.children, subcategoryId, categoryId)) {
        _expandedCategories.add(categoryId);
        found = true;
        break;
      }
    }

    // Refresh UI if we found and expanded categories
    if (found && mounted) {
      setState(() {});
    }
  }

  // Recursively find subcategory and expand the path
  bool _findAndExpandPath(
      List<Child> children, String targetId, String parentId) {
    for (final child in children) {
      if (child.id == targetId) {
        return true;
      }
      if (child.children.isNotEmpty) {
        if (_findAndExpandPath(child.children, targetId, child.id)) {
          _expandedCategories.add(child.id);
          return true;
        }
      }
    }
    return false;
  }

  // Fetch all brands from API
  Future<void> _fetchAllBrands() async {
    try {
      if (mounted) {
        setState(() => _isBrandsLoading = true);
      }

      final response = await http.get(Uri.parse(Configss.getallbrands));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          for (final brand in data) {
            if (brand is Map<String, dynamic>) {
              final brandId = brand['_id']?.toString() ?? '';
              final brandName = brand['name']?.toString() ?? '';
              if (brandId.isNotEmpty && brandName.isNotEmpty) {
                _allBrandsMap[brandId] = brandName;
              }
            }
          }
        }

        log('Fetched ${_allBrandsMap.length} brands from API');
      }
    } catch (e) {
      log('Error fetching brands: $e');
    } finally {
      if (mounted) {
        // Now extract brands from products using the map
        _extractBrandsFromProducts();
        setState(() => _isBrandsLoading = false);
      }
    }
  }

  Future<void> _refreshSystemOptionsForSelection() async {
    final requestId = ++_systemOptionRequestId;

    if (!_hasSpecificCategorySelection) {
      if (mounted) {
        setState(() {
          _makeOptions = [];
          _modelOptions = [];
          _seriesOptions = [];
          _manufacturerOptions = [];
          _soldByOptions = [];
          _selectedMakeIds.clear();
          _selectedModelIds.clear();
          _selectedSeriesIds.clear();
          _selectedManufacturerIds.clear();
          _selectedSoldByIds.clear();
          _isMakesLoading = false;
          _isModelsLoading = false;
          _isSeriesLoading = false;
          _isManufacturersLoading = false;
          _isSoldByLoading = false;
        });
      }
      return;
    }

    final cacheKey = _systemOptionsCacheKey;
    final cachedOptions = _cachedSystemOptions;
    if (cacheKey == _cachedSystemOptionsKey && cachedOptions != null) {
      if (mounted) {
        setState(() {
          _applySystemOptions(cachedOptions);
          _isMakesLoading = false;
          _isModelsLoading = false;
          _isSeriesLoading = false;
          _isManufacturersLoading = false;
          _isSoldByLoading = false;
        });
      }
      log('Using cached make/model options for selected category');
      return;
    }

    if (mounted) {
      setState(() {
        _isMakesLoading = true;
        _isModelsLoading = true;
        _isSeriesLoading = true;
        _isManufacturersLoading = true;
        _isSoldByLoading = true;
      });
    }

    try {
      final localProducts = _filterProductsForSelectedCategory(widget.products);
      final responses = await Future.wait([
        _fetchProductsForSelectedCategory(),
        _fetchProductSystemOptionsById('series'),
        _fetchProductSystemOptionsById('manufacturer'),
        _fetchProductSystemOptionsById('sold-by'),
      ]);
      if (!mounted || requestId != _systemOptionRequestId) return;

      final fetchedProducts = responses[0] as List<dynamic>;
      final seriesNamesById = responses[1] as Map<String, String>;
      final manufacturerNamesById = responses[2] as Map<String, String>;
      final soldByNamesById = responses[3] as Map<String, String>;
      final fetchedScopedProducts =
          _filterProductsForSelectedCategory(fetchedProducts);
      final sourceProducts = fetchedScopedProducts.isNotEmpty
          ? fetchedScopedProducts
          : localProducts;
      final makeOptions = _extractOptionsFromProducts(sourceProducts, 'make');
      final modelOptions = _extractOptionsFromProducts(sourceProducts, 'model');
      final seriesOptions = _extractOptionsFromProducts(
        sourceProducts,
        'series',
        optionNamesById: seriesNamesById,
      );
      final manufacturerOptions = _extractOptionsFromProducts(
        sourceProducts,
        'manufacturer',
        optionNamesById: manufacturerNamesById,
      );
      final soldByOptions = _extractOptionsFromProducts(
        sourceProducts,
        'soldBy',
        optionNamesById: soldByNamesById,
      );
      final makeIds = makeOptions.map((option) => option.id).toSet();
      final modelIds = modelOptions.map((option) => option.id).toSet();
      final seriesIds = seriesOptions.map((option) => option.id).toSet();
      final manufacturerIds =
          manufacturerOptions.map((option) => option.id).toSet();
      final soldByIds = soldByOptions.map((option) => option.id).toSet();

      final cacheEntry = _SystemOptionsCacheEntry(
        makeOptions: makeOptions,
        modelOptions: modelOptions,
        seriesOptions: seriesOptions,
        manufacturerOptions: manufacturerOptions,
        soldByOptions: soldByOptions,
      );
      _cachedSystemOptionsKey = cacheKey;
      _cachedSystemOptions = cacheEntry;

      setState(() {
        _makeOptions = List<ProductSystemOption>.from(makeOptions);
        _modelOptions = List<ProductSystemOption>.from(modelOptions);
        _seriesOptions = List<ProductSystemOption>.from(seriesOptions);
        _manufacturerOptions =
            List<ProductSystemOption>.from(manufacturerOptions);
        _soldByOptions = List<ProductSystemOption>.from(soldByOptions);
        _selectedMakeIds.removeWhere((id) => !makeIds.contains(id));
        _selectedModelIds.removeWhere((id) => !modelIds.contains(id));
        _selectedSeriesIds.removeWhere((id) => !seriesIds.contains(id));
        _selectedManufacturerIds
            .removeWhere((id) => !manufacturerIds.contains(id));
        _selectedSoldByIds.removeWhere((id) => !soldByIds.contains(id));
      });

      log('Loaded ${makeOptions.length} make, ${modelOptions.length} model, ${seriesOptions.length} series, ${manufacturerOptions.length} manufacturer, ${soldByOptions.length} sold-by options for selected category');
    } catch (e) {
      log('Error loading category system options: $e');
    } finally {
      if (mounted && requestId == _systemOptionRequestId) {
        setState(() {
          _isMakesLoading = false;
          _isModelsLoading = false;
          _isSeriesLoading = false;
          _isManufacturersLoading = false;
          _isSoldByLoading = false;
        });
      }
    }
  }

  bool get _hasSpecificCategorySelection {
    final hasSubCategory =
        _selectedSubCategoryId != null && _selectedSubCategoryId!.isNotEmpty;
    final hasCategory = _selectedCategoryId != null &&
        _selectedCategoryId != 'all' &&
        _selectedCategoryId!.isNotEmpty;
    return hasSubCategory || hasCategory;
  }

  String get _systemOptionsCacheKey {
    final selectedSubCategoryId = _selectedSubCategoryId;
    if (selectedSubCategoryId != null && selectedSubCategoryId.isNotEmpty) {
      return 'subcategory:$selectedSubCategoryId';
    }

    final selectedCategoryId = _selectedCategoryId;
    if (selectedCategoryId != null &&
        selectedCategoryId != 'all' &&
        selectedCategoryId.isNotEmpty) {
      return 'parentCategory:$selectedCategoryId';
    }

    return 'all';
  }

  void _applySystemOptions(_SystemOptionsCacheEntry options) {
    _makeOptions = List<ProductSystemOption>.from(options.makeOptions);
    _modelOptions = List<ProductSystemOption>.from(options.modelOptions);
    _seriesOptions = List<ProductSystemOption>.from(options.seriesOptions);
    _manufacturerOptions =
        List<ProductSystemOption>.from(options.manufacturerOptions);
    _soldByOptions = List<ProductSystemOption>.from(options.soldByOptions);

    final makeIds = _makeOptions.map((option) => option.id).toSet();
    final modelIds = _modelOptions.map((option) => option.id).toSet();
    final seriesIds = _seriesOptions.map((option) => option.id).toSet();
    final manufacturerIds =
        _manufacturerOptions.map((option) => option.id).toSet();
    final soldByIds = _soldByOptions.map((option) => option.id).toSet();

    _selectedMakeIds.removeWhere((id) => !makeIds.contains(id));
    _selectedModelIds.removeWhere((id) => !modelIds.contains(id));
    _selectedSeriesIds.removeWhere((id) => !seriesIds.contains(id));
    _selectedManufacturerIds.removeWhere((id) => !manufacturerIds.contains(id));
    _selectedSoldByIds.removeWhere((id) => !soldByIds.contains(id));
  }

  void _clearCachedSystemOptions() {
    _cachedSystemOptionsKey = null;
    _cachedSystemOptions = null;
  }

  Future<List<dynamic>> _fetchProductsForSelectedCategory() async {
    final selectedSubCategoryId = _selectedSubCategoryId;
    final selectedCategoryId = _selectedCategoryId;
    final queryParams = <String, String>{};

    if (selectedSubCategoryId != null && selectedSubCategoryId.isNotEmpty) {
      queryParams['subcategory'] = selectedSubCategoryId;
    } else if (selectedCategoryId != null &&
        selectedCategoryId != 'all' &&
        selectedCategoryId.isNotEmpty) {
      queryParams['parentCategory'] = selectedCategoryId;
    } else {
      return const [];
    }

    final uri = Uri.parse(Configss.product).replace(
      queryParameters: queryParams,
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) return const [];

    return _extractList(jsonDecode(response.body));
  }

  Future<Map<String, String>> _fetchProductSystemOptionsById(
    String optionType,
  ) async {
    try {
      final uri = Uri.parse(Configss.productSystemOptions(optionType));
      final response = await http.get(uri);
      if (response.statusCode != 200) return const {};

      final options = _extractList(jsonDecode(response.body));
      final namesById = <String, String>{};

      for (final option in options) {
        if (option is! Map) continue;
        final id = _optionLikeId(option);
        final name = _optionLikeName(option, null);
        if (id.isNotEmpty && name.isNotEmpty) {
          namesById[id] = name;
        }
      }

      return namesById;
    } catch (e) {
      log('Error fetching $optionType options: $e');
      return const {};
    }
  }

  List<dynamic> _filterProductsForSelectedCategory(List<dynamic> products) {
    if (!_hasSpecificCategorySelection) return const [];

    return products.where((product) {
      if (product is! Map) return false;

      final selectedSubCategoryId = _selectedSubCategoryId;
      if (selectedSubCategoryId != null && selectedSubCategoryId.isNotEmpty) {
        return _productHasCategoryId(product, selectedSubCategoryId, const [
          'category',
          'subCategory',
          'subCategory2',
          'subCategory3',
          'subCategory4',
        ]);
      }

      final selectedCategoryId = _selectedCategoryId;
      if (selectedCategoryId != null &&
          selectedCategoryId != 'all' &&
          selectedCategoryId.isNotEmpty) {
        return _productHasCategoryId(
          product,
          selectedCategoryId,
          const ['parentCategory'],
        );
      }

      return false;
    }).toList();
  }

  bool _productHasCategoryId(
    Map product,
    String selectedId,
    List<String> fields,
  ) {
    for (final field in fields) {
      final value = product[field];
      if (_optionLikeId(value) == selectedId) return true;
    }
    return false;
  }

  List<ProductSystemOption> _extractOptionsFromProducts(
    List<dynamic> products,
    String fieldName, {
    Map<String, String>? optionNamesById,
  }) {
    final options = <ProductSystemOption>[];
    final seenIds = <String>{};

    for (final product in products) {
      if (product is! Map) continue;

      final value = product[fieldName];
      final id = _optionLikeId(value);
      final mappedName = optionNamesById?[id];
      final name = mappedName != null && mappedName.isNotEmpty
          ? mappedName
          : _optionLikeName(value, product['${fieldName}Name']);

      if (id.isNotEmpty && name.isNotEmpty && seenIds.add(id)) {
        options.add(ProductSystemOption(id: id, name: name));
      }
    }

    options.sort((a, b) => a.name.compareTo(b.name));
    return options;
  }

  String _optionLikeId(dynamic value) {
    if (value is Map) {
      return _firstStringValue(value, const ['_id', 'id', 'value']);
    }
    if (value is String) return value.trim();
    return '';
  }

  String _optionLikeName(dynamic value, dynamic fallback) {
    if (value is Map) {
      return _firstStringValue(value, const ['name', 'title', 'label']);
    }
    if (fallback != null && fallback.toString().trim().isNotEmpty) {
      return fallback.toString().trim();
    }
    if (value is String) return value.trim();
    return '';
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in const ['data', 'options', 'items', 'results']) {
        final value = decoded[key];
        if (value is List) return value;
        if (value is Map) {
          final nested = _extractList(value);
          if (nested.isNotEmpty) return nested;
        }
      }
    }
    return const [];
  }

  String _firstStringValue(Map item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  void _clearSystemSelectionsAndOptions() {
    _selectedMakeIds.clear();
    _selectedModelIds.clear();
    _selectedSeriesIds.clear();
    _selectedManufacturerIds.clear();
    _selectedSoldByIds.clear();
    _makeOptions = [];
    _modelOptions = [];
    _seriesOptions = [];
    _manufacturerOptions = [];
    _soldByOptions = [];
  }

  // Extract brands from current products and map to names
  void _extractBrandsFromProducts() {
    final Set<String> brandIdsInProducts = {};

    for (final product in widget.products) {
      if (product is Map<String, dynamic>) {
        final brand = product['brand'];
        String? brandId;

        if (brand is Map<String, dynamic>) {
          brandId = brand['_id']?.toString();
        } else if (brand is String && brand.isNotEmpty) {
          brandId = brand;
        }

        if (brandId != null && brandId.isNotEmpty) {
          brandIdsInProducts.add(brandId);
        }
      }
    }

    // Map brand IDs to names using _allBrandsMap
    final List<Map<String, String>> brandsList = [];
    for (final brandId in brandIdsInProducts) {
      final brandName = _allBrandsMap[brandId];
      if (brandName != null && brandName.isNotEmpty) {
        brandsList.add({'id': brandId, 'name': brandName});
      }
    }

    // Sort by name
    brandsList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

    if (!mounted) return;

    setState(() {
      _availableBrands = brandsList;
    });

    log('Found ${_availableBrands.length} brands in ${widget.products.length} products');
  }

  @override
  void dispose() {
    _systemOptionRequestId++;
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategoryId = 'all';
      _selectedSubCategoryId = null;
      _selectedTitle = null;
      _selectedBrandIds.clear();
      _selectedMakeIds.clear();
      _selectedModelIds.clear();
      _selectedSeriesIds.clear();
      _selectedManufacturerIds.clear();
      _selectedSoldByIds.clear();
      _expandedCategories.clear();
    });

    // Call onApplyFilters with "all categories" filter to reset the shop view
    final resetFilters = <String, dynamic>{
      'categoryId': '',
      'subCategoryId': '',
      'selectedId': '',
      'parentType': '',
      'title': 'shop_all_products'.tr,
      'selectedBrandIds': [],
      'selectedMakeIds': [],
      'selectedModelIds': [],
      'selectedSeriesIds': [],
      'selectedManufacturerIds': [],
      'selectedSoldByIds': [],
    };
    log('Resetting filters: $resetFilters');
    widget.onApplyFilters(resetFilters);
    Navigator.of(context).pop();
  }

  // Build parent category tile (level 0)
  Widget _buildCategoryTile(Menumodel category) {
    final categoryId = category.id;
    final categoryName = category.name;
    final hasChildren = category.children.isNotEmpty;
    final isExpanded = _expandedCategories.contains(categoryId);
    final isSelected =
        _selectedCategoryId == categoryId && _selectedSubCategoryId == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            final hasCategoryChanged = _selectedCategoryId != categoryId ||
                _selectedSubCategoryId != null;

            if (!hasCategoryChanged) return;

            setState(() {
              _selectedCategoryId = categoryId;
              _selectedSubCategoryId = null;
              _selectedTitle = categoryName;
              _clearSystemSelectionsAndOptions();
              _clearCachedSystemOptions();
              log('Selected category: $categoryName ($categoryId)');
            });
            _refreshSystemOptionsForSelection();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                // Radio button
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? kPrimaryColor : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kPrimaryColor,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Category name
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? kPrimaryColor : Colors.black87,
                    ),
                  ),
                ),
                // Expand/collapse button
                if (hasChildren)
                  InkWell(
                    onTap: () {
                      final hasCategoryChanged =
                          _selectedCategoryId != categoryId ||
                              _selectedSubCategoryId != null;

                      setState(() {
                        if (isExpanded) {
                          _expandedCategories.remove(categoryId);
                        } else {
                          _expandedCategories.add(categoryId);
                        }

                        if (hasCategoryChanged) {
                          _selectedCategoryId = categoryId;
                          _selectedSubCategoryId = null;
                          _selectedTitle = categoryName;
                          _clearSystemSelectionsAndOptions();
                          _clearCachedSystemOptions();
                          log('Selected category: $categoryName ($categoryId)');
                        }
                      });
                      if (hasCategoryChanged) {
                        _refreshSystemOptionsForSelection();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isExpanded ? Icons.remove : Icons.add,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Children (subcategories level 1) - only show level 1 children
        if (hasChildren && isExpanded)
          ...category.children.where((c) => c.level == 1).map((child) =>
              _buildChildTile(child, parentId: categoryId, level: 1)),
      ],
    );
  }

  // Build child category tile (levels 1, 2, 3, 4...)
  Widget _buildChildTile(Child child,
      {required String parentId, int level = 1}) {
    final childId = child.id;
    final childName = child.name;
    final hasChildren = child.children.isNotEmpty;
    final isExpanded = _expandedCategories.contains(childId);
    final isSelected = _selectedSubCategoryId == childId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            final hasCategoryChanged = _selectedCategoryId != parentId ||
                _selectedSubCategoryId != childId;

            if (!hasCategoryChanged) return;

            setState(() {
              _selectedCategoryId = parentId;
              _selectedSubCategoryId = childId;
              _selectedTitle = childName;
              _clearSystemSelectionsAndOptions();
              _clearCachedSystemOptions();
              log('Selected subcategory level $level: $childName ($childId)');
            });
            _refreshSystemOptionsForSelection();
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: level * 20.0,
              top: 6,
              bottom: 6,
              right: 4,
            ),
            child: Row(
              children: [
                // Radio button
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? kPrimaryColor : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kPrimaryColor,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Category name
                Expanded(
                  child: Text(
                    childName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? kPrimaryColor : Colors.black54,
                    ),
                  ),
                ),
                // Expand/collapse button
                if (hasChildren)
                  InkWell(
                    onTap: () {
                      final hasCategoryChanged =
                          _selectedCategoryId != parentId ||
                              _selectedSubCategoryId != childId;

                      setState(() {
                        if (isExpanded) {
                          _expandedCategories.remove(childId);
                        } else {
                          _expandedCategories.add(childId);
                        }

                        if (hasCategoryChanged) {
                          _selectedCategoryId = parentId;
                          _selectedSubCategoryId = childId;
                          _selectedTitle = childName;
                          _clearSystemSelectionsAndOptions();
                          _clearCachedSystemOptions();
                          log('Selected subcategory level $level: $childName ($childId)');
                        }
                      });
                      if (hasCategoryChanged) {
                        _refreshSystemOptionsForSelection();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isExpanded ? Icons.remove : Icons.add,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.add,
                      size: 18,
                      color: Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Nested children (levels 2, 3, 4...)
        if (hasChildren && isExpanded)
          ...child.children.map((nestedChild) => _buildChildTile(
                nestedChild,
                parentId: parentId,
                level: level + 1,
              )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'shop_filters_title'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kSecondaryColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                  ),
                ],
              ),
              const Divider(),

              // Scrollable content - Categories then Brands
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categories Section
                      _buildCategoriesSection(),

                      const SizedBox(height: 16),

                      // Brands Section
                      _buildBrandsSection(),

                      const SizedBox(height: 16),

                      // Model Section
                      if (_isModelsLoading || _modelOptions.isNotEmpty) ...[
                        _buildSystemOptionsSection(
                          title: 'shop_filter_model'.tr,
                          options: _modelOptions,
                          selectedIds: _selectedModelIds,
                          isExpanded: _isModelSectionExpanded,
                          isLoading: _isModelsLoading,
                          onHeaderTap: () {
                            setState(() {
                              _isModelSectionExpanded =
                                  !_isModelSectionExpanded;
                            });
                          },
                          onToggle: (id) {
                            setState(() {
                              if (_selectedModelIds.contains(id)) {
                                _selectedModelIds.remove(id);
                              } else {
                                _selectedModelIds.add(id);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Make Section
                      if (_isMakesLoading || _makeOptions.isNotEmpty) ...[
                        _buildSystemOptionsSection(
                          title: 'shop_filter_make'.tr,
                          options: _makeOptions,
                          selectedIds: _selectedMakeIds,
                          isExpanded: _isMakeSectionExpanded,
                          isLoading: _isMakesLoading,
                          onHeaderTap: () {
                            setState(() {
                              _isMakeSectionExpanded = !_isMakeSectionExpanded;
                            });
                          },
                          onToggle: (id) {
                            setState(() {
                              if (_selectedMakeIds.contains(id)) {
                                _selectedMakeIds.remove(id);
                              } else {
                                _selectedMakeIds.add(id);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Series Section
                      if (_isSeriesLoading || _seriesOptions.isNotEmpty) ...[
                        _buildSystemOptionsSection(
                          title: 'shop_filter_series'.tr,
                          options: _seriesOptions,
                          selectedIds: _selectedSeriesIds,
                          isExpanded: _isSeriesSectionExpanded,
                          isLoading: _isSeriesLoading,
                          onHeaderTap: () {
                            setState(() {
                              _isSeriesSectionExpanded =
                                  !_isSeriesSectionExpanded;
                            });
                          },
                          onToggle: (id) {
                            setState(() {
                              if (_selectedSeriesIds.contains(id)) {
                                _selectedSeriesIds.remove(id);
                              } else {
                                _selectedSeriesIds.add(id);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Manufacturer Section
                      if (_isManufacturersLoading ||
                          _manufacturerOptions.isNotEmpty) ...[
                        _buildSystemOptionsSection(
                          title: 'shop_filter_manufacturer'.tr,
                          options: _manufacturerOptions,
                          selectedIds: _selectedManufacturerIds,
                          isExpanded: _isManufacturerSectionExpanded,
                          isLoading: _isManufacturersLoading,
                          onHeaderTap: () {
                            setState(() {
                              _isManufacturerSectionExpanded =
                                  !_isManufacturerSectionExpanded;
                            });
                          },
                          onToggle: (id) {
                            setState(() {
                              if (_selectedManufacturerIds.contains(id)) {
                                _selectedManufacturerIds.remove(id);
                              } else {
                                _selectedManufacturerIds.add(id);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Sold By Section
                      if (_isSoldByLoading || _soldByOptions.isNotEmpty) ...[
                        _buildSystemOptionsSection(
                          title: 'shop_filter_sold_by'.tr,
                          options: _soldByOptions,
                          selectedIds: _selectedSoldByIds,
                          isExpanded: _isSoldBySectionExpanded,
                          isLoading: _isSoldByLoading,
                          onHeaderTap: () {
                            setState(() {
                              _isSoldBySectionExpanded =
                                  !_isSoldBySectionExpanded;
                            });
                          },
                          onToggle: (id) {
                            setState(() {
                              if (_selectedSoldByIds.contains(id)) {
                                _selectedSoldByIds.remove(id);
                              } else {
                                _selectedSoldByIds.add(id);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _resetFilters,
                      child: Text(
                        'shop_reset_btn'.tr,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        // Determine the ID and parentType based on selection
                        String? selectedId;
                        String parentType = '';
                        String title = _selectedTitle ?? '';

                        if (_selectedSubCategoryId != null &&
                            _selectedSubCategoryId!.isNotEmpty) {
                          // Subcategory selected
                          selectedId = _selectedSubCategoryId;
                          parentType = 'subcategory';
                        } else if (_selectedCategoryId != null &&
                            _selectedCategoryId != 'all' &&
                            _selectedCategoryId!.isNotEmpty) {
                          // Parent category selected
                          selectedId = _selectedCategoryId;
                          parentType = 'parentCategory';
                        }

                        final filters = <String, dynamic>{
                          'categoryId': _selectedCategoryId == 'all'
                              ? ''
                              : _selectedCategoryId,
                          'subCategoryId': _selectedSubCategoryId ?? '',
                          'selectedId': selectedId ?? '',
                          'parentType': parentType,
                          'title': title,
                          'selectedBrandIds': _selectedBrandIds.toList(),
                          'selectedMakeIds': _selectedMakeIds.toList(),
                          'selectedModelIds': _selectedModelIds.toList(),
                          'selectedSeriesIds': _selectedSeriesIds.toList(),
                          'selectedManufacturerIds':
                              _selectedManufacturerIds.toList(),
                          'selectedSoldByIds': _selectedSoldByIds.toList(),
                        };
                        log('Applying filters: $filters');
                        widget.onApplyFilters(filters);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'shop_apply_filters_btn'.tr,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Categories Section
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categories Header
        InkWell(
          onTap: () {
            setState(() {
              _isCategorySectionExpanded = !_isCategorySectionExpanded;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'categories'.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              Icon(
                _isCategorySectionExpanded ? Icons.remove : Icons.add,
                color: kPrimaryColor,
              ),
            ],
          ),
        ),

        if (_isCategorySectionExpanded) ...[
          const SizedBox(height: 8),

          // Use Obx to listen to menuController
          Obx(() {
            if (_menuController.isLoading.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // All Categories option
                InkWell(
                  onTap: () {
                    final hasCategoryChanged = _selectedCategoryId != 'all' ||
                        _selectedSubCategoryId != null;

                    if (!hasCategoryChanged) return;

                    setState(() {
                      _selectedCategoryId = 'all';
                      _selectedSubCategoryId = null;
                      _selectedTitle = null;
                      _clearSystemSelectionsAndOptions();
                      _clearCachedSystemOptions();
                    });
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedCategoryId == 'all'
                                  ? kPrimaryColor
                                  : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: _selectedCategoryId == 'all'
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'shop_all_categories'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedCategoryId == 'all'
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _selectedCategoryId == 'all'
                                ? kPrimaryColor
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Category list from menuController
                ..._menuController.categories
                    .map((category) => _buildCategoryTile(category)),
              ],
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSystemOptionsSection({
    required String title,
    required List<ProductSystemOption> options,
    required Set<String> selectedIds,
    required bool isExpanded,
    required bool isLoading,
    required VoidCallback onHeaderTap,
    required ValueChanged<String> onToggle,
  }) {
    final rows = options.map((option) {
      final isSelected = selectedIds.contains(option.id);

      return InkWell(
        onTap: () => onToggle(option.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: isSelected ? kPrimaryColor : Colors.grey,
                    width: 1.5,
                  ),
                  color: isSelected ? kPrimaryColor : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? kPrimaryColor : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    Widget optionsBody;
    if (isLoading) {
      optionsBody = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (options.isEmpty) {
      optionsBody = Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No ${title.toLowerCase()} options available',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    } else if (options.length > 8) {
      optionsBody = SizedBox(
        height: 300,
        child: Scrollbar(
          child: ListView(
            padding: EdgeInsets.zero,
            children: rows,
          ),
        ),
      );
    } else {
      optionsBody = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onHeaderTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLoading ? title : '$title (${options.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              Icon(
                isExpanded ? Icons.remove : Icons.add,
                color: kPrimaryColor,
              ),
            ],
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          optionsBody,
        ],
      ],
    );
  }

  // Brands Section (shows brands available in current products)
  Widget _buildBrandsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brands Header
        InkWell(
          onTap: () {
            setState(() {
              _isBrandSectionExpanded = !_isBrandSectionExpanded;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBrandsLoading
                    ? 'shop_brands'.tr
                    : 'shop_brands_count'.trParams(
                        {'count': _availableBrands.length.toString()}),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              Icon(
                _isBrandSectionExpanded ? Icons.remove : Icons.add,
                color: kPrimaryColor,
              ),
            ],
          ),
        ),

        if (_isBrandSectionExpanded) ...[
          const SizedBox(height: 8),
          if (_isBrandsLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_availableBrands.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'shop_no_brands_msg'.tr,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            // Brand list with checkboxes
            ..._availableBrands.map((brand) {
              final brandId = brand['id'] ?? '';
              final brandName = brand['name'] ?? '';
              final isSelected = _selectedBrandIds.contains(brandId);

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedBrandIds.remove(brandId);
                    } else {
                      _selectedBrandIds.add(brandId);
                    }
                  });
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      // Checkbox
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected ? kPrimaryColor : Colors.grey,
                            width: 2,
                          ),
                          color:
                              isSelected ? kPrimaryColor : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          brandName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? kPrimaryColor : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ],
    );
  }
}
