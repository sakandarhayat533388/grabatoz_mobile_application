import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Models/home_section_model.dart';

class DynamicSectionController extends GetxController {
  final RxBool isLoadingSections = false.obs;
  final RxList<HomeSectionModel> activeSections = <HomeSectionModel>[].obs;
  final RxMap<String, RxList<BannerCardModel>> sectionCardsMap =
      <String, RxList<BannerCardModel>>{}.obs;
  final RxMap<String, RxBool> sectionLoadingMap = <String, RxBool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchActiveSections();
  }

  Future<void> fetchActiveSections() async {
    isLoadingSections.value = true;
    try {
      final response = await http.get(
        Uri.parse(Configss.getActiveHomeSections),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<HomeSectionModel> sections = data
            .map((json) => HomeSectionModel.fromJson(json))
            .where((section) => section.isActive)
            .toList();

        // Sort sections by order
        sections.sort((a, b) => a.order.compareTo(b.order));
        activeSections.assignAll(sections);

        // Fetch cards for each section
        for (var section in sections) {
          fetchCardsForSection(section.slug);
        }
      } else {
        log('Failed to fetch active sections: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error fetching active sections: $e');
    } finally {
      isLoadingSections.value = false;
    }
  }

  Future<List<BannerCardModel>> fetchCardsForSection(String slug) async {
    if (slug.isEmpty) return [];

    if (!sectionCardsMap.containsKey(slug)) {
      sectionCardsMap[slug] = <BannerCardModel>[].obs;
    }
    if (!sectionLoadingMap.containsKey(slug)) {
      sectionLoadingMap[slug] = false.obs;
    }

    // Return cached list if already loaded and not empty
    if (sectionCardsMap[slug]!.isNotEmpty) {
      return sectionCardsMap[slug]!;
    }

    sectionLoadingMap[slug]!.value = true;
    try {
      final url = Configss.getBannerCardsBySection(slug);
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<BannerCardModel> cards = data
            .map((json) => BannerCardModel.fromJson(json))
            .where((card) => card.isActive)
            .toList();

        // Sort cards by order
        cards.sort((a, b) => a.order.compareTo(b.order));
        sectionCardsMap[slug]!.assignAll(cards);
        return cards;
      } else {
        log('Failed to fetch cards for section $slug: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching cards for section $slug: $e');
    } finally {
      sectionLoadingMap[slug]!.value = false;
    }
    return [];
  }

  // Helper method to parse Hex Color string safely
  static int parseHexColor(String hexColorString, {int defaultColor = 0xFFFFFFFF}) {
    try {
      String hex = hexColorString.replaceAll('#', '').trim();
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      if (hex.length == 8) {
        return int.parse(hex, radix: 16);
      }
    } catch (_) {}
    return defaultColor;
  }
}
