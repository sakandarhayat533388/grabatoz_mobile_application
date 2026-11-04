import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:graba2z/Api/Models/country_model.dart';
import 'package:graba2z/Controllers/country_controller.dart';
import 'package:graba2z/Controllers/language_controller.dart';
import 'package:graba2z/Utils/appcolors.dart';
import 'package:graba2z/Utils/imageconstants.dart';
import 'package:graba2z/Views/Home/home.dart';
import 'package:graba2z/Widgets/theme_logo.dart';

/// SharedPreferences flag: once true, onboarding never shows again.
/// The splash screen reads the same key to pick its destination.
const String kOnboardingDoneKey = 'onboarding_completed';

/// First-launch onboarding (shown once, until [kOnboardingDoneKey] is set):
/// page 1 picks the country, page 2 the language. Both pages write through
/// the same [CountryController] / [LanguageController] the Settings rows
/// use, so the choices stay in sync everywhere. No skip — each page has a
/// sensible default preselected.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  CountryController get _countryCtrl => Get.find<CountryController>();
  LanguageController get _langCtrl => Get.find<LanguageController>();

  @override
  void initState() {
    super.initState();
    _preselectFromDevice();
    if (Get.isRegistered<CountryController>() &&
        _countryCtrl.countries.isEmpty) {
      _countryCtrl.fetchCountries();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// First launch only: when the user has never saved a language, mirror
  /// the device — an Arabic device starts onboarding in Arabic.
  Future<void> _preselectFromDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('app_language') == null &&
          PlatformDispatcher.instance.locale.languageCode ==
              LanguageController.arabicCode) {
        await _langCtrl.setLanguage(LanguageController.arabicCode);
      }
    } catch (_) {}
  }

  Future<void> _finish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kOnboardingDoneKey, true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(seconds: 1),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const Home(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation.drive(
              Tween<double>(begin: 0.0, end: 1.0).chain(
                CurveTween(curve: Curves.easeInOut),
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _next() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Soft splash-style green shapes (mirror in RTL).
          PositionedDirectional(
            top: -160,
            end: -150,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryColor.withValues(alpha: 0.14),
              ),
            ),
          ),
          PositionedDirectional(
            top: -120,
            end: -110,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryColor.withValues(alpha: 0.18),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: -190,
            start: -160,
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryColor.withValues(alpha: 0.10),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Center(
                  child: ThemeLogo(
                    width: 180,
                    fallbackAsset: AppImages.logoicon,
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _buildCountryPage(),
                      _buildLanguagePage(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: [
                      _buildDots(),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor:
                                kPrimaryColor.withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _page == 0 ? _next : _finish,
                          child: Text(
                            _page == 0
                                ? 'continue'.tr
                                : 'onboarding_start_shopping'.tr,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 2; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 3.5),
            width: _page == i ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: _page == i ? kPrimaryColor : const Color(0xFFDDDDDD),
            ),
          ),
      ],
    );
  }

  Widget _pageHeading(String title, String subtitle) {
    return Column(
      children: [
        const SizedBox(height: 34),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF8A8A8A),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  // --- Page 1: country -----------------------------------------------------

  Widget _buildCountryPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          _pageHeading(
            'onboarding_country_title'.tr,
            'onboarding_country_sub'.tr,
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Obx(() {
              // Reading the language keeps country names localized live.
              final isArabic = _langCtrl.isArabic;
              final countries = _countryCtrl.countries;
              final selectedCode = _countryCtrl.countryCode;
              if (countries.isEmpty) {
                final fallback = _countryCtrl.selectedCountry.value;
                if (fallback == null) {
                  return Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  );
                }
                return ListView(
                  children: [
                    _countryCard(fallback, true, isArabic),
                  ],
                );
              }
              return ListView.separated(
                itemCount: countries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final country = countries[index];
                  return _countryCard(
                    country,
                    country.code.toUpperCase() == selectedCode.toUpperCase(),
                    isArabic,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _countryCard(Country country, bool selected, bool isArabic) {
    final name = (isArabic && country.nameAr.trim().isNotEmpty)
        ? country.nameAr
        : country.name;
    return GestureDetector(
      onTap: () => _countryCtrl.selectCountry(country),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFAFDF0) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kPrimaryColor : const Color(0xFFEEEEEE),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? kPrimaryColor.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _circleFlag(country.flagSvg),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1C),
                ),
              ),
            ),
            Text(
              country.currencyCode,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9A9A9A),
              ),
            ),
            const SizedBox(width: 12),
            _radio(selected),
          ],
        ),
      ),
    );
  }

  Widget _circleFlag(String svg) {
    Widget inner = const Icon(Icons.flag_outlined,
        size: 20, color: Color(0xFFBDBDBD));
    if (svg.trim().isNotEmpty) {
      try {
        inner = SvgPicture.string(
          svg,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
        );
      } catch (_) {}
    }
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFEEEEEE)),
        color: const Color(0xFFF5F5F5),
      ),
      child: ClipOval(child: inner),
    );
  }

  // --- Page 2: language ----------------------------------------------------

  Widget _buildLanguagePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          _pageHeading(
            'onboarding_language_title'.tr,
            'onboarding_language_sub'.tr,
          ),
          const SizedBox(height: 30),
          Obx(() {
            final isArabic = _langCtrl.isArabic;
            return Column(
              children: [
                _languageCard(
                  code: LanguageController.englishCode,
                  badge: 'EN',
                  title: 'English',
                  subtitle: 'onboarding_lang_english'.tr,
                  selected: !isArabic,
                ),
                const SizedBox(height: 14),
                _languageCard(
                  code: LanguageController.arabicCode,
                  badge: 'ع',
                  title: 'العربية',
                  subtitle: 'onboarding_lang_arabic'.tr,
                  selected: isArabic,
                ),
              ],
            );
          }),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: kPrimaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'onboarding_arabic_note'.tr,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF8A8A8A),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageCard({
    required String code,
    required String badge,
    required String title,
    required String subtitle,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () => _langCtrl.setLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFAFDF0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? kPrimaryColor : const Color(0xFFEEEEEE),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? kPrimaryColor.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? kPrimaryColor
                    : const Color(0xFFF1F8DC),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: badge == 'EN' ? 17 : 19,
                  fontWeight: FontWeight.w800,
                  color:
                      selected ? Colors.white : const Color(0xFF65A30D),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF9A9A9A),
                    ),
                  ),
                ],
              ),
            ),
            _radio(selected),
          ],
        ),
      ),
    );
  }

  // --- Shared --------------------------------------------------------------

  Widget _radio(bool selected) {
    return Container(
      width: 23,
      height: 23,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? kPrimaryColor : Colors.transparent,
        border: Border.all(
          color: selected ? kPrimaryColor : const Color(0xFFD5D5D5),
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
