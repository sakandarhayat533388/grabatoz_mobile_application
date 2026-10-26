import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import 'package:graba2z/Controllers/country_controller.dart';
import 'package:graba2z/Controllers/language_controller.dart';
import 'package:graba2z/Models/referral_models.dart';
import 'package:graba2z/Services/referral_api.dart';

/// Refer & Earn (referrals) state.
///
/// Settings are cached at launch; [panel] holds the signed-in user's
/// `/me` panel (own code/link, invites, rewards, stats). The checkout
/// fields hold the single selected reward id + the latest quote — [best]
/// from the server is preselected, and a selection that stops being
/// active is dropped on the next quote.
class ReferralController extends GetxController {
  final Rx<ReferralSettings?> settings = Rx<ReferralSettings?>(null);
  final RxBool settingsLoaded = false.obs;

  final Rx<ReferralPanel?> panel = Rx<ReferralPanel?>(null);
  final RxBool loadingPanel = false.obs;

  // --- Checkout -----------------------------------------------------------
  final RxString checkoutRewardId = ''.obs;
  final Rx<ReferralQuote?> checkoutQuote = Rx<ReferralQuote?>(null);
  final RxBool quoting = false.obs;

  bool get _isArabic =>
      Get.isRegistered<LanguageController>() &&
      Get.find<LanguageController>().isArabic;

  /// Selected country's ISO code, lowercased (e.g. "ae").
  /// `CountryController.countryCode` returns e.g. "AE" and already falls
  /// back to "AE" itself; 'ae' is only used when the controller is not
  /// registered (or somehow returns an empty code).
  String get _countryCode {
    if (Get.isRegistered<CountryController>()) {
      final code = Get.find<CountryController>().countryCode.trim();
      if (code.isNotEmpty) return code.toLowerCase();
    }
    return 'ae';
  }

  /// Settings actually in effect: the panel's copy wins over the cached
  /// public settings once the panel has loaded.
  ReferralSettings? get _effectiveSettings =>
      panel.value?.settings ?? settings.value;

  bool get isEnabled =>
      panel.value?.settings.isEnabled ?? settings.value?.isEnabled ?? false;

  /// Arabic-aware programme name, straight from the API.
  /// Falls back to the generic translation when settings have not loaded
  /// (or the API returned an empty name).
  String get programmeName {
    final s = _effectiveSettings;
    if (s == null) return 'referral_title'.tr;
    if (_isArabic && s.programmeNameAr.trim().isNotEmpty) {
      return s.programmeNameAr;
    }
    if (s.programmeName.trim().isNotEmpty) return s.programmeName;
    return 'referral_title'.tr;
  }

  /// The reward the shopper currently has selected at checkout, looked up
  /// in the latest quote. Null when nothing is selected, no quote has run
  /// yet, or the selected id is no longer in the quote.
  ReferralReward? get checkoutReward {
    final id = checkoutRewardId.value;
    if (id.isEmpty) return null;
    final quote = checkoutQuote.value;
    if (quote == null) return null;
    for (final reward in quote.rewards) {
      if (reward.id == id) return reward;
    }
    return null;
  }

  /// AED discount the selected reward gives on this order (per the quote).
  double get checkoutDiscountAed => checkoutReward?.quoteDiscountAed ?? 0.0;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  /// Loads (and caches) the public programme settings.
  /// `ReferralApi.fetchSettings` never throws; [settingsLoaded] is set
  /// regardless so the UI can stop waiting and simply hide the programme
  /// when no settings arrived.
  Future<void> loadSettings() async {
    try {
      final fetched = await ReferralApi.fetchSettings();
      if (fetched != null) {
        settings.value = fetched;
      }
    } catch (_) {
      // Keep any previously cached settings.
    } finally {
      settingsLoaded.value = true;
    }
  }

  /// Reloads the user's referral panel for the current country/language.
  /// Also refreshes [settings] from the panel's settings copy.
  /// Errors are swallowed: the previous panel stays on screen.
  Future<void> refreshPanel() async {
    if (loadingPanel.value) return;
    loadingPanel.value = true;
    try {
      final fetched = await ReferralApi.fetchMe(
        country: _countryCode,
        lang: _isArabic ? 'ar' : 'en',
      );
      panel.value = fetched;
      final ReferralSettings? panelSettings = fetched.settings;
      if (panelSettings != null) {
        settings.value = panelSettings;
        settingsLoaded.value = true;
      }
    } catch (_) {
      // Keep the old panel / settings on failure.
    } finally {
      loadingPanel.value = false;
    }
  }

  /// Quotes the user's rewards against [eligibleAmount] for checkout.
  ///
  /// Preselects the server's `best` reward when nothing is selected, and
  /// clears a selection that is no longer among the quote's active rewards
  /// (then preselects `best` if there is one). Errors are swallowed: the
  /// previous quote/selection is kept — checkout never blocks on a quote.
  Future<void> quoteCheckout(double eligibleAmount) async {
    if (quoting.value) return;
    quoting.value = true;
    try {
      final quote = await ReferralApi.quote(eligibleAmount: eligibleAmount);
      checkoutQuote.value = quote;

      final activeIds = quote.rewards
          .where((r) => r.isActive)
          .map((r) => r.id)
          .toSet();
      if (checkoutRewardId.value.isNotEmpty &&
          !activeIds.contains(checkoutRewardId.value)) {
        checkoutRewardId.value = '';
      }
      if (checkoutRewardId.value.isEmpty && quote.best != null) {
        checkoutRewardId.value = quote.best!.id;
      }
    } catch (_) {
      // Keep the previous quote and selection.
    } finally {
      quoting.value = false;
    }
  }

  /// Clears the checkout reward selection (e.g. after a successful order).
  void clearCheckout() {
    checkoutRewardId.value = '';
    checkoutQuote.value = null;
  }

  /// Shares the user's referral link using the API's share message
  /// (`{{link}}` replaced with the user's own link).
  ///
  /// Falls back to copying the raw link to the clipboard (with a
  /// confirmation snackbar) when there is no share template; does nothing
  /// when there is no link at all.
  Future<void> shareReferral() async {
    final link = panel.value?.link ?? '';

    var template = settings.value?.shareMessage ?? '';
    if (template.trim().isEmpty) {
      template = panel.value?.settings.shareMessage ?? '';
    }

    if (template.trim().isEmpty || link.trim().isEmpty) {
      if (link.isEmpty) return;
      await Clipboard.setData(ClipboardData(text: link));
      Get.snackbar('', 'referral_link_copied'.tr);
      return;
    }

    final message = template.replaceAll('{{link}}', link);
    await Share.share(message);
  }
}
