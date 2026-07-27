import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:graba2z/Controllers/dynamic_section_controller.dart';
import 'package:graba2z/Models/home_section_model.dart';
import 'package:graba2z/Widgets/HomeSections/banner_card_item.dart';

class SplitImageSection extends StatelessWidget {
  final HomeSectionModel section;
  final List<BannerCardModel> cards;
  final bool isImageLeft;
  final Function(String linkUrl, String? title)? onCardTap;

  const SplitImageSection({
    super.key,
    required this.section,
    required this.cards,
    this.isImageLeft = false,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final bgColor = Color(
      DynamicSectionController.parseHexColor(
        section.settings.backgroundColor,
        defaultColor: 0x00000000,
      ),
    );

    final sideImage = section.settings.sideImageUrl;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sideImage.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: double.infinity,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: sideImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return SizedBox(
                  width: 150,
                  child: BannerCardItem(
                    card: card,
                    showText: false,
                    onTap: () {
                      if (onCardTap != null && card.linkUrl.isNotEmpty) {
                        onCardTap!(card.linkUrl, card.name.isNotEmpty ? card.name : section.name);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
