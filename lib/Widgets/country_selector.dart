import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:graba2z/Api/Models/country_model.dart';
import 'package:graba2z/Controllers/country_controller.dart';

/// Small rounded flag widget, reused by the settings rows and the selector.
/// Falls back to a neutral icon when the SVG is missing or invalid.
class CountryFlag extends StatelessWidget {
  final String svg;
  final double width;
  final double height;

  const CountryFlag(this.svg,
      {super.key, this.width = 34, this.height = 24});

  @override
  Widget build(BuildContext context) {
    if (svg.trim().isNotEmpty) {
      try {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border:
                Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SvgPicture.string(
              svg,
              width: width,
              height: height,
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (_) {}
    }
    return Icon(Icons.flag_outlined,
        size: height + 4, color: Colors.grey.shade400);
  }
}

/// Bottom-sheet country / currency switcher.
///
/// Shows the public country list with inline SVG flags. On selection the
/// [CountryController] persists the choice and refreshes payment charges;
/// screens that depend on the country (e.g. the payment screen) re-resolve
/// via their own listeners.
Future<void> showCountrySelector(BuildContext context) {
  if (!Get.isRegistered<CountryController>()) return Future.value();
  final CountryController controller = Get.find<CountryController>();

  return Get.bottomSheet(
    Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Select Country / Currency',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Prices will be shown in the selected currency',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: Obx(() {
              if (controller.isLoading.value && controller.countries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.countries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No countries available'),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                itemCount: controller.countries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final c = controller.countries[i];
                  final selected =
                      controller.selectedCountry.value?.code == c.code;
                  return Material(
                    color: selected
                        ? Colors.green.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      leading: CountryFlag(c.flagSvg),
                      title: Text(c.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        _currencyLabel(c),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      trailing: Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color:
                            selected ? Colors.green : Colors.grey.shade400,
                        size: 24,
                      ),
                      onTap: () async {
                        await controller.selectCountry(c);
                        Get.back();
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
  );
}

/// Avoids redundant labels like "AED - AED".
String _currencyLabel(Country c) {
  if (c.currencySymbol.trim().isEmpty ||
      c.currencySymbol == c.currencyCode) {
    return c.currencyCode;
  }
  return '${c.currencyCode} (${c.currencySymbol})';
}
