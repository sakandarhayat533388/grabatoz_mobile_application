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

String? _sOrNull(dynamic v) {
  if (v == null) return null;
  final value = _s(v);
  return value.isEmpty ? null : value;
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
    final value = v.toInt();
    if (value > 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value);
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

/// Parses a single referral offer (the `referee` / `referrer` objects in the referral `offer`, and the `offer` in POST /api/referrals/validate).
class ReferralOffer {
  final String discountType;
  final double discountValue;
  final double maxDiscountAed;
  final double minOrderAed;
  final bool firstOrderOnly;

  const ReferralOffer({
    this.discountType = 'percentage',
    this.discountValue = 0,
    this.maxDiscountAed = 0,
    this.minOrderAed = 0,
    this.firstOrderOnly = false,
  });

  // Note: 0 in maxDiscountAed / minOrderAed means NO limit on the backend —
  // the raw values are stored as-is, with no transformation.
  factory ReferralOffer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReferralOffer();
    return ReferralOffer(
      discountType: _s(json['discountType'], 'percentage').isEmpty
          ? 'percentage'
          : _s(json['discountType'], 'percentage'),
      discountValue: _d(json['discountValue'] ?? json['value']),
      maxDiscountAed: _d(json['maxDiscountAed'] ?? json['maxDiscount']),
      minOrderAed: _d(json['minOrderAed'] ?? json['minOrder']),
      firstOrderOnly: _b(json['firstOrderOnly']),
    );
  }
}

/// Parses the referral programme settings (nested `settings` + `offer` in GET /api/referrals/me).
class ReferralSettings {
  final bool isEnabled;
  final bool showInProfile;
  final String programmeName;
  final String programmeNameAr;
  final String shareMessage;
  final String programmeTerms;
  final String qualifyOnOrderStatus;
  final String refereeDiscountType;
  final String referrerDiscountType;
  final double refereeDiscountValue;
  final double refereeMaxDiscountAed;
  final double refereeMinOrderAed;
  final double referrerDiscountValue;
  final double referrerMaxDiscountAed;
  final double referrerMinOrderAed;
  final double qualifyMinOrderAed;
  final bool refereeFirstOrderOnly;
  final ReferralOffer? offerReferee;
  final ReferralOffer? offerReferrer;

  const ReferralSettings({
    this.isEnabled = false,
    this.showInProfile = false,
    this.programmeName = '',
    this.programmeNameAr = '',
    this.shareMessage = '',
    this.programmeTerms = '',
    this.qualifyOnOrderStatus = '',
    this.refereeDiscountType = '',
    this.referrerDiscountType = '',
    this.refereeDiscountValue = 0,
    this.refereeMaxDiscountAed = 0,
    this.refereeMinOrderAed = 0,
    this.referrerDiscountValue = 0,
    this.referrerMaxDiscountAed = 0,
    this.referrerMinOrderAed = 0,
    this.qualifyMinOrderAed = 0,
    this.refereeFirstOrderOnly = false,
    this.offerReferee,
    this.offerReferrer,
  });

  factory ReferralSettings.fromJson(
    Map<String, dynamic> settings,
    Map<String, dynamic>? offer,
  ) {
    // The offer may be passed in, or nested inside the settings map itself.
    final effectiveOffer = offer ?? _map(settings['offer']);
    final refereeOfferMap = _map(effectiveOffer?['referee']);
    final referrerOfferMap = _map(effectiveOffer?['referrer']);
    final offerReferee = refereeOfferMap == null
        ? null
        : ReferralOffer.fromJson(refereeOfferMap);
    final offerReferrer = referrerOfferMap == null
        ? null
        : ReferralOffer.fromJson(referrerOfferMap);

    return ReferralSettings(
      isEnabled: _b(settings['isEnabled'] ?? settings['enabled']),
      showInProfile: _b(settings['showInProfile']),
      programmeName: _s(settings['programmeName']),
      programmeNameAr: _s(settings['programmeNameAr']),
      shareMessage: _s(settings['shareMessage']),
      programmeTerms: _s(settings['programmeTerms'] ?? settings['terms']),
      qualifyOnOrderStatus: _s(settings['qualifyOnOrderStatus']),
      refereeDiscountType: _s(
        settings['refereeDiscountType'] ?? offerReferee?.discountType,
      ),
      referrerDiscountType: _s(
        settings['referrerDiscountType'] ?? offerReferrer?.discountType,
      ),
      refereeDiscountValue: _d(
        settings['refereeDiscountValue'] ?? offerReferee?.discountValue,
      ),
      refereeMaxDiscountAed: _d(
        settings['refereeMaxDiscountAed'] ?? offerReferee?.maxDiscountAed,
      ),
      refereeMinOrderAed: _d(
        settings['refereeMinOrderAed'] ?? offerReferee?.minOrderAed,
      ),
      referrerDiscountValue: _d(
        settings['referrerDiscountValue'] ?? offerReferrer?.discountValue,
      ),
      referrerMaxDiscountAed: _d(
        settings['referrerMaxDiscountAed'] ?? offerReferrer?.maxDiscountAed,
      ),
      referrerMinOrderAed: _d(
        settings['referrerMinOrderAed'] ?? offerReferrer?.minOrderAed,
      ),
      qualifyMinOrderAed: _d(settings['qualifyMinOrderAed']),
      refereeFirstOrderOnly: settings['refereeFirstOrderOnly'] == null
          ? (offerReferee?.firstOrderOnly ?? false)
          : _b(settings['refereeFirstOrderOnly']),
      offerReferee: offerReferee,
      offerReferrer: offerReferrer,
    );
  }

