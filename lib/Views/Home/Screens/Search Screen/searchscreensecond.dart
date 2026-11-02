import 'dart:math' as math;


import 'package:flutter/material.dart';

import 'package:flutter_html/flutter_html.dart';

import 'package:get/get.dart';

import '../../../../Controllers/SecondSearchControlller.dart';

import 'package:graba2z/Views/Product%20Folder/newProduct_card.dart';


import '../../../../Utils/appcolors.dart';


class SearchScreenSecond extends StatefulWidget {

  SearchScreenSecond({super.key});


  @override

  State<SearchScreenSecond> createState() => _SearchScreenSecondState();

}


class _SearchScreenSecondState extends State<SearchScreenSecond> {

  final ProductController controller = Get.put(ProductController());

  final TextEditingController searchController = TextEditingController();


  double _calcSortMaxWidth(BoxConstraints c) =>

      math.min(220.0, c.maxWidth * 0.38);

  bool _sortMenuOpen = false;

  String _sortLabel = 'Newest First';


  static const int pageSize = 20;

  int visibleCount = pageSize;


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


  @override

  Widget build(BuildContext context) {

    return Scaffold(

      body: SafeArea(

        child: Column(

          children: [

            // Top row with back button and search field

            Padding(

              padding: const EdgeInsets.all(12.0),

              child: Row(

                children: [

                  IconButton(

                    icon: Icon(Icons.arrow_back_ios),

                    onPressed: () {

                      Navigator.pop(context);

                    },

                  ),

                  SizedBox(width: 8),

                  Expanded(

                    child: Container(

                      height: 45,

                      decoration: BoxDecoration(

                        color: Colors.grey[200],

                        borderRadius: BorderRadius.circular(60),

                      ),

                      child: TextFormField(

                        controller: searchController,

                        onChanged: (value) {

                          controller.searchQuery.value = value;

                        },

                        onFieldSubmitted: (value) {

                          controller.searchQuery.value = value;

                        },

                        decoration: InputDecoration(

                          hintText: 'search_hint'.tr,

                          border: InputBorder.none,

                          prefixIcon: const Icon(Icons.search),

                        ),

                      ),

                    ),

                  ),

                ],

              ),

            ),

            // Product list / Placeholder

            Expanded(

              child: Obx(() {

                final sortproducts =

                    _getSortedDisplayProducts(controller.displayedProducts);

                final sorted = _applySortOption(sortproducts);


                final products = sorted.take(visibleCount).toList();

                if (!controller.hasSearched.value) {

                  return Column(

                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [

                      Text(

                        'search_empty_title_simple'.tr,

                        style: TextStyle(color: kPrimaryColor, fontSize: 15,fontWeight: FontWeight.bold),

                      ),

                      SizedBox(height: 10),

                      Padding(

                        padding: const EdgeInsets.symmetric(horizontal: 10),

                        child: Text(

                          'search_empty_hint'.tr,

                          textAlign: TextAlign.center,

                          style: TextStyle(

                              color: kdefblackColor,

                              fontWeight: FontWeight.bold),

                        ),

                      )

                    ],

                  );

                }


                if (controller.isLoading.value) {

                  return const Center(child: CircularProgressIndicator());

                }


                if (controller.displayedProducts.isEmpty) {

                  return Center(child: Text('search_no_products'.tr));

                }


                return CustomScrollView(

                  slivers: [

                    /// 🔥 count + sort row

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

                                  child: Text(

                                    'search_products_found'.trParams({'count': controller.displayedProducts.length.toString()}),

                                    style: const TextStyle(

                                      fontSize: 14,

                                      fontWeight: FontWeight.w700,

                                    ),

                                    overflow: TextOverflow.ellipsis,

                                  ),

                                ),

                                const SizedBox(width: 8),

                                SizedBox(width: maxW, child: _sortMenuButton()),

                              ],

                            );

                          },

                        ),

                      ),

                    ),


                    /// 🧱 Product Grid

                    SliverPadding(

                      padding: const EdgeInsets.symmetric(

                          horizontal: 12, vertical: 8),

                      sliver: SliverGrid(

                        delegate: SliverChildBuilderDelegate(

                          (context, index) {

                            final product = products[index];

                            return NewProductCard(

                              prdouctList: product,

                              onAddedToCart: _showAddedToCartPopup,

                            );

                          },

                          childCount: products.length, // ✅ sirf 20 / 40 / 60

                        ),

                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(

                          crossAxisCount:

                              MediaQuery.of(context).size.width > 600 ? 3 : 2,

                          childAspectRatio: 0.7,

                          crossAxisSpacing: 8,

                          mainAxisSpacing: 8,

                        ),

                      ),

                    ),


                    /// ⬇️ Load More button — EXACTLY grid ke baad

                    SliverToBoxAdapter(

                      child: Padding(

                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),

                        child: Center(

                          child: (visibleCount <

                                  controller.displayedProducts.length)

                              ? ElevatedButton(

                                  style: _webLikeLoadMoreStyle(),

                                  onPressed: () {

                                    final total =

                                        controller.displayedProducts.length;

                                    setState(() {

                                      visibleCount = (visibleCount + pageSize)

                                          .clamp(0, total);

                                    });

                                  },

                                  child: Text('common_load_more'.tr),

                                )

                              : const SizedBox.shrink(),

                        ),

                      ),

                    ),

                  ],

                );

              }),

            ),

          ],

        ),

      ),

    );

  }

}
