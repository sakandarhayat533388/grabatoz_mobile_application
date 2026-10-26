import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:graba2z/Controllers/referral_controller.dart';
import 'package:graba2z/Models/referral_models.dart';
import 'package:graba2z/Utils/appcolors.dart';
import 'package:graba2z/Utils/price_formatter.dart';
import 'package:graba2z/Views/Auth/login.dart';

/// Refer & Earn screen: the "you get / friend gets" offers, the user's
/// own code (copy + share), stats, invites and rewards — all from the
/// signed-in panel payload, never hardcoded.
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  late final ReferralController _ctrl;

  bool _isLoggedIn = false;
  bool _loginChecked = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.isRegistered<ReferralController>()
        ? Get.find<ReferralController>()
        : Get.put(ReferralController());
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final loggedIn = token != null && token.isNotEmpty;
    if (!mounted) return;
    setState(() {
      _isLoggedIn = loggedIn;
      _loginChecked = true;
    });
    if (loggedIn) {
      _ctrl.refreshPanel();
    }
  }

  /// 20 -> "20", 12.5 -> "12.5".
  String _fmtNum(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    var text = value.toString();
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }

  /// Human-readable offer line, e.g. "20% off · on orders over AED 100.00
  /// · first order only". Empty string when there is no offer.
  String _offerText(ReferralOffer? offer) {
    if (offer == null) return '';
    return _offerTextFromFields(
      discountType: offer.discountType,
      discountValue: offer.discountValue,
      minOrderAed: offer.minOrderAed,
      firstOrderOnly: offer.firstOrderOnly,
    );
  }

  String _offerTextFromFields({
    required String discountType,
    required double discountValue,
    required double minOrderAed,
    required bool firstOrderOnly,
  }) {
    if (discountValue <= 0) return '';
    var text = discountType == 'percentage'
        ? 'referral_off_percent'.trParams({'value': _fmtNum(discountValue)})
        : 'referral_off_fixed'
            .trParams({'amount': formatPriceForSelected(discountValue)});
    if (minOrderAed > 0) {
      text +=
          ' · ${'referral_min_order'.trParams({'amount': formatPriceForSelected(minOrderAed)})}';
    }
    if (firstOrderOnly) {
      text += ' · ${'referral_first_order_only'.tr}';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Obx(() => Text(_ctrl.programmeName)),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        // Programme switched off.
        if (_ctrl.settingsLoaded.value && !_ctrl.isEnabled) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'referral_disabled'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: kSecondaryColor),
              ),
            ),
          );
        }

        if (!_loginChecked) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!_isLoggedIn) {
          return _buildLoginPrompt();
        }

        if (_ctrl.loadingPanel.value && _ctrl.panel.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final panel = _ctrl.panel.value;
        final settings = panel?.settings ?? _ctrl.settings.value;

        return RefreshIndicator(
          color: kPrimaryColor,
          onRefresh: _ctrl.refreshPanel,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeroCard(panel, settings),
              const SizedBox(height: 16),
              if (panel?.code != null && panel!.code!.isNotEmpty) ...[
                _buildCodeCard(panel.code!),
                const SizedBox(height: 16),
              ],
              if (panel?.stats != null) ...[
                _buildStatsRow(panel!.stats!),
                const SizedBox(height: 16),
              ],
              _sectionTitle('referral_invites'.tr),
              const SizedBox(height: 8),
              if (panel == null || panel.invites.isEmpty)
                _emptyText('referral_no_invites'.tr)
              else
                ...panel.invites.map(_buildInviteItem),
              const SizedBox(height: 16),
              _sectionTitle('referral_rewards'.tr),
              const SizedBox(height: 8),
              if (panel == null || panel.rewards.isEmpty)
                _emptyText('referral_no_rewards'.tr)
              else
                ..._sortedRewards(panel.rewards).map(_buildRewardItem),
              _buildTerms(settings),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 56, color: kPrimaryColor),
            const SizedBox(height: 16),
            Text(
              'referral_login_required'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: kSecondaryColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => Get.to(() => const Login()),
              child: Text('auth_login_title'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(ReferralPanel? panel, ReferralSettings? settings) {
    // The panel's offer object wins over the cached settings copy.
    final referrerOffer = panel?.offerReferrer ?? settings?.offerReferrer;
    final refereeOffer = panel?.offerReferee ?? settings?.offerReferee;
    final referrerText = _offerText(referrerOffer);
    final refereeText = _offerText(refereeOffer);
    final qualifyStatus = settings?.qualifyOnOrderStatus ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (referrerText.isNotEmpty)
            Text(
              'referral_you_get'.trParams({'offer': referrerText}),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (refereeText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'referral_friend_gets'.trParams({'offer': refereeText}),
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
          if (qualifyStatus.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'referral_qualify_note'
                        .trParams({'status': qualifyStatus}),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeCard(String code) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: defaultBoxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'referral_your_code'.tr,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: kSecondaryColor,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  Get.snackbar('', 'referral_code_copied'.tr);
                },
                icon: const Icon(Icons.copy, size: 18),
                label: Text('referral_copy'.tr),
                style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _ctrl.shareReferral(),
              icon: const Icon(Icons.share, size: 18),
              label: Text('referral_share'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ReferralStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: defaultBoxShadow,
      ),
      child: Row(
        children: [
          _statColumn('referral_invited'.tr, '${stats.total}'),
          _statColumn('referral_qualified'.tr, '${stats.qualified}'),
          _statColumn(
            'referral_earned'.tr,
            formatPriceForSelected(stats.totalEarnedAed),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: kSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: kSecondaryColor,
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }

  Widget _statusChip(String status) {
    Color background;
    Color foreground;
    switch (status) {
      case 'pending':
        background = Colors.amber.shade100;
        foreground = Colors.amber.shade800;
        break;
      case 'qualified':
      case 'active':
        background = Colors.green.shade100;
        foreground = Colors.green.shade800;
        break;
      case 'used':
        background = Colors.blue.shade100;
        foreground = Colors.blue.shade800;
        break;
      case 'cancelled':
      case 'expired':
        background = Colors.grey.shade200;
        foreground = Colors.grey.shade700;
        break;
      default:
        background = Colors.grey.shade200;
        foreground = Colors.grey.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'referral_status_$status'.tr,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Widget _buildInviteItem(ReferralInvite invite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: defaultBoxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  invite.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                  ),
                ),
              ),
              _statusChip(invite.status),
            ],
          ),
          if (invite.email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              invite.email,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          if (invite.joinedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              DateFormat.yMMMd().format(invite.joinedAt!),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          if (invite.notRewardedReason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: Colors.amber.shade800),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    invite.notRewardedReason,
                    style:
                        TextStyle(fontSize: 12, color: Colors.amber.shade800),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<ReferralReward> _sortedRewards(List<ReferralReward> rewards) {
    final sorted = [...rewards];
    sorted.sort(
      (a, b) => (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0),
    );
    return sorted;
  }

  Widget _buildRewardItem(ReferralReward reward) {
    final discountText = _offerTextFromFields(
      discountType: reward.discountType,
      discountValue: reward.discountValue,
      minOrderAed: reward.minOrderAed,
      firstOrderOnly: reward.firstOrderOnly,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: defaultBoxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reward.description.isNotEmpty
                      ? reward.description
                      : reward.referralTypeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                  ),
                ),
              ),
              _statusChip(reward.status),
            ],
          ),
          if (discountText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              discountText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kPrimaryColor,
              ),
            ),
          ],
          if (reward.expiresAt != null) ...[
            const SizedBox(height: 4),
            Text(
              // No referral-specific expiry key exists; loyalty_expires_on
              // is the generic "Expires @date" string.
              'loyalty_expires_on'.trParams({
                'date': DateFormat.yMMMd().format(reward.expiresAt!),
              }),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          if (reward.status == 'used' && reward.discountAppliedAed > 0) ...[
            const SizedBox(height: 4),
            Text(
              formatPriceForSelected(reward.discountAppliedAed),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTerms(ReferralSettings? settings) {
    final terms = settings?.programmeTerms ?? '';
    if (terms.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        terms,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
