import 'package:get/get.dart';

import 'package:graba2z/Api/Models/categorymodel.dart';

import 'package:graba2z/Api/Services/apiservices.dart';

import 'package:graba2z/Controllers/addtocart.dart';

import 'package:graba2z/Controllers/brand_controller.dart';

import 'package:graba2z/Controllers/home_controller.dart';

import 'package:graba2z/Utils/appextensions.dart';

import 'package:graba2z/Views/Home/Screens/Cart/cart.dart';

import 'package:graba2z/Views/Product%20Folder/new_all_products.dart';

import 'package:graba2z/Utils/popup_helper.dart';

import '../../Utils/packages.dart';


class SubCategoryScreen extends StatefulWidget {

  final String selectedCategoryId;

  final String title;


  const SubCategoryScreen(

      {super.key, required this.selectedCategoryId, required this.title});


  @override

  State<SubCategoryScreen> createState() => _SubCategoryScreenState();

}


class _SubCategoryScreenState extends State<SubCategoryScreen> {

  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (mounted) {

        PopupHelper.showIfNeeded(context, 'category');

      }

    });

  }


  HomeController _homeController = Get.put(HomeController());

  Widget build(BuildContext context) {

    // Filtered list of subcategories

    final filteredSubcategories = _homeController.subcategory.where((subcat) {

      return subcat.category?.sId == widget.selectedCategoryId;

    }).toList();


    return Scaffold(

      appBar: CustomAppBar(

        titleText: widget.title,

      ),

      body: filteredSubcategories.isEmpty

          ? Center(child: Text('category_no_subcategories'.tr))

          : SafeArea(

              child: ListView.builder(

                itemCount: filteredSubcategories.length,

                itemBuilder: (context, index) {

                  final subcat = filteredSubcategories[index];

                  return ListTile(

                    title: Text(

                      subcat.name ?? '',

                      style:

                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),

                    ),

                    subtitle: Text(

                      subcat.slug ?? '',

                      style: TextStyle(fontSize: 12),

                    ),

                    onTap: () {

                      Get.to(() => NewAllProduct(

                            id: subcat.sId ?? '',

                            parentType: "subcategory", // was "category"

                          ));

                    },

                    trailing: Icon(Icons.arrow_forward_ios),

                  );

                },

              ),

            ),

    );

  }

}
