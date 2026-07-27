import 'package:flutter/material.dart';
import 'package:graba2z/Controllers/dynamic_section_controller.dart';
import 'package:graba2z/Models/home_section_model.dart';
import 'package:graba2z/Widgets/HomeSections/banner_card_item.dart';

class VerticalGridSection extends StatelessWidget {
  final HomeSectionModel section;
  final List<BannerCardModel> cards;
  final Function(String linkUrl, String? title)? onCardTap;

  const VerticalGridSection({
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

    final columns = section.settings.cardsPerRow > 0 ? section.settings.cardsPerRow : 2;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: bgColor,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: 1.8,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemBuilder: (context, index) {
          final card = cards[index];
          return BannerCardItem(
            card: card,
            showText: false,
            fit: BoxFit.cover,
            onTap: () {
              if (onCardTap != null && card.linkUrl.isNotEmpty) {
                onCardTap!(card.linkUrl, card.name.isNotEmpty ? card.name : section.name);
              }
            },
          );
        },
      ),
    );
  }
}
