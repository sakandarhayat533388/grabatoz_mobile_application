import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graba2z/Controllers/dynamic_section_controller.dart';
import 'package:graba2z/Models/home_section_model.dart';
import 'package:graba2z/Widgets/HomeSections/arrow_slider_section.dart';
import 'package:graba2z/Widgets/HomeSections/background_image_section.dart';
import 'package:graba2z/Widgets/HomeSections/banner_section.dart';
import 'package:graba2z/Widgets/HomeSections/simple_cards_section.dart';
import 'package:graba2z/Widgets/HomeSections/split_image_section.dart';
import 'package:graba2z/Widgets/HomeSections/vertical_grid_section.dart';
import 'package:shimmer/shimmer.dart';

class HomeSectionBuilder extends StatelessWidget {
  final HomeSectionModel section;
  final Function(String linkUrl, String? title)? onCardTap;

  const HomeSectionBuilder({
    super.key,
    required this.section,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final DynamicSectionController controller = Get.find<DynamicSectionController>();

    return Obx(() {
      final isLoading = controller.sectionLoadingMap[section.slug]?.value ?? false;
      final cards = controller.sectionCardsMap[section.slug]?.toList() ?? [];

      if (isLoading && cards.isEmpty) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: AspectRatio(
            aspectRatio: 3.2,
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      }

      if (cards.isEmpty) {
        return const SizedBox.shrink();
      }

      switch (section.sectionType) {
        case 'arrow-slider':
          return ArrowSliderSection(
            section: section,
            cards: cards,
            onCardTap: onCardTap,
          );

        case 'background-image':
          return BackgroundImageSection(
            section: section,
            cards: cards,
            onCardTap: onCardTap,
          );

        case 'cards-left-image-right':
          return SplitImageSection(
            section: section,
            cards: cards,
            isImageLeft: false,
            onCardTap: onCardTap,
          );

        case 'cards-right-image-left':
          return SplitImageSection(
            section: section,
            cards: cards,
            isImageLeft: true,
            onCardTap: onCardTap,
          );

        case 'vertical-grid':
          return VerticalGridSection(
            section: section,
            cards: cards,
            onCardTap: onCardTap,
          );

        case 'banner-section':
          return BannerSection(
            section: section,
            cards: cards,
            onCardTap: onCardTap,
          );

        case 'simple-cards':
        default:
          return SimpleCardsSection(
            section: section,
            cards: cards,
            onCardTap: onCardTap,
          );
      }
    });
  }
}
