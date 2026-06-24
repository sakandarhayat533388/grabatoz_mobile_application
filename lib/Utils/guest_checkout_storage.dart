import 'package:shared_preferences/shared_preferences.dart';

Future<void> clearGuestCheckoutData() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove('Guest');
  await prefs.remove('guest_name');
  await prefs.remove('guest_email');
  await prefs.remove('guest_phone');
  await prefs.remove('guest_country_code');
  await prefs.remove('guest_address');
  await prefs.remove('guest_city');
  await prefs.remove('guest_state');
  await prefs.remove('guest_zip');
  await prefs.remove('guest_registered_email');
  await prefs.remove('guest_token');
  await prefs.remove('guestInfo');
  await prefs.remove('savedShippingAddress');
}
