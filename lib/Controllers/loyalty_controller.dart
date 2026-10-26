import 'package:get/get.dart';

import 'package:graba2z/Controllers/language_controller.dart';
import 'package:graba2z/Models/loyalty_models.dart';
import 'package:graba2z/Services/loyalty_api.dart';

/// Grabian Points (loyalty) state.
///
/// Settings are cached at launch (the programme hides itself when
/// [isEnabled] is false), [account] holds the latest `/me` page, and the
/// checkout fields hold the shopper's current points redemption + quote.
///
/// Transaction history: [account] is replaced by every fetched page, so its
/// `transactions` only ever contains that one page. The UI must therefore
/// read the accumulated history from [transactions] instead — it is seeded
/// by [refreshAccount] and appended to by [loadMoreTransactions], while
/// [account] is only kept for balance data and page / hasMore bookkeeping.
class LoyaltyController extends GetxController {
  final Rx<LoyaltySettings?> settings = Rx<LoyaltySettings?>(null);
  final RxBool settingsLoaded = false.obs;

  final Rx<LoyaltyAccount?> account = Rx<LoyaltyAccount?>(null);
  final RxBool loadingAccount = false.obs;
  final RxBool loadingMore = false.obs;

  /// Accumulated transaction history across all loaded pages.
  /// See the class doc: read this, not `account.transactions`.
  final RxList<LoyaltyTransaction> transactions = <LoyaltyTransaction>[].obs;

  // --- Checkout -----------------------------------------------------------
  final RxInt checkoutPoints = 0.obs;
  final Rx<LoyaltyQuote?> checkoutQuote = Rx<LoyaltyQuote?>(null);
  final RxBool quoting = false.obs;

  /// Announcements are shown at most once per app session.
  bool announcementsShownThisSession = false;

  bool get _isArabic =>
      Get.isRegistered<LanguageController>() &&
      Get.find<LanguageController>().isArabic;

  bool get isEnabled => settings.value?.isEnabled ?? false;

  /// Arabic-aware programme/points name, straight from the API.
  /// Falls back to the generic translation when settings have not loaded
  /// (or the API returned an empty name).
  String get pointsName {
    final s = settings.value;
    if (s == null) return 'loyalty_title'.tr;
    if (_isArabic && s.pointsNameAr.trim().isNotEmpty) return s.pointsNameAr;
    if (s.pointsName.trim().isNotEmpty) return s.pointsName;
    return 'loyalty_title'.tr;
  }

  /// AED discount currently applied at checkout, from the latest quote.
  /// 0 unless points are selected AND a quote backs them.
  double get checkoutDiscountAed =>
      (checkoutPoints.value > 0 && checkoutQuote.value != null)
      ? checkoutQuote.value!.discountAed
      : 0.0;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  /// Loads (and caches) the public programme settings.
  /// `LoyaltyApi.fetchSettings` never throws; [settingsLoaded] is set
  /// regardless so the UI can stop waiting and simply hide the programme
  /// when no settings arrived.
  Future<void> loadSettings() async {
    try {
      final fetched = await LoyaltyApi.fetchSettings();
      if (fetched != null) {
        settings.value = fetched;
      }
    } catch (_) {
      // Keep any previously cached settings.
    } finally {
      settingsLoaded.value = true;
    }
  }

  /// Reloads page 1 of the account (balance + first transactions page).
  /// Errors are swallowed: the previous account stays on screen.
  Future<void> refreshAccount() async {
    if (loadingAccount.value) return;
    loadingAccount.value = true;
    try {
      final fetched = await LoyaltyApi.fetchMe(page: 1, limit: 20);
      account.value = fetched;
      transactions.assignAll(fetched.transactions);
    } catch (_) {
      // Keep the old account / transactions on failure.
    } finally {
      loadingAccount.value = false;
    }
  }

  /// Appends the next transactions page to [transactions].
  /// [account] is replaced with the newly fetched page (for its page /
  /// hasMore bookkeeping); its `transactions` are only that page — the UI
  /// reads the full history from [transactions].
  Future<void> loadMoreTransactions() async {
    final current = account.value;
    if (current == null || !current.hasMore || loadingMore.value) return;
    loadingMore.value = true;
    try {
      final fetched = await LoyaltyApi.fetchMe(
        page: current.page + 1,
        limit: current.limit,
      );
      transactions.addAll(fetched.transactions);
      account.value = fetched;
    } catch (_) {
      // Keep the history loaded so far; hasMore stays as it was.
    } finally {
      loadingMore.value = false;
    }
  }

  /// Quotes a points redemption for checkout.
  ///
  /// A non-positive [requestedPoints] clears the selection (no API call).
  /// Otherwise the server-rounded `quote.points` wins over the request.
  /// On error the previous quote/selection is kept — checkout never blocks
  /// on a failed quote.
  Future<void> quoteCheckout(double eligibleAmount, int requestedPoints) async {
    if (requestedPoints <= 0) {
      checkoutPoints.value = 0;
      checkoutQuote.value = null;
      return;
    }
    quoting.value = true;
    try {
      final quote = await LoyaltyApi.quote(
        eligibleAmount: eligibleAmount,
        requestedPoints: requestedPoints,
      );
      checkoutQuote.value = quote;
      checkoutPoints.value = quote.points;
    } catch (_) {
      // Keep the previous quote and selection.
    } finally {
      quoting.value = false;
    }
  }

  /// Clears the checkout redemption (e.g. after a successful order).
  void clearCheckout() {
    checkoutPoints.value = 0;
    checkoutQuote.value = null;
  }

  /// Fetches any un-acknowledged "points confirmed" announcements.
  /// `LoyaltyApi.fetchAnnouncements` never throws.
  Future<LoyaltyAnnouncements> checkAnnouncements() async {
    return await LoyaltyApi.fetchAnnouncements();
  }

  /// Acknowledges the announcements so they are not shown again.
  Future<void> ackAnnouncements() async {
    await LoyaltyApi.ackAnnouncements();
  }
}
