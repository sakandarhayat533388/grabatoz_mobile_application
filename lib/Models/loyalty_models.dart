import 'dart:math' as math;

// Tolerant converters: the backend does not always send consistent types
// (numbers arrive as int or double, ids as '_id' or 'id', etc.).

double _d(dynamic v, [double defaultValue = 0]) {
  if (v == null) return defaultValue;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim()) ?? defaultValue;
  return defaultValue;
}

int _i(dynamic v, [int defaultValue = 0]) {
  if (v == null) return defaultValue;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is num) return v.toInt();
  if (v is String) {
    final parsedInt = int.tryParse(v.trim());
    if (parsedInt != null) return parsedInt;
    final parsedDouble = double.tryParse(v.trim());
    if (parsedDouble != null) return parsedDouble.round();
    return defaultValue;
  }
  return defaultValue;
}

String _s(dynamic v, [String defaultValue = '']) {
  if (v == null) return defaultValue;
  if (v is String) return v;
  return v.toString();
}

bool _b(dynamic v, [bool defaultValue = false]) {
  if (v == null) return defaultValue;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final lower = v.trim().toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no' || lower == '') {
      return false;
    }
  }
  return defaultValue;
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is num) {
    // Seconds or milliseconds since epoch.
    final value = v.toInt();
    if (value > 100000000000) {
      return DateTime.tryParse(
        DateTime.fromMillisecondsSinceEpoch(value).toIso8601String(),
      );
    }
    if (value > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    return null;
  }
  if (v is String) {
    final trimmed = v.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }
  return null;
}

Map<String, dynamic>? _map(dynamic v) {
  if (v == null) return null;
  if (v is Map<String, dynamic>) return v;
  if (v is Map) {
    return v.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

String _id(dynamic json) {
  if (json is Map) {
    return _s(json['_id'] ?? json['id']);
  }
  return _s(json);
}

String _orderId(dynamic v) {
  if (v == null) return '';
  if (v is Map) return _s(v['_id'] ?? v['id']);
  return _s(v);
}

/// Parses the loyalty programme settings (nested `settings` in GET /api/loyalty/me and GET /api/loyalty/settings).
class LoyaltySettings {
  final bool isEnabled;
  final String pointsName;
  final String pointsNameAr;
  final String pointsNameSingular;
  final double earnPointsPerAed;
  final double redeemPointsPerAed;
  final int minPointsToRedeem;
  final double maxRedeemPercentOfOrder;
  final int maxPointsPerOrder;
  final int redeemStep;
  final bool showOnProductPage;
  final bool showOnCart;
  final String programmeTerms;

  const LoyaltySettings({
    this.isEnabled = false,
    this.pointsName = '',
    this.pointsNameAr = '',
    this.pointsNameSingular = '',
    this.earnPointsPerAed = 0,
    this.redeemPointsPerAed = 1000,
    this.minPointsToRedeem = 0,
    this.maxRedeemPercentOfOrder = 0,
    this.maxPointsPerOrder = 0,
    this.redeemStep = 1,
    this.showOnProductPage = false,
    this.showOnCart = false,
    this.programmeTerms = '',
  });

  factory LoyaltySettings.fromJson(Map<String, dynamic> json) {
    final redeemPoints = _d(json['redeemPointsPerAed'], 1000);
    return LoyaltySettings(
      isEnabled: _b(json['isEnabled'] ?? json['enabled']),
      pointsName: _s(json['pointsName']),
      pointsNameAr: _s(json['pointsNameAr']),
      pointsNameSingular: _s(json['pointsNameSingular']),
      earnPointsPerAed: _d(json['earnPointsPerAed']),
      // Guard divide-by-zero downstream: never store 0 here.
      redeemPointsPerAed: redeemPoints == 0 ? 1000 : redeemPoints,
      minPointsToRedeem: _i(json['minPointsToRedeem']),
      maxRedeemPercentOfOrder: _d(json['maxRedeemPercentOfOrder']),
      maxPointsPerOrder: _i(json['maxPointsPerOrder']),
      // Never 0 — a step of 0 would break redemption steppers.
      redeemStep: math.max(1, _i(json['redeemStep'], 1)),
      showOnProductPage: _b(json['showOnProductPage']),
      showOnCart: _b(json['showOnCart']),
      programmeTerms: _s(json['programmeTerms'] ?? json['terms']),
    );
  }
}

/// Parses a loyalty tier object (the `tier` object in GET /api/loyalty/me).
class LoyaltyTier {
  final String id;
  final String name;
  final String color;
  final String badgeText;
  final double earnMultiplier;

  const LoyaltyTier({
    this.id = '',
    this.name = '',
    this.color = '',
    this.badgeText = '',
    this.earnMultiplier = 1,
  });

  factory LoyaltyTier.fromJson(Map<String, dynamic> json) {
    return LoyaltyTier(
      id: _id(json),
      name: _s(json['name']),
      color: _s(json['color']),
      badgeText: _s(json['badgeText']),
      earnMultiplier: _d(json['earnMultiplier'], 1),
    );
  }
}

/// Parses a single loyalty transaction (items in GET /api/loyalty/me transactions and GET /api/loyalty/announcements).
class LoyaltyTransaction {
  final String id;
  final String type;
  final String status;
  final String description;
  final String orderId;
  final int points;
  final double amountAed;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const LoyaltyTransaction({
    this.id = '',
    this.type = '',
    this.status = '',
    this.description = '',
    this.orderId = '',
    this.points = 0,
    this.amountAed = 0,
    this.expiresAt,
    this.createdAt,
  });

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: _id(json),
      type: _s(json['type']),
      status: _s(json['status']),
      description: _s(json['description']),
      orderId: _orderId(json['order'] ?? json['orderId']),
      points: _i(json['points']),
      amountAed: _d(json['amountAed'] ?? json['amount']),
      expiresAt: _date(json['expiresAt']),
      createdAt: _date(json['createdAt']),
    );
  }
}

