import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:graba2z/Api/Models/categorymodel.dart';

import 'package:graba2z/Controllers/brand_controller.dart';

import 'package:graba2z/Controllers/home_controller.dart';

import 'package:graba2z/Utils/appextensions.dart';

import 'package:graba2z/Utils/packages.dart';

import 'package:graba2z/Views/Filter%20Screen/filter_controller.dart';


class FilterScreen extends StatelessWidget {

  final Function(Map<String, dynamic>) onApplyFilters;


  const FilterScreen({super.key, required this.onApplyFilters});


  @override

  Widget build(BuildContext context) {

    return Drawer(

      child: FilterDrawerContent(

        onApplyFilters: onApplyFilters,

      ),

    );

  }

}


class FilterDrawerContent extends StatefulWidget {

  final Function(Map<String, dynamic>) onApplyFilters;

  FilterDrawerContent({super.key, required this.onApplyFilters});


  @override

  FilterDrawerContentState createState() => FilterDrawerContentState();

}


class FilterDrawerContentState extends State<FilterDrawerContent> {

  final FilterController filterController =

      Get.isRegistered<FilterController>()

          ? Get.find<FilterController>()

          : Get.put(FilterController(), permanent: true);

  SubCategoryModel? selectedSubCategoryModel;

  final TextEditingController minPriceController = TextEditingController();

  final TextEditingController maxPriceController = TextEditingController();


  final BrandController _brandController = Get.find<BrandController>();

  final HomeController _homeController = Get.find<HomeController>();


  List<SubCategoryModel> get filteredSubcategories {

    if (filterController.selectedCategoryId.value == 'all') {

      return _homeController.filterSubcategory;

    }

    return _homeController.filterSubcategory

        .where((sub) =>

            sub.category?.sId == filterController.selectedCategoryId.value)

        .toList();

  }


  String _sanitizeId(String? v) {

    final s = (v ?? '').trim();

    final low = s.toLowerCase();

    if (s.isEmpty || low == 'all' || low == 'null' || low == 'none') return '';

    return s;

  }


  @override

  void initState() {

    super.initState();

    final allSubCat = _homeController.filterSubcategory

        .firstWhereOrNull((e) => e.name == "All");

    selectedSubCategoryModel =

        allSubCat ?? SubCategoryModel(name: "All", sId: "");

    minPriceController.text =

        filterController.minPrice.value.toStringAsFixed(0);

    maxPriceController.text =

        filterController.maxPrice.value.toStringAsFixed(0);

  }


  @override

  void dispose() {

    // Reset filter values so the next open starts clean

    try {

      filterController.resetFilters();

    } catch (_) {}

    // Dispose local controllers

    minPriceController.dispose();

    maxPriceController.dispose();

    super.dispose();

  }


  void resetFilters() {

    setState(() {

      filterController.minPrice.value = 0; // was 1

      filterController.maxPrice.value = 100000;

      minPriceController.text = "0"; // was "1"

      maxPriceController.text = "100000";

      filterController.selectedBrand.value = "All";

      filterController.selectedStockStatus.value = "All";

      filterController.selectedCategoryId.value = 'all';

      filterController.selectedSubCategoryId.value = null;

    });

  }


  @override

