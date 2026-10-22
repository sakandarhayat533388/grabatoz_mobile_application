import 'package:get/get.dart';
import 'package:graba2z/Views/Home/Screens/Deals%20Screen/dealsview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Controllers/menuController.dart';
import '../Utils/packages.dart';
import '../Views/Home/Screens/Shop Screen/Shop.dart';
import 'MenuTile.dart';

Drawer buildCategoryDrawer() {
  final menuController controller = Get.find<menuController>();

  return Drawer(
    child: Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            color: kPrimaryColor,
            width: double.infinity,
            child: Center(
              child: Image.asset(
                AppImages.logoicon,
                width: 90,
                height: 90,
                color: kdefwhiteColor,
              ),
            ),
          ),
          // Crownyx Tile - Opens website
          GestureDetector(
            onTap: () async {
            Get.to(()=>offerDeals(
              displayTitle:"CROWNYX",
              slug: "crownyx",
            ));
            },
            child: Container(
              color: const Color(0xFF2B3497),
              width: double.infinity,
              padding: const EdgeInsets.only(top: 14, bottom: 14, left: 16, right: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CROWNYX',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF2B3497)),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Colors.black),
          // Gaming Zone Tile
          GestureDetector(
            onTap: () async {
              Get.to(()=>offerDeals(
                displayTitle: 'home_gaming_zone'.tr,
                slug: "gaming-zone",
              ));
            },
            child: Container(
              color: const Color(0xFF2B3497),
              width: double.infinity,
              padding: const EdgeInsets.only(top: 14, bottom: 14, left: 16, right: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'home_gaming_zone'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF2B3497)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: controller.categories.map((category) {
                return CategoryTile(
                  title: category.name,
                  slug: category.slug,
                  id: category.id,
                  children: category.children.where((c) => c.level == 1).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }),
  );
}
