import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../Controllers/authController.dart';
import '../../../../../Utils/appcolors.dart';
import '../../../../../Controllers/country_controller.dart';
import '../../../../../Widgets/country_selector.dart';
import '../../../../../Widgets/customappbar.dart';

import 'Account Details/account_details_screen.dart';
import 'Edit Profile/editprofile.dart';
import 'Security/security_password_screen.dart';
import 'Saved Addresses/saved_addresses_screen.dart';
import 'Danger Zone/danger_zone_screen.dart';
import 'Notification Inbox/notification_inbox_screen.dart';

class ProfileMenuScreen extends StatelessWidget {
  const ProfileMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(titleText: "My Profile"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Card
            GetBuilder<AuthController>(
              builder: (auth) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kdefwhiteColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: kPrimaryColor.withOpacity(0.12),
                        child: Text(
                          auth.fullName.value.isNotEmpty
                              ? auth.fullName.value[0].toUpperCase()
                              : "U",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.fullName.value.isNotEmpty
                                  ? auth.fullName.value
                                  : "User Profile",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auth.email.value,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            const Text(
              "PROFILE MENU",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),

            // Profile Sub-tabs Container Card
            Container(
              decoration: BoxDecoration(
                color: kdefwhiteColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 1. Account Details
                  ListTile(
                    minLeadingWidth: 0,
                    onTap: () => Get.to(() => const AccountDetailsScreen()),
                    leading: const Icon(Icons.person_outline_rounded,
                        color: kSecondaryColor, size: 22),
                    title: const Text('Account Details',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: kSecondaryColor, size: 14),
                  ),
                  Divider(height: 0, color: Colors.grey.withOpacity(0.2)),

                  // 2. Edit Profile
                  ListTile(
                    minLeadingWidth: 0,
                    onTap: () => Get.to(() => const EditProfile()),
                    leading: const Icon(Icons.edit_outlined,
                        color: kSecondaryColor, size: 22),
                    title: const Text('Edit Profile',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: kSecondaryColor, size: 14),
                  ),
                  Divider(height: 0, color: Colors.grey.withOpacity(0.2)),

                  // 3. Security & Password
                  ListTile(
                    minLeadingWidth: 0,
                    onTap: () => Get.to(() => const SecurityPasswordScreen()),
                    leading: const Icon(Icons.lock_outline_rounded,
                        color: kSecondaryColor, size: 22),
                    title: const Text('Security & Password',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: kSecondaryColor, size: 14),
                  ),
                  Divider(height: 0, color: Colors.grey.withOpacity(0.2)),

                  // 4. Saved Addresses
                  ListTile(
                    minLeadingWidth: 0,
                    onTap: () => Get.to(() => const SavedAddressesScreen()),
                    leading: const Icon(Icons.location_on_outlined,
                        color: kSecondaryColor, size: 22),
                    title: const Text('Saved Addresses',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: kSecondaryColor, size: 14),
                  ),
                  Divider(height: 0, color: Colors.grey.withOpacity(0.2)),

                  // 5. Notifications (push inbox)
                  ListTile(
                    minLeadingWidth: 0,
                    onTap: () => Get.to(() => const NotificationInboxScreen()),
                    leading: const Icon(Icons.notifications_outlined,
                        color: kSecondaryColor, size: 22),
                    title: const Text('Notifications',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: kSecondaryColor, size: 14),
                  ),
                  Divider(height: 0, color: Colors.grey.withOpacity(0.2)),

                  // 5b. Country / Currency
                  Obx(() {
                    final cc = Get.isRegistered<CountryController>()
                        ? Get.find<CountryController>()
                        : null;
                    final selected = cc?.selectedCountry.value;
                    return ListTile(
                      minLeadingWidth: 0,
                      onTap: () => showCountrySelector(context),
                      leading: selected == null
                          ? const Icon(Icons.public_outlined,
                              color: kSecondaryColor, size: 22)
                          : CountryFlag(selected.flagSvg,
                              width: 32, height: 22),
                      title: const Text('Country / Currency',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: selected == null
                          ? null
                          : Text(
                              '${selected.name} (${selected.currencyCode})',
                              style: const TextStyle(fontSize: 12),
                            ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: kSecondaryColor, size: 14),
                    );
                  }),
                  Divider(height: 0, color: Colors.grey.withOpacity(0.2)),

                  // 6. Danger Zone (Styled Card as shown in screenshot)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: InkWell(
                      onTap: () => Get.to(() => const DangerZoneScreen()),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.red, size: 22),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Danger Zone',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                color: Colors.red, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
