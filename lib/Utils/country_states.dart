import 'package:get/get.dart';
import 'package:graba2z/Controllers/country_controller.dart';

/// Country -> provinces/states used by the address forms.
///
/// Mirrors the website's `client/src/utils/countryStates.js` (same country
/// keys, same province names, same order) so an address entered in the app
/// uses exactly the values the website offers and the backend expects.
/// There is no states API — the website hardcodes this map, and so do we.
const Map<String, List<String>> countryProvinces = {
  'AE': [
    'Abu Dhabi',
    'Ajman',
    'Al Ain',
    'Dubai',
    'Fujairah',
    'Ras Al Khaimah',
    'Sharjah',
    'Umm Al Quwain',
  ],
  'SA': [
    'Riyadh Region',
    'Makkah Region (Jeddah, Makkah)',
    'Madinah Region',
    'Eastern Province (Dammam, Khobar, Dhahran)',
    'Al Qassim Region',
    'Asir Region',
    'Tabuk Region',
    'Hail Region',
    'Northern Borders Region',
    'Jazan Region',
    'Najran Region',
    'Al Baha Region',
    'Al Jawf Region',
  ],
  'QA': [
    'Doha',
    'Al Rayyan',
    'Al Wakrah',
    'Al Khor',
    'Al Daayen',
    'Umm Salal',
    'Al Shamal',
    'Shahaniya',
  ],
  'OM': [
    'Muscat Governorate',
    'Dhofar Governorate',
    'Musandam Governorate',
    'Al Buraimi Governorate',
    'Ad Dakhiliyah Governorate',
    'Al Batinah North Governorate',
    'Al Batinah South Governorate',
    'Ash Sharqiyah North Governorate',
    'Ash Sharqiyah South Governorate',
    'Ad Dhahirah Governorate',
    'Al Wusta Governorate',
  ],
  'KW': [
    'Al Asimah (Kuwait City)',
    'Hawalli Governorate',
    'Farwaniya Governorate',
    'Mubarak Al-Kabeer Governorate',
    'Ahmadi Governorate',
    'Jahra Governorate',
  ],
  'BH': [
    'Capital Governorate (Manama)',
    'Muharraq Governorate',
    'Northern Governorate',
    'Southern Governorate',
  ],
  'EG': [
    'Cairo',
    'Giza',
    'Alexandria',
    'Qalyubia',
    'Sharqia',
    'Gharbia',
    'Monufia',
    'Beheira',
    'Dakahlia',
    'Damietta',
    'Port Said',
    'Ismailia',
    'Suez',
    'Red Sea',
    'Fayoum',
    'Beni Suef',
    'Minya',
    'Asyut',
    'Sohag',
    'Qena',
    'Luxor',
    'Aswan',
    'Matrouh',
    'North Sinai',
    'South Sinai',
    'New Valley',
  ],
  'JO': [
    'Amman',
    'Zarqa',
    'Irbid',
    'Aqaba',
    'Balqa',
    'Madaba',
    'Jerash',
    'Ajloun',
    'Mafraq',
    'Karak',
    'Tafilah',
    "Ma'an",
  ],
  'TR': [
    'Istanbul',
    'Ankara',
    'Izmir',
    'Bursa',
    'Antalya',
    'Adana',
    'Konya',
    'Gaziantep',
    'Kocaeli',
    'Mersin',
    'Mugla',
    'Trabzon',
  ],
  'GB': [
    'Greater London',
    'England',
    'Scotland',
    'Wales',
    'Northern Ireland',
  ],
  'US': [
    'California',
    'Texas',
    'Florida',
    'New York',
    'Illinois',
    'Pennsylvania',
    'Ohio',
    'Georgia',
    'North Carolina',
    'Washington',
  ],
  'IN': [
    'Maharashtra',
    'Delhi',
    'Karnataka',
    'Tamil Nadu',
    'Telangana',
    'Gujarat',
    'Uttar Pradesh',
    'West Bengal',
    'Punjab',
    'Kerala',
  ],
  'PK': [
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Islamabad Capital Territory',
    'Azad Kashmir',
    'Gilgit-Baltistan',
  ],
};

/// English country name per code — the value stored on saved addresses
/// (the backend's own default is the name form 'UAE', and the website's
/// normalizer below accepts names as well as codes).
const Map<String, String> countryNames = {
  'AE': 'UAE',
  'SA': 'Saudi Arabia',
  'QA': 'Qatar',
  'OM': 'Oman',
  'KW': 'Kuwait',
  'BH': 'Bahrain',
  'EG': 'Egypt',
  'JO': 'Jordan',
  'TR': 'Turkey',
  'GB': 'United Kingdom',
  'US': 'United States',
  'IN': 'India',
  'PK': 'Pakistan',
};

