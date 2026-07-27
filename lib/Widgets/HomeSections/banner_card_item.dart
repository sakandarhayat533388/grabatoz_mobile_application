import 'package:graba2z/Controllers/dynamic_section_controller.dart';
import 'package:graba2z/Models/home_section_model.dart';
import 'package:graba2z/Utils/packages.dart';

class BannerCardItem extends StatelessWidget {
  final BannerCardModel card;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool showText;

  const BannerCardItem({
    super.key,
    required this.card,
    this.onTap,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardBgColor = Color(
      DynamicSectionController.parseHexColor(card.bgColor, defaultColor: 0x00000000),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: card.displayImage,
                  fit: fit,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
              if (showText && (card.name.isNotEmpty || card.details.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (card.name.isNotEmpty)
                        Text(
                          card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      if (card.details.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            card.details,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
