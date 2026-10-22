import 'package:get/get.dart';

import 'package:graba2z/Controllers/addtocart.dart';

import 'package:graba2z/Controllers/homeSliderController.dart';

import 'package:graba2z/Controllers/home_controller.dart';

import 'package:graba2z/Utils/appextensions.dart';

import 'package:graba2z/Utils/popup_helper.dart';

import 'package:graba2z/Views/Categories%20Folder/subcategories_view.dart';

import 'package:graba2z/Views/Home/Screens/Cart/cart.dart';

import 'package:graba2z/Views/Home/home.dart';

import '../../Utils/packages.dart';

import 'package:graba2z/Configs/config.dart';


import '../Home/Screens/Deals Screen/dealsview.dart';

import '../Home/Screens/Search Screen/searchscreensecond.dart';

import '../Home/Screens/Shop Screen/Shop.dart';

import '../Home/Screens/banner redirect/bannerredirect.dart';

import '../Product Folder/new_all_products.dart';


class AllCategoriesScreen extends StatefulWidget {

  const AllCategoriesScreen({super.key});


  @override

  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();

}


class _AllCategoriesScreenState extends State<AllCategoriesScreen> {

  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (mounted) {

        PopupHelper.showIfNeeded(context, 'category');

      }

    });

  }


  String generateSlug(String text) {

    return text

        .toLowerCase()                        // CAPITAL → lowercase

        .trim()                              // start/end spaces remove

        .replaceAll(RegExp(r'[^\w\s-]'), '') // special characters remove

        .replaceAll(RegExp(r'\s+'), '-')     // spaces → hyphen

        .replaceAll(RegExp(r'-+'), '-');     // multiple hyphens → single

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: CustomAppBar(

        titleText: 'category_all'.tr,

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

      body: SafeArea(

        child: GetBuilder<HomeSliderController>(builder: (

          apiservice,

        ) {

          if (apiservice.isCateloading.value) {

            return Padding(

              padding: defaultPadding(),

              child: GridView.builder(

                itemCount: apiservice

                    .category.length, // Number of shimmer items to show

                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(

                  crossAxisCount: 3,

                  childAspectRatio: 1,

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


          if (apiservice.category.isEmpty) {

            return Center(

              child: Text('category_no_categories'.tr),

            );

          }

          return Padding(

            padding: defaultPadding(vertical: 15),

            child: GridView.builder(

              itemCount: apiservice.category.length,

              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(

                crossAxisCount: 3,

                childAspectRatio: 0.8,

              ),

              itemBuilder: (context, index) {

                final category = apiservice.category[index];

                // final imageUrl = category.image?.src;

                // print('Image URL: $imageUrl');

                return Padding(

                  padding: EdgeInsets.symmetric(horizontal: 10),

                  child: Column(

                    children: [

                      GestureDetector(

                        onTap: () {

                          final targetId = (category.slug != null && category.slug!.isNotEmpty)

                              ? category.slug!

                              : (category.sId != null && category.sId!.isNotEmpty)

                                  ? category.sId!

                                  : generateSlug(category.name ?? '');

                          Get.to(() => bannerProduct(

                                brandname: targetId,

                                displayTitle: category.name ?? '',

                              ));

                        },

                        child: Container(

                          decoration: BoxDecoration(

                            color: kdefgreyColor,

                            borderRadius: BorderRadius.circular(6),

                            boxShadow: [

                              BoxShadow(

                                color: Colors.black.withValues(alpha: 0.2),

                                offset: Offset(0, 2),

                                blurRadius: 3,

                                spreadRadius: 1,

                              ),

                            ],

                          ),

                          child: CachedNetworkImage(


                                  imageUrl: Configss.baseUrl + category.image!,

                            imageBuilder: (context, imageProvider) => Container(

                              height: 80,

                              width: 75,

                              decoration: BoxDecoration(

                                borderRadius: BorderRadius.circular(6),

                                image: DecorationImage(

                                  image: imageProvider,

                                  fit: BoxFit.cover,

                                ),

                              ),

                            ),

                            placeholder: (context, url) => SizedBox(

                              height: 80,

                              width: 75,

                              child: Shimmer.fromColors(

                                baseColor: Colors.grey.shade300,

                                highlightColor: Colors.grey.shade100,

                                child: Container(

                                  decoration: BoxDecoration(

                                    color: Colors.grey,

                                    borderRadius: BorderRadius.circular(6),

                                  ),

                                ),

                              ),

                            ),

                            errorWidget: (context, url, error) => Container(

                              height: 80,

                              width: 75,

                              decoration: BoxDecoration(

                                borderRadius: BorderRadius.circular(6),

                                image: const DecorationImage(

                                  image: AssetImage(

                                    'assets/images/noimage.png',

                                  ),

                                  fit: BoxFit.contain,

                                ),

                              ),

                            ),

                          ),

                        ),

                      ),

                      8.0.heightbox,

                      Text(

                        category.name ?? '',

                        style: const TextStyle(

                          fontSize: 13,

                          fontWeight: FontWeight.w600,

                          color: kSecondaryColor,

                        ),

                        textAlign: TextAlign.center,

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                      ),

                    ],

                  ),


                  //     CategoricalServiceCard(

                  //   id: category.sId ?? '',

                  //   maxLine: 1,

                  //   categoryAPIModel: categoriesModel(

                  //     name: category.name,

                  //     image: category.image,

                  //   ),

                  // ),

                );

              },

            ),

          );

        }),

      ),

    );

  }

}
