import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:graba2z/Controllers/loyalty_controller.dart';
import 'package:graba2z/Models/loyalty_models.dart';
import 'package:graba2z/Utils/appcolors.dart';
import 'package:graba2z/Utils/price_formatter.dart';
import 'package:graba2z/Views/Auth/login.dart';

/// Grabian Points (loyalty) screen: balance card, how-it-works rules
/// from the live programme settings, and the paged transaction history.
class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  late final LoyaltyController _ctrl;
  final ScrollController _scrollController = ScrollController();

  bool _isLoggedIn = false;
  bool _loginChecked = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.isRegistered<LoyaltyController>()
        ? Get.find<LoyaltyController>()
        : Get.put(LoyaltyController());
    _scrollController.addListener(_onScroll);
    _checkLogin();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _ctrl.loadMoreTransactions();
    }
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
      _ctrl.refreshAccount();
    }
  }

  /// 1000 -> "1000", 0.5 -> "0.5", 2.50 -> "2.5".
  String _fmtNum(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    var text = value.toString();
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }

  Color _tierColor(String raw) {
    try {
      return Color(int.parse(raw.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Obx(() => Text(_ctrl.pointsName)),
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
                'loyalty_disabled'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: kSecondaryColor),
              ),
            ),
          );
        }

        // Login state not known yet.
        if (!_loginChecked) {
          return const Center(child: CircularProgressIndicator());
        }

        // Guests: settings are public, the account is not.
        if (!_isLoggedIn) {
          return _buildLoginPrompt();
        }

        if (_ctrl.loadingAccount.value && _ctrl.account.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          color: kPrimaryColor,
          onRefresh: _ctrl.refreshAccount,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 16),
              if (_ctrl.settings.value != null) _buildHowItWorksCard(),
              if (_ctrl.settings.value != null) const SizedBox(height: 16),
              Text(
                'loyalty_history'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              if (_ctrl.transactions.isEmpty &&
                  !_ctrl.loadingAccount.value &&
                  !_ctrl.loadingMore.value)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'loyalty_no_transactions'.tr,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._ctrl.transactions.map(_buildTransactionItem),
              if (_ctrl.loadingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              _buildTerms(),
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
            Icon(Icons.lock_outline, size: 56, color: kPrimaryColor),
            const SizedBox(height: 16),
            Text(
              'loyalty_login_required'.tr,
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

  Widget _buildBalanceCard() {
    final account = _ctrl.account.value;
    final balance = account?.balance ?? 0;
    final pending = account?.pending ?? 0;
    final lifetime = account?.lifetime ?? 0;
    final valueAed = account?.balanceValueAed ?? 0;
    final tier = account?.tier;
    final pointsFormat = NumberFormat('#,##0');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'loyalty_balance'.tr,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              if (tier != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tierColor(tier.color),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tier.badgeText.isNotEmpty ? tier.badgeText : tier.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            pointsFormat.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '= ${formatPriceForSelected(valueAed)}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.hourglass_empty, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${pointsFormat.format(pending)} '
                  '${'loyalty_pending'.tr} · ${'loyalty_pending_note'.tr}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${'loyalty_lifetime'.tr}: ${pointsFormat.format(lifetime)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    final settings = _ctrl.settings.value!;
    final rows = <String>[
      'loyalty_earn_rule'.trParams({
        'points': _fmtNum(settings.earnPointsPerAed),
        'name': _ctrl.pointsName,
      }),
      'loyalty_redeem_rule'.trParams({
        'points': _fmtNum(settings.redeemPointsPerAed),
        // The landed string is '@points points = @amount off', so the
        // amount must carry its currency: formatPriceForSelected(1).
        'amount': formatPriceForSelected(1),
      }),
      if (settings.minPointsToRedeem > 0)
        'loyalty_min_rule'.trParams({
          'points': '${settings.minPointsToRedeem}',
        }),
      if (settings.redeemStep > 0)
        'loyalty_step_rule'.trParams({
          'points': '${settings.redeemStep}',
        }),
      if (settings.maxRedeemPercentOfOrder > 0)
        'loyalty_cap_rule'.trParams({
          'percent': _fmtNum(settings.maxRedeemPercentOfOrder),
        }),
      if (settings.maxPointsPerOrder == 0) 'loyalty_no_cap'.tr,
    ];

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
            'loyalty_how_it_works'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: kPrimaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row,
                      style: const TextStyle(
                          fontSize: 13, color: kSecondaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'earn':
        return Icons.arrow_downward;
      case 'redeem':
        return Icons.arrow_upward;
      case 'adjust':
        return Icons.tune;
      case 'expire':
        return Icons.timer_off;
      default:
        return Icons.swap_horiz;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'earn':
        return 'loyalty_type_earn'.tr;
      case 'redeem':
        return 'loyalty_type_redeem'.tr;
      case 'adjust':
        return 'loyalty_type_adjust'.tr;
      case 'expire':
        return 'loyalty_type_expire'.tr;
      default:
        return type;
    }
  }

  Widget _statusChip(String status) {
    Color background;
    Color foreground;
    switch (status) {
      case 'pending':
        background = Colors.amber.shade100;
        foreground = Colors.amber.shade800;
        break;
      case 'confirmed':
        background = Colors.green.shade100;
        foreground = Colors.green.shade800;
        break;
      case 'used':
        background = Colors.blue.shade100;
        foreground = Colors.blue.shade800;
        break;
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
        'loyalty_status_$status'.tr,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(LoyaltyTransaction tx) {
    final isNegative =
        tx.type == 'redeem' || tx.type == 'expire' || tx.points < 0;
    final pointsFormat = NumberFormat('#,##0');
    final pointsText =
        '${isNegative ? '-' : '+'}${pointsFormat.format(tx.points.abs())}';
    final pointsColor = tx.points == 0
        ? Colors.grey
        : (isNegative ? kredColor : kdefgreenColor);

    final subtitleParts = <String>[];
    if (tx.createdAt != null) {
      subtitleParts.add(DateFormat.yMMMd().format(tx.createdAt!));
    }
    if (tx.expiresAt != null) {
      subtitleParts.add(
        'loyalty_expires_on'.trParams({
          'date': DateFormat.yMMMd().format(tx.expiresAt!),
        }),
      );
    }
    if (tx.amountAed > 0) {
      subtitleParts.add(formatPriceForSelected(tx.amountAed));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: defaultBoxShadow,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kPrimaryColor.withValues(alpha: 0.15),
          child: Icon(_typeIcon(tx.type), color: kPrimaryColor, size: 20),
        ),
        title: Text(
          tx.description.isNotEmpty ? tx.description : _typeLabel(tx.type),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: subtitleParts.isEmpty
            ? null
            : Text(
                subtitleParts.join(' · '),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              pointsText,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: pointsColor,
              ),
            ),
            const SizedBox(height: 4),
            _statusChip(tx.status),
          ],
        ),
      ),
    );
  }

  Widget _buildTerms() {
    final terms = _ctrl.settings.value?.programmeTerms ?? '';
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
