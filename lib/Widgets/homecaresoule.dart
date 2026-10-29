import 'dart:convert';
import 'package:get/get.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Utils/image_helper.dart';
import '../Utils/packages.dart';
import 'package:http/http.dart' as http;

import '../Views/Home/Screens/banner redirect/bannerredirect.dart';
import '../Views/Home/Screens/Deals Screen/dealsview.dart';

class ImageCarouselSlider extends StatefulWidget {
  const ImageCarouselSlider({super.key});

  @override
  ImageCarouselSliderState createState() => ImageCarouselSliderState();
}

class ImageCarouselSliderState extends State<ImageCarouselSlider> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  // double getResponsivecaresoulHeight(BuildContext context) {
  //   final screenWidth = MediaQuery.of(context).size.width;

  //   if (screenWidth <= 400) {
  //     return MediaQuery.of(context).size.height * 0.15; // small phones
  //   } else if (screenWidth <= 600) {
  //     return MediaQuery.of(context).size.height * 0.12; // regular phones
  //   } else if (screenWidth <= 900) {
  //     return MediaQuery.of(context).size.height * 0.9; // small tablets
  //   } else {
  //     return MediaQuery.of(context).size.height *
  //         0.20; // tablets/iPads ✅ tested
  //   }
  // }

  List bannerList = [];

  Future<List<Map<String, dynamic>>> fetchBanners() async {
    String url = Configss.getBanners;
    List<Map<String, dynamic>> banners = [];

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Filter and map banners
        banners = (data as List)
            .where((item) =>
                item['deviceType'] == 'mobile' &&
                item['position'] == 'hero' &&
                item['isActive'] == true)
            .map<Map<String, dynamic>>((item) => {
                  "image": item['image'] ?? "",
                  "redirect_url": item['buttonLink'] ?? "",
                })
            .toList();
      } else {
        print("Failed to fetch banners. Status code: ${response.statusCode}");
        throw Exception('Failed to load banners');
      }
    } catch (error) {
      print("Error fetching banners: $error");
    }

    return banners;
  }

  String extractLastWord(String link) {
    // Remove query parameters (? ke baad sab)
    final cleanLink = link.split('?').first;

    // If brand link
    if (link.contains("?brand=")) {
      return link.split("?brand=").last;
    }

    // If search query
    if (link.contains("?search=")) {
      return link.split("?search=").last;
    }

    // If category link
    if (cleanLink.contains("/product-category/")) {
      final parts = cleanLink.split("/product-category/");
      if (parts.length > 1) {
        final subParts = parts[1].split("/");
        return subParts.isNotEmpty ? subParts.last : "";
      }
    }

    return "";
  }


  Future<void> loadBanners() async {
    bannerList = await fetchBanners(); // fetch list of maps
    if (!mounted) return;
    setState(() {}); // update UI
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadBanners();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          items: bannerList.map((banner) {
            final imageUrl = banner['image'] ?? "";

            return GestureDetector(
              onTap: () {
                final link = banner['redirect_url'] ?? "";
                final name = extractLastWord(link);

                debugPrint("Banner link: $link");

                // Check if link contains "offers/" or "/offers/" - redirect to deals page
                if (link.contains("offers/") || link.contains("/offers/")) {
                  // Extract slug from offers link (e.g., "offers/ramadan-offers" -> "ramadan-offers")
                  String offerSlug = "";
                  if (link.contains("/offers/")) {
                    offerSlug = link.split("/offers/").last.split("?").first;
                  } else {
                    offerSlug = link.split("offers/").last.split("?").first;
                  }
                  // Remove any trailing slashes
                  offerSlug = offerSlug.replaceAll("/", "");

                  debugPrint("Offer slug: $offerSlug");

                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return offerDeals(
                      slug: offerSlug,
                      displayTitle: offerSlug.replaceAll("-", " ").split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' '),
                    );
                  }));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return bannerProduct(
                      brandname: name,
                      displayTitle: name,
                    );
                  }));
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CachedNetworkImage(
                  width: double.infinity,
                  imageUrl: ImageHelper.getUrl(imageUrl),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('home_no_image'.tr,
                          style: const TextStyle(color: Colors.red)),
                      SizedBox(height: 10),
                      Icon(Icons.error, color: Colors.red),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 160,
            viewportFraction: 1.0,
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 6),
            onPageChanged: (index, reason) {
              if (!mounted) return;
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),

        10.0.heightbox,
        bannerList.isNotEmpty
            ? AnimatedSmoothIndicator(
                activeIndex: _currentIndex,
                count: bannerList.length,
                effect: WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: kPrimaryColor,
                  dotColor: kdefgreyColor,
                ),
              )
            : const SizedBox(), // empty placeholder when no banners
      ],
    );
  }
}