  /// Convenience factory for the full GET /api/referrals/me payload shape:
  /// pulls `settings` and `offer` out of the top-level map.
  factory ReferralSettings.fromPayload(Map<dynamic, dynamic> payload) {
    final settingsMap = _map(payload['settings']) ?? <String, dynamic>{};
    final offerMap = _map(payload['offer']);
    return ReferralSettings.fromJson(settingsMap, offerMap);
  }
}

/// Parses a single referral invite (items in the `invites` list of GET /api/referrals/me).
class ReferralInvite {
  final String id;
  final String name;
  final String email;
  final String status;
  final String notRewardedReason;
  final bool rewarded;
  final DateTime? joinedAt;
  final DateTime? qualifiedAt;

  const ReferralInvite({
    this.id = '',
    this.name = '',
    this.email = '',
    this.status = '',
    this.notRewardedReason = '',
    this.rewarded = false,
    this.joinedAt,
    this.qualifiedAt,
  });

  factory ReferralInvite.fromJson(Map<String, dynamic> json) {
    return ReferralInvite(
      id: _id(json),
      // name / email are server-masked — stored as-is.
      name: _s(json['name']),
      email: _s(json['email']),
      status: _s(json['status']),
      notRewardedReason: _s(json['notRewardedReason']),
      rewarded: _b(json['rewarded']),
      joinedAt: _date(json['joinedAt'] ?? json['createdAt']),
      qualifiedAt: _date(json['qualifiedAt']),
    );
  }
}

/// Parses a single referral reward / coupon (items in the `rewards` list of GET /api/referrals/me and POST /api/referrals/quote).
class ReferralReward {
  final String id;
  final String role;
  final String code;
  final String referralTypeName;
  final String discountType;
  final String status;
  final String description;
  final double discountValue;
  final double maxDiscountAed;
  final double minOrderAed;
  final double discountAppliedAed;
  final double quoteDiscountAed;
  final bool firstOrderOnly;
  final DateTime? expiresAt;
  final DateTime? usedAt;

  const ReferralReward({
    this.id = '',
    this.role = '',
    this.code = '',
    this.referralTypeName = '',
    this.discountType = '',
    this.status = '',
    this.description = '',
    this.discountValue = 0,
    this.maxDiscountAed = 0,
    this.minOrderAed = 0,
    this.discountAppliedAed = 0,
    this.quoteDiscountAed = 0,
    this.firstOrderOnly = false,
    this.expiresAt,
    this.usedAt,
  });

  bool get isActive => status == 'active';

  factory ReferralReward.fromJson(Map<String, dynamic> json) {
    final discountApplied = _d(
      json['discountAppliedAed'] ?? json['discountApplied'],
    );
    return ReferralReward(
      id: _id(json),
      role: _s(json['role']),
      code: _s(json['code']),
      referralTypeName: _s(json['referralTypeName'] ?? json['typeName']),
      discountType: _s(json['discountType']),
      status: _s(json['status']),
      description: _s(json['description']),
      discountValue: _d(json['discountValue'] ?? json['value']),
      maxDiscountAed: _d(json['maxDiscountAed'] ?? json['maxDiscount']),
      minOrderAed: _d(json['minOrderAed'] ?? json['minOrder']),
      discountAppliedAed: discountApplied,
      quoteDiscountAed: _d(
        json['discountAed'] ?? json['discount'] ?? discountApplied,
      ),
      firstOrderOnly: _b(json['firstOrderOnly']),
      expiresAt: _date(json['expiresAt']),
      usedAt: _date(json['usedAt']),
    );
  }
}

