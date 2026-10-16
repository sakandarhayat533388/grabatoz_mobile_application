import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:graba2z/Controllers/country_controller.dart';

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Select Country / Currency',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
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
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = controller.countries[i];
                  final selected =
                      controller.selectedCountry.value?.code == c.code;
                  return ListTile(
                    leading: _flag(c.flagSvg),
                    title: Text(c.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${c.currencyCode} · ${c.currencySymbol}'),
                    trailing: selected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () async {
                      await controller.selectCountry(c);
                      Get.back();
                    },
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

Widget _flag(String svg) {
  if (svg.trim().isNotEmpty) {
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SvgPicture.string(svg, width: 36, height: 24, fit: BoxFit.cover),
      );
    } catch (_) {}
  }
  return const Icon(Icons.flag_outlined, size: 28);
}