/// Parses the full loyalty account payload from GET /api/loyalty/me.
class LoyaltyAccount {
  final int balance;
  final int pending;
  final int lifetime;
  final double balanceValueAed;
  final bool canRedeem;
  final LoyaltyTier? tier;
  final LoyaltySettings settings;
  final List<LoyaltyTransaction> transactions;
  final int page;
  final int limit;
  final int totalCount;
  final bool hasMore;

  const LoyaltyAccount({
    this.balance = 0,
    this.pending = 0,
    this.lifetime = 0,
    this.balanceValueAed = 0,
    this.canRedeem = false,
    this.tier,
    required this.settings,
    this.transactions = const [],
    this.page = 1,
    this.limit = 0,
    this.totalCount = 0,
    this.hasMore = false,
  });

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) {
    final tierMap = _map(json['tier']);
    final settingsMap = _map(json['settings']);
    final rawTransactions = json['transactions'];

    return LoyaltyAccount(
      balance: _i(json['balance']),
      pending: _i(json['pending']),
      lifetime: _i(json['lifetime']),
      balanceValueAed: _d(json['balanceValueAed']),
      canRedeem: _b(json['canRedeem']),
      tier: tierMap == null ? null : LoyaltyTier.fromJson(tierMap),
      settings: settingsMap == null
          ? const LoyaltySettings()
          : LoyaltySettings.fromJson(settingsMap),
      transactions: rawTransactions is List
          ? rawTransactions
                .map((e) => _map(e))
                .where((e) => e != null)
                .map((e) => LoyaltyTransaction.fromJson(e!))
                .toList()
          : const [],
      page: _i(json['page'], 1),
      limit: _i(json['limit']),
      totalCount: _i(json['totalCount']),
      hasMore: _b(json['hasMore']),
    );
  }
}

/// Parses a redemption quote from POST /api/loyalty/quote (points → AED discount for a cart/order amount).
class LoyaltyQuote {
  final int maxPoints;
  final int points;
  final int balance;
  final int pending;
  final double redeemPointsPerAed;
  final int minPointsToRedeem;
  final int redeemStep;
  final double discountAed;
  final String pointsName;

  const LoyaltyQuote({
    this.maxPoints = 0,
    this.points = 0,
    this.balance = 0,
    this.pending = 0,
    this.redeemPointsPerAed = 1000,
    this.minPointsToRedeem = 0,
    this.redeemStep = 1,
    this.discountAed = 0,
    this.pointsName = '',
  });

  factory LoyaltyQuote.fromJson(Map<String, dynamic> json) {
    final redeemPoints = _d(json['redeemPointsPerAed'], 1000);
    return LoyaltyQuote(
      maxPoints: _i(json['maxPoints']),
      points: _i(json['points']),
      balance: _i(json['balance']),
      pending: _i(json['pending']),
      redeemPointsPerAed: redeemPoints == 0 ? 1000 : redeemPoints,
      minPointsToRedeem: _i(json['minPointsToRedeem']),
      redeemStep: math.max(1, _i(json['redeemStep'], 1)),
      discountAed: _d(json['discountAed']),
      pointsName: _s(json['pointsName']),
    );
  }
}

/// Parses pending/expiring points announcements from GET /api/loyalty/announcements.
class LoyaltyAnnouncements {
  final int totalPoints;
  final int count;
  final List<LoyaltyTransaction> items;

  const LoyaltyAnnouncements({
    this.totalPoints = 0,
    this.count = 0,
    this.items = const [],
  });

  bool get hasAny => totalPoints > 0 || items.isNotEmpty;

  factory LoyaltyAnnouncements.fromJson(Map<String, dynamic> json) {
    final rawItems =
        json['transactions'] ?? json['items'] ?? json['announcements'];
    final items = rawItems is List
        ? rawItems
              .map((e) => _map(e))
              .where((e) => e != null)
              .map((e) => LoyaltyTransaction.fromJson(e!))
              .toList()
        : <LoyaltyTransaction>[];

    return LoyaltyAnnouncements(
      totalPoints: _i(json['totalPoints'] ?? json['points']),
      count: json['count'] == null ? items.length : _i(json['count']),
      items: items,
    );
  }
}