/// Provinces for a country given as a code ('SA') or a name
/// ('Saudi Arabia', 'UAE', ...). Port of the website's
/// getProvincesForCountry: empty input returns the AE list; an unknown
/// non-empty input returns null.
List<String>? provincesForCountry(String? countryNameOrCode) {
  if (countryNameOrCode == null || countryNameOrCode.trim().isEmpty) {
    return countryProvinces['AE'];
  }
  final clean = countryNameOrCode.trim().toUpperCase();

  // Match by code first.
  if (countryProvinces.containsKey(clean)) {
    return countryProvinces[clean];
  }

  // Match by name, in the website's order.
  if (clean.contains('EMIRATES') ||
      clean.contains('UAE') ||
      clean == 'UNITED ARAB EMIRATES') {
    return countryProvinces['AE'];
  }
  if (clean.contains('SAUDI') ||
      clean.contains('KSA') ||
      clean == 'SAUDI ARABIA') {
    return countryProvinces['SA'];
  }
  if (clean.contains('QATAR')) return countryProvinces['QA'];
  if (clean.contains('OMAN')) return countryProvinces['OM'];
  if (clean.contains('KUWAIT')) return countryProvinces['KW'];
  if (clean.contains('BAHRAIN')) return countryProvinces['BH'];
  if (clean.contains('EGYPT')) return countryProvinces['EG'];
  if (clean.contains('JORDAN')) return countryProvinces['JO'];
  if (clean.contains('TURKEY') || clean.contains('TÜRKIYE')) {
    return countryProvinces['TR'];
  }
  if (clean.contains('KINGDOM') ||
      clean.contains('UK') ||
      clean == 'UNITED KINGDOM') {
    return countryProvinces['GB'];
  }
  if (clean.contains('STATES') ||
      clean.contains('USA') ||
      clean == 'UNITED STATES') {
    return countryProvinces['US'];
  }
  if (clean.contains('INDIA')) return countryProvinces['IN'];
  if (clean.contains('PAKISTAN')) return countryProvinces['PK'];

  return null;
}

/// Resolve any stored country value (code or name) to its code.
/// Falls back to 'AE' — the backend's default country.
String countryCodeFor(String? countryNameOrCode) {
  if (countryNameOrCode == null || countryNameOrCode.trim().isEmpty) {
    return 'AE';
  }
  final clean = countryNameOrCode.trim().toUpperCase();
  if (countryProvinces.containsKey(clean)) return clean;
  final list = provincesForCountry(countryNameOrCode);
  if (list == null) return 'AE';
  for (final entry in countryProvinces.entries) {
    if (identical(entry.value, list)) return entry.key;
  }
  return 'AE';
}

/// English name stored on an address for the given code.
String countryNameForCode(String code) =>
    countryNames[code.toUpperCase()] ?? code.toUpperCase();

/// One selectable country in an address form.
class AddressCountryOption {
  final String code;
  final String name;
  final String nameAr;

  const AddressCountryOption({
    required this.code,
    required this.name,
    required this.nameAr,
  });

  String get displayName =>
      (Get.locale?.languageCode == 'ar' && nameAr.isNotEmpty) ? nameAr : name;
}

/// Countries offered in address forms: the shop's enabled countries from
/// the countries API when loaded, otherwise the six GCC countries the
/// backend supports.
List<AddressCountryOption> addressCountryOptions() {
  if (Get.isRegistered<CountryController>()) {
    final countries = Get.find<CountryController>().countries;
    if (countries.isNotEmpty) {
      return countries
          .map((c) => AddressCountryOption(
                code: c.code.toUpperCase(),
                name: c.name,
                nameAr: c.nameAr,
              ))
          .toList();
    }
  }
  return const [
    AddressCountryOption(code: 'AE', name: 'UAE', nameAr: 'الإمارات'),
    AddressCountryOption(code: 'SA', name: 'Saudi Arabia', nameAr: 'السعودية'),
    AddressCountryOption(code: 'QA', name: 'Qatar', nameAr: 'قطر'),
    AddressCountryOption(code: 'OM', name: 'Oman', nameAr: 'عُمان'),
    AddressCountryOption(code: 'BH', name: 'Bahrain', nameAr: 'البحرين'),
    AddressCountryOption(code: 'KW', name: 'Kuwait', nameAr: 'الكويت'),
  ];
}

/// Country preselected for a NEW address: the country the shopper is
/// browsing with (CountryController selection), else 'AE'.
String defaultAddressCountryCode() {
  if (Get.isRegistered<CountryController>()) {
    return Get.find<CountryController>().countryCode.toUpperCase();
  }
  return 'AE';
}
