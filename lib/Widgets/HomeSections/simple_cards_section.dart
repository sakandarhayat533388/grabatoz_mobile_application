import 'package:flutter/material.dart';
import 'package:graba2z/Controllers/dynamic_section_controller.dart';
import 'package:graba2z/Models/home_section_model.dart';
import 'package:graba2z/Widgets/HomeSections/banner_card_item.dart';

class SimpleCardsSection extends StatelessWidget {
  final HomeSectionModel section;
  final List<BannerCardModel> cards;
  final Function(String linkUrl, String? title)? onCardTap;

  const SimpleCardsSection({
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cards.map((card) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: AspectRatio(
              aspectRatio: 3.2,
              child: BannerCardItem(
                card: card,
                fit: BoxFit.cover,
                showText: false,
                onTap: () {
                  if (onCardTap != null && card.linkUrl.isNotEmpty) {
                    onCardTap!(card.linkUrl, card.name.isNotEmpty ? card.name : section.name);
                  }
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