/// Parses referral programme statistics (the `stats` object in GET /api/referrals/me).
class ReferralStats {
  final int total;
  final int pending;
  final int qualified;
  final int cancelled;
  final int activeRewards;
  final double totalEarnedAed;

  const ReferralStats({
    this.total = 0,
    this.pending = 0,
    this.qualified = 0,
    this.cancelled = 0,
    this.activeRewards = 0,
    this.totalEarnedAed = 0,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      total: _i(json['total']),
      pending: _i(json['pending']),
      qualified: _i(json['qualified']),
      cancelled: _i(json['cancelled']),
      activeRewards: _i(json['activeRewards']),
      totalEarnedAed: _d(json['totalEarnedAed'] ?? json['totalEarned']),
    );
  }
}

/// Parses the full referral panel payload from GET /api/referrals/me.
class ReferralPanel {
  final String? code;
  final String link;
  final List<ReferralInvite> invites;
  final List<ReferralReward> rewards;
  final ReferralStats? stats;
  final ReferralSettings settings;
  final ReferralOffer? offerReferee;
  final ReferralOffer? offerReferrer;

  const ReferralPanel({
    this.code,
    this.link = '',
    this.invites = const [],
    this.rewards = const [],
    this.stats,
    required this.settings,
    this.offerReferee,
    this.offerReferrer,
  });

  factory ReferralPanel.fromJson(Map<String, dynamic> json) {
    final settingsMap = _map(json['settings']) ?? <String, dynamic>{};
    final panelOffer = _map(json['offer']);
    // When the panel-level offer is missing, ReferralSettings.fromJson
    // falls back to any offer nested inside the settings map.
    final settings = ReferralSettings.fromJson(settingsMap, panelOffer);

    final statsMap = _map(json['stats']);
    final rawInvites = json['invites'];
    final rawRewards = json['rewards'];

    return ReferralPanel(
      code: _sOrNull(json['code']),
      link: _s(json['link']),
      invites: rawInvites is List
          ? rawInvites
                .map((e) => _map(e))
                .where((e) => e != null)
                .map((e) => ReferralInvite.fromJson(e!))
                .toList()
          : const [],
      rewards: rawRewards is List
          ? rawRewards
                .map((e) => _map(e))
                .where((e) => e != null)
                .map((e) => ReferralReward.fromJson(e!))
                .toList()
          : const [],
      // Must stay null when the backend sends stats: null (programme off).
      stats: statsMap == null ? null : ReferralStats.fromJson(statsMap),
      settings: settings,
      offerReferee: settings.offerReferee,
      offerReferrer: settings.offerReferrer,
    );
  }
}

/// Parses a referral discount quote from POST /api/referrals/quote.
class ReferralQuote {
  final List<ReferralReward> rewards;
  final ReferralReward? best;

  const ReferralQuote({this.rewards = const [], this.best});

  factory ReferralQuote.fromJson(Map<String, dynamic> json) {
    final rawRewards = json['rewards'];
    final bestMap = _map(json['best']);
    return ReferralQuote(
      rewards: rawRewards is List
          ? rawRewards
                .map((e) => _map(e))
                .where((e) => e != null)
                .map((e) => ReferralReward.fromJson(e!))
                .toList()
          : const [],
      best: bestMap == null ? null : ReferralReward.fromJson(bestMap),
    );
  }
}

/// Parses a referral code validation result from POST /api/referrals/validate (HTTP 200 even when valid is false).
class ReferralValidation {
  final bool valid;
  final String reason;
  final String? firstName;
  final ReferralOffer? offer;

  const ReferralValidation({
    this.valid = false,
    this.reason = '',
    this.firstName,
    this.offer,
  });

  factory ReferralValidation.fromJson(Map<String, dynamic> json) {
    final offerMap = _map(json['offer']);
    return ReferralValidation(
      valid: _b(json['valid']),
      reason: _s(json['reason']),
      firstName: _sOrNull(json['firstName']),
      offer: offerMap == null ? null : ReferralOffer.fromJson(offerMap),
    );
  }
}
