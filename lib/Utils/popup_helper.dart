import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:graba2z/Api/Services/apiservices.dart';
import 'package:graba2z/Api/Models/popup_settings_model.dart';
import 'package:graba2z/Utils/image_helper.dart';
import 'package:graba2z/Views/Auth/signup.dart';
import 'packages.dart';

class PopupHelper {
  static Future<void> showIfNeeded(BuildContext context, String pageKey) async {
    try {
      final apiService = Get.find<ApiServiceController>();
      final popup = await apiService.fetchActivePopup(pageKey: pageKey);
      
      if (popup == null || !popup.isEnabled) {
        return;
      }
      
      if (!context.mounted) return;

      final prefs = await SharedPreferences.getInstance();

      if (popup.showLimit == 'once') {
        final lastShownPopupId = prefs.getString('last_shown_popup_id');
        if (lastShownPopupId == popup.id) {
          // Already shown this popup, do not show again.
          return;
        }
        await prefs.setString('last_shown_popup_id', popup.id);
      }

      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          final media = MediaQuery.of(context);
          final dialogWidth =
              (media.size.width - 32).clamp(280.0, 390.0).toDouble();
          final imageAspectRatio = 2.1; // aspect ratio for the top banner image
          final bannerHeight = dialogWidth / imageAspectRatio;

          final bool hasMobileImage = popup.mobileImageUrl != null && popup.mobileImageUrl!.isNotEmpty;

          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: SizedBox(
              width: dialogWidth,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Material(
                  color: kdefwhiteColor,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Top Image Banner with close button overlay
                        Stack(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: bannerHeight,
                              child: hasMobileImage
                                  ? CachedNetworkImage(
                                      imageUrl: ImageHelper.getUrl(popup.mobileImageUrl!),
                                      fit: BoxFit.fill,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(
                                          color: kPrimaryColor,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) {
                                        return _fallbackBanner(bannerHeight);
                                      },
                                    )
                                  : _fallbackBanner(bannerHeight),
                            ),
                            // Close Button 'X'
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: kdefwhiteColor.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.black54,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 2. Section Title
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 16.0, right: 16.0),
                          child: Text(
                            popup.sectionTitle ?? '- Why Download Our App? -',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF0C3E16),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // 3. Features Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFeatureColumn(
                                icon: Icons.local_offer_outlined,
                                label: popup.feature1Label ?? 'Exclusive\nApp Discounts',
                              ),
                              _buildFeatureColumn(
                                icon: Icons.flash_on_outlined,
                                label: popup.feature2Label ?? 'Faster &\nSmooth Checkout',
                              ),
                              _buildFeatureColumn(
                                icon: Icons.notifications_none_outlined,
                                label: popup.feature3Label ?? 'Early Access to\nDeals & Offers',
                              ),
                            ],
                          ),
                        ),

                        // 4. Dashed Promo Box
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                          child: CustomPaint(
                            painter: DashedRectPainter(
                              color: const Color(0xFF007E2F),
                              strokeWidth: 1.5,
                              gap: 4.0,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (popup.discountTopText != null && popup.discountTopText!.isNotEmpty)
                                    Text(
                                      popup.discountTopText!.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF0C3E16),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    popup.discountValue ?? '5% OFF',
                                    style: const TextStyle(
                                      color: Color(0xFF007E2F),
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (popup.discountBottomText != null && popup.discountBottomText!.isNotEmpty)
                                    Text(
                                      popup.discountBottomText!.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF0C3E16),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (popup.discountNote != null && popup.discountNote!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      popup.discountNote!,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 5. Store Buttons Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStoreButton(
                                  isApple: false,
                                  link: popup.googlePlayLink ?? '',
                                  context: context,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildStoreButton(
                                  isApple: true,
                                  link: popup.appStoreLink ?? '',
                                  context: context,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 6. Continue to Website Button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                popup.continueButtonText ?? 'Continue to Website',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('Error showing promotional popup: $e');
    }
  }

  static Widget _fallbackBanner(double height) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0C3E16), Color(0xFF176728)],
        ),
      ),
      child: Center(
        child: Image.asset(
          AppImages.logoicon,
          width: 120,
          fit: BoxFit.contain,
          color: kdefwhiteColor,
        ),
      ),
    );
  }

  static Widget _buildFeatureColumn({required IconData icon, required String label}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE2F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0C3E16),
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStoreButton({
    required bool isApple,
    required String link,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () async {
        Navigator.of(context).pop();
        if (link.isNotEmpty) {
          final uri = Uri.tryParse(link);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        }
        Get.to(() => const SignUp());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF007E2F),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isApple ? Icons.apple : Icons.play_arrow_rounded,
              color: kdefwhiteColor,
              size: isApple ? 22 : 20,
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isApple ? "Download on the" : "GET IT ON",
                  style: const TextStyle(
                    color: kdefwhiteColor,
                    fontSize: 6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  isApple ? "App Store" : "Google Play",
                  style: const TextStyle(
                    color: kdefwhiteColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for dashed rectangle border
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));

    final dashedPath = Path();
    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
