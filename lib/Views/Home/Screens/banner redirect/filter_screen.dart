import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graba2z/Utils/appcolors.dart';
import 'package:graba2z/Controllers/language_controller.dart';

class FilterDrawer extends StatefulWidget {
  final List<Map<String, String>> availableBrands;
  final List<Map<String, String>> availableCategories;
  final Set<String> selectedBrandIds;
  final Set<String> selectedCategoryIds;
  final Function(Set<String>, Set<String>)? onApply;

  const FilterDrawer({
    Key? key,
    required this.availableBrands,
    required this.availableCategories,
    required this.selectedBrandIds,
    required this.selectedCategoryIds,
    this.onApply,
  }) : super(key: key);

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  String _displayName(Map<String, String> item) {
    final bool isAr = Get.isRegistered<LanguageController>() &&
        Get.find<LanguageController>().isArabic;
    final ar = (item['nameAr'] ?? '').trim();
    if (isAr && ar.isNotEmpty) return ar;
    return item['name'] ?? '';
  }

  late Set<String> _selectedBrandIds;
  late Set<String> _selectedCategoryIds;
  late bool _isBrandExpanded;
  late bool _isCategoryExpanded;

  @override
  void initState() {
    super.initState();
    _selectedBrandIds = Set<String>.from(widget.selectedBrandIds);
    _selectedCategoryIds = Set<String>.from(widget.selectedCategoryIds);

    // Expand brands section if:
    // 1. Brands are already selected (to show what's selected)
    // 2. OR brands list is not empty (to show available options)
    _isBrandExpanded = _selectedBrandIds.isNotEmpty || widget.availableBrands.isNotEmpty;

    // Expand categories section if:
    // 1. Categories are already selected (to show what's selected)
    // 2. OR categories list is not empty (to show available options)
    _isCategoryExpanded = _selectedCategoryIds.isNotEmpty || widget.availableCategories.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'shop_filters_title'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categories Section
                    _buildCategoriesSection(),
                    const SizedBox(height: 24),

                    // Brands Section
                    _buildBrandsSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Apply button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        // Reset filters
                        setState(() {
                          _selectedBrandIds.clear();
                          _selectedCategoryIds.clear();
                        });
                      },
                      child: Text(
                        'shop_reset_btn'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                    Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        // Call the apply callback if provided
                        widget.onApply?.call(_selectedBrandIds, _selectedCategoryIds);
                        // Close drawer
                        Navigator.pop(context);
                      },
                      child: Text(
                        'shop_apply_btn'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Brands Section
  Widget _buildBrandsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isBrandExpanded = !_isBrandExpanded;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'shop_brands_count'.trParams(
                    {'count': widget.availableBrands.length.toString()}),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Icon(
                _isBrandExpanded ? Icons.expand_less : Icons.expand_more,
                color: kPrimaryColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isBrandExpanded) ...[
          if (widget.availableBrands.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'shop_no_brands'.tr,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...widget.availableBrands.map((brand) {
              final brandId = brand['id'] ?? '';
              final brandName = _displayName(brand);
              final isSelected = _selectedBrandIds.contains(brandId);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedBrandIds.remove(brandId);
                      } else {
                        _selectedBrandIds.add(brandId);
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected ? kPrimaryColor : Colors.grey.shade300,
                            width: 2,
                          ),
                          color: isSelected ? kPrimaryColor : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
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
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? kPrimaryColor : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ],
    );
  }

  // Categories Section
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isCategoryExpanded = !_isCategoryExpanded;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'shop_categories_count'.trParams(
                    {'count': widget.availableCategories.length.toString()}),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Icon(
                _isCategoryExpanded ? Icons.expand_less : Icons.expand_more,
                color: kPrimaryColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isCategoryExpanded) ...[
          if (widget.availableCategories.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'shop_no_categories'.tr,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...widget.availableCategories.map((category) {
              final categoryId = category['id'] ?? '';
              final categoryName = _displayName(category);
              final isSelected = _selectedCategoryIds.contains(categoryId);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategoryIds.remove(categoryId);
                      } else {
                        _selectedCategoryIds.add(categoryId);
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected ? kPrimaryColor : Colors.grey.shade300,
                            width: 2,
                          ),
                          color: isSelected ? kPrimaryColor : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? kPrimaryColor : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ],
    );
  }
}