  Widget build(BuildContext context) {

    List<DropdownMenuItem<String>> categoryDropdownItems = [

      DropdownMenuItem(value: 'all', child: Text('common_all'.tr)),

      ..._homeController.filterCategory.map((cat) {

        return DropdownMenuItem(value: cat.sId, child: Text(cat.name ?? ''));

      }).toList(),

    ];


    return SafeArea(

      child: Padding(

        padding: defaultPadding(vertical: 10),

        child: SingleChildScrollView(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                'filter_price_range'.tr,

                style: TextStyle(

                  fontSize: 14,

                  fontWeight: FontWeight.bold,

                  color: kSecondaryColor,

                ),

              ),

              Obx(() => RangeSlider(

                    values: RangeValues(

                      filterController.minPrice.value,

                      filterController.maxPrice.value,

                    ),

                    min: 0,

                    max: 100000,

                    divisions: 500,

                    labels: RangeLabels(

                      "${filterController.minPrice.value.toInt()} AED",

                      "${filterController.maxPrice.value.toInt()} AED",

                    ),

                    activeColor: kPrimaryColor,

                    inactiveColor: kSecondaryColor.withOpacity(0.3),

                    onChanged: (RangeValues newRange) {

                      filterController.minPrice.value = newRange.start;

                      filterController.maxPrice.value = newRange.end;

                      minPriceController.text =

                          newRange.start.toInt().toString();

                      maxPriceController.text = newRange.end.toInt().toString();

                    },

                  )),


              Row(

                children: [

                  Expanded(

                    child: TextField(

                      controller: minPriceController,

                      keyboardType: TextInputType.number,

                      decoration: InputDecoration(

                        labelText: 'filter_min_price'.tr,

                        prefixText: "AED ",

                        border: OutlineInputBorder(

                            borderRadius: BorderRadius.circular(12)),

                      ),

                      onChanged: (value) {

                        log('the min price $value');

                        double newMin = double.tryParse(value) ?? 0;

                        if (newMin <= filterController.maxPrice.value) {

                          filterController.minPrice.value = newMin;

                        }

                      },

                    ),

                  ),

                  SizedBox(width: 20),

                  Expanded(

                    child: TextField(

                      controller: maxPriceController,

                      keyboardType: TextInputType.number,

                      decoration: InputDecoration(

                        labelText: 'filter_max_price'.tr,

                        prefixText: "AED ",

                        border: OutlineInputBorder(

                            borderRadius: BorderRadius.circular(12)),

                      ),

                      onChanged: (value) {

                        log('the max price $value');

                        double newMax = double.tryParse(value) ?? 100000;

                        if (newMax >= filterController.minPrice.value) {

                          filterController.maxPrice.value = newMax;

                        }

                      },

                    ),

                  ),

                ],

              ),


              SizedBox(height: 20),

              Text('filter_category'.tr,

                  style: TextStyle(

                      fontSize: 14,

                      fontWeight: FontWeight.bold,

                      color: kSecondaryColor)),

              Card(

                elevation: 3,

                child: DropdownButtonHideUnderline(

                  child: DropdownButton<String>(

                    padding: EdgeInsets.only(left: 8),

                    style: TextStyle(fontSize: 13, color: Colors.black),

                    value: filterController.selectedCategoryId.value,

                    isExpanded: true,

                    items: categoryDropdownItems,

                    onChanged: (value) {

                      setState(() {

                        filterController.selectedCategoryId.value = value ?? '';

                        if (filterController.selectedCategoryId.value == 'all') {

                          filterController.selectedSubCategoryId.value = null;

                        }

                        log('the selected CategoryId is ${filterController.selectedCategoryId.value}');

                      });

                    },

                  ),

                ),

              ),

              SizedBox(height: 20),

              //

              // Text(

              //   "SubCategory",

              //   style: TextStyle(

              //     fontSize: 14,

              //     fontWeight: FontWeight.bold,

              //     color: kSecondaryColor,

              //   ),

              // ),

              //

              // SizedBox(height: 8),

              //

              // Card(

              //   elevation: 3,

              //   shape: RoundedRectangleBorder(

              //     borderRadius: BorderRadius.circular(8),

              //   ),

              //   child: Padding(

              //     padding: const EdgeInsets.symmetric(horizontal: 8.0), // internal padding

              //     child: DropdownButtonFormField<String>(

              //       isExpanded: true, // ✅ prevents overflow

              //       decoration: InputDecoration(

              //         border: InputBorder.none,

              //         hintText: "Select SubCategory",

              //         hintStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),

              //         contentPadding: EdgeInsets.symmetric(vertical: 12), // vertical spacing

              //       ),

              //       style: TextStyle(fontSize: 13, color: Colors.black),

              //       value: filteredSubcategories.any((sub) =>

              //       sub.sId == filterController.selectedSubCategoryId.value)

              //           ? filterController.selectedSubCategoryId.value

              //           : null,

              //       items: filteredSubcategories.map((sub) {

              //         return DropdownMenuItem(

              //           value: sub.sId,

              //           child: Text(

              //             sub.name ?? '',

              //             overflow: TextOverflow.ellipsis,

              //           ),

              //         );

              //       }).toList(),

              //       onChanged: (value) {

              //         setState(() {

              //           filterController.selectedSubCategoryId.value = value;

              //           log(

              //               'The selected subcategory is ${filterController.selectedSubCategoryId.value}');

              //         });

              //       },

              //     ),

              //   ),

              // ),


              SizedBox(height: 20),

              Text('filter_brand'.tr,

                  style: TextStyle(

                      fontSize: 14,

                      fontWeight: FontWeight.bold,

                      color: kSecondaryColor)),

              Card(

                elevation: 3,

                child: DropdownButtonHideUnderline(

                  child: DropdownButton<String>(

                    padding: EdgeInsets.only(left: 8),

                    isExpanded: true,

                    value: filterController.selectedBrand.value.isNotEmpty

                        ? filterController.selectedBrand.value

                        : null,

                    items: ["All", ..._brandController.brandName.toSet()]

                        .map((brand) => DropdownMenuItem(

                              value: brand,

                              child: Text(brand == 'All' ? 'common_all'.tr : brand,

                                  style: TextStyle(

                                      fontSize: 12, color: kSecondaryColor)),

                            ))

                        .toList(),

                    onChanged: (value) {

                      setState(() {

                        filterController.selectedBrand.value = value!;

                        if (filterController.selectedBrand.value != "All") {

                          filterController.brandId.value = _brandController

                              .brandList

                              .firstWhere((val) =>

                                  filterController.selectedBrand.value ==
                                  val['name'])['_id']

                              .toString();

                        } else {

                          filterController.brandId.value = '';

                        }

                      });

                    },

                  ),

                ),

              ),

              SizedBox(height: 10),


              // Sort by section removed


              SizedBox(height: 10),

              ElevatedButton(

                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),

                onPressed: () {

                  final filters = <String, dynamic>{

                    'minPrice': filterController.minPrice.value,

                    'maxPrice': filterController.maxPrice.value,

                    'sortBy': '', // no sorting from drawer

                    'parentCategoryId': filterController.selectedCategoryId.value == 'all'

                        ? ''

                        : (filterController.selectedCategoryId.value),

                    'subcategoryId': filterController.selectedSubCategoryId.value ?? '',

                    'brandId': filterController.selectedBrand.value != 'All'

                        ? filterController.brandId.value

                        : '',

                  };

                  // Fire-and-close so shimmer shows immediately in caller

                  widget.onApplyFilters(filters);

                  Navigator.of(context).pop();

                },

                child: Text(

                  'filter_apply'.tr,

                  style: TextStyle(color: Colors.white),

                ),

              ),


              SizedBox(height: 10),

              ElevatedButton(

                onPressed: resetFilters,

                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

                child: Text(

                  'filter_reset'.tr,

                  style: TextStyle(color: Colors.white),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}
