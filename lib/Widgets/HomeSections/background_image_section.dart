import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:graba2z/Controllers/dynamic_section_controller.dart';
import 'package:graba2z/Models/home_section_model.dart';
import 'package:graba2z/Widgets/HomeSections/banner_card_item.dart';

class BackgroundImageSection extends StatelessWidget {
  final HomeSectionModel section;
  final List<BannerCardModel> cards;
  final Function(String linkUrl, String? title)? onCardTap;

  const BackgroundImageSection({
    super.key,
    required this.section,
    required this.cards,
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

    final bgImageUrl = section.settings.backgroundImageUrl;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        image: bgImageUrl.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider(bgImageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.15),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return SizedBox(
              width: 160,
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
    );
  }
}
