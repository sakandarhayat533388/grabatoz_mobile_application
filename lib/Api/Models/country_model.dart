/// Country / currency model for `GET /api/countries/public`.
class Country {
  final String id;
  final String code;
  final String name;
  final String nameAr;
  final String currencyCode;
  final String currencySymbol;
  final String currencySymbolAr;
  final String flagSvg;
  final bool isDefault;
  final double effectiveRate;
  final int sortOrder;

  const Country({
    required this.id,
    required this.code,
    required this.name,
    required this.nameAr,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencySymbolAr,
    required this.flagSvg,
    required this.isDefault,
    required this.effectiveRate,
    required this.sortOrder,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      code: (json['code']?.toString() ?? 'AE').toUpperCase(),
      name: json['name']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? '',
      currencyCode: (json['currencyCode']?.toString() ?? 'AED').toUpperCase(),
      currencySymbol: json['currencySymbol']?.toString() ?? 'AED',
      currencySymbolAr: json['currencySymbolAr']?.toString() ?? '',
      flagSvg: json['flagSvg']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
      effectiveRate: (json['effectiveRate'] as num?)?.toDouble() ?? 1.0,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
