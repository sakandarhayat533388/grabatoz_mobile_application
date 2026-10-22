import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:graba2z/Utils/appcolors.dart';
import 'package:graba2z/Views/Product%20Folder/newProduct_card.dart';
import 'package:shimmer/shimmer.dart';

class HorizontalProducts extends StatefulWidget {
  String name;
  bool loading;
  List productList;
  Function()? onTap;
  Function()? onAddedToCart;

  HorizontalProducts({
    super.key,
    required this.name,
    required this.loading,
    this.onTap,
    required this.productList,
    this.onAddedToCart,
  });

  @override
  State<HorizontalProducts> createState() => _HorizontalProductsState();
}

class _HorizontalProductsState extends State<HorizontalProducts> {
  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double horizontalPadding = 5 * 2;
    final double gap = 8;
    final double cardWidth = (screenW - horizontalPadding - gap) / 2;
    final double cardHeight = cardWidth / 0.68;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.name.isNotEmpty
            ? GestureDetector(
                onTap: widget.onTap,
                child: Padding(
                  padding: defaultPadding(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kSecondaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'home_show_all'.tr,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: kSecondaryColor),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: kSecondaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox(),
        widget.loading
            ? SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: cardWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    );
                  },
                ),
              )
            : SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.productList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final product = widget.productList[index];
                    return SizedBox(
                      width: cardWidth,
                      child: NewProductCard(
                        prdouctList: product,
                        onAddedToCart: widget.onAddedToCart,
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}
