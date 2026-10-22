import 'package:get/get.dart';

import 'package:graba2z/Api/Services/apiservices.dart';

import 'package:graba2z/Controllers/addtocart.dart';

import 'package:graba2z/Utils/appextensions.dart';

import 'package:graba2z/Utils/image_helper.dart';

import 'package:graba2z/Views/Brand%20Folder/brandcard.dart';

import 'package:graba2z/Views/Home/Screens/Cart/cart.dart';

import '../../../Utils/packages.dart';

import '../Home/Screens/Search Screen/searchscreensecond.dart';


class AllBrandScreen extends StatelessWidget {

  List brandList;


  AllBrandScreen({super.key, required this.brandList});


  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: CustomAppBar(

        titleText: 'brand_all'.tr,

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

      body: GetBuilder<ApiServiceController>(builder: (apiservice) {

        return SafeArea(

          child: GridView.builder(

            itemCount: brandList.length,

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(

              crossAxisCount: 2,

              childAspectRatio: .93,

            ),

            itemBuilder: (context, index) {

              final brand = brandList[index];

              return BrandCard(

                id: brand['_id'].toString(),

                imageUrl:

                    brand['logo'] != null && brand['logo'].toString().isNotEmpty

                        ? ImageHelper.getUrl(brand['logo'])

                        : 'https://i.postimg.cc/SsWYSvq6/noimage.png',

                name: brand['name'] ?? 'brand_no_name'.tr,

                // Pass as map if BrandCard accepts it

              );

            },

          ),

        );

      }),

    );

  }

}
