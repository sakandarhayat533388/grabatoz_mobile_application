class PopupSettingsModel {
  final String id;
  final String name;
  final bool isEnabled;
  final List<String> showOnPages;
  final List<String> platforms;
  final String showLimit;
  final String? leftImageUrl;
  final String? mobileImageUrl;
  final String? sectionTitle;
  final String? feature1Label;
  final String? feature2Label;
  final String? feature3Label;
  final String? discountTopText;
  final String? discountValue;
  final String? discountBottomText;
  final String? discountNote;
  final String? googlePlayLink;
  final String? appStoreLink;
  final String? continueButtonText;
  final String? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  PopupSettingsModel({
    required this.id,
    required this.name,
    required this.isEnabled,
    required this.showOnPages,
    required this.platforms,
    required this.showLimit,
    this.leftImageUrl,
    this.mobileImageUrl,
    this.sectionTitle,
    this.feature1Label,
    this.feature2Label,
    this.feature3Label,
    this.discountTopText,
    this.discountValue,
    this.discountBottomText,
    this.discountNote,
    this.googlePlayLink,
    this.appStoreLink,
    this.continueButtonText,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory PopupSettingsModel.fromJson(Map<String, dynamic> json) {
    return PopupSettingsModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      isEnabled: json['isEnabled'] ?? false,
      showOnPages: List<String>.from(json['showOnPages'] ?? []),
      platforms: List<String>.from(json['platforms'] ?? []),
      showLimit: json['showLimit'] ?? 'once',
      leftImageUrl: json['leftImageUrl'],
      mobileImageUrl: json['mobileImageUrl'],
      sectionTitle: json['sectionTitle'],
      feature1Label: json['feature1Label'],
      feature2Label: json['feature2Label'],
      feature3Label: json['feature3Label'],
      discountTopText: json['discountTopText'],
      discountValue: json['discountValue'],
      discountBottomText: json['discountBottomText'],
      discountNote: json['discountNote'],
      googlePlayLink: json['googlePlayLink'],
      appStoreLink: json['appStoreLink'],
      continueButtonText: json['continueButtonText'],
      updatedBy: json['updatedBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}
