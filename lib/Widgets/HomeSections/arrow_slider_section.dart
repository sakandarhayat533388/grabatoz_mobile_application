import 'package:flutter/material.dart';
import 'package:graba2z/Controllers/dynamic_section_controller.dart';
import 'package:graba2z/Models/home_section_model.dart';
import 'package:graba2z/Widgets/HomeSections/banner_card_item.dart';

class ArrowSliderSection extends StatefulWidget {
  final HomeSectionModel section;
  final List<BannerCardModel> cards;
  final Function(String linkUrl, String? title)? onCardTap;

  const ArrowSliderSection({
    super.key,
    required this.section,
    required this.cards,
    this.onCardTap,
  });

  @override
  State<ArrowSliderSection> createState() => _ArrowSliderSectionState();
}

class _ArrowSliderSectionState extends State<ArrowSliderSection> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();

    final bgColor = Color(
      DynamicSectionController.parseHexColor(
        widget.section.settings.backgroundColor,
        defaultColor: 0x00000000,
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: bgColor,
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.cards.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final card = widget.cards[index];
                return BannerCardItem(
                  card: card,
                  width: double.infinity,
                  showText: false,
                  fit: BoxFit.cover,
                  onTap: () {
                    if (widget.onCardTap != null && card.linkUrl.isNotEmpty) {
                      widget.onCardTap!(card.linkUrl, card.name.isNotEmpty ? card.name : widget.section.name);
                    }
                  },
                );
              },
            ),
          ),
          if (widget.cards.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.cards.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.black87 : Colors.grey[400],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
