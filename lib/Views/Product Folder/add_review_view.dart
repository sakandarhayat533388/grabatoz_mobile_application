import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:get/get.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Controllers/review_controller.dart';
import 'package:graba2z/Utils/packages.dart';
import 'package:graba2z/Views/Auth/login_bottom_view.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WriteReviewScreen extends StatefulWidget {
  final String productId;

  const WriteReviewScreen({super.key, required this.productId});

  @override
  _WriteReviewScreenState createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  double _rating = 5.0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // added
  bool _submitting = false;
  // Guest verification state
  bool _awaitingVerification = false;
  String? _verificationId;
  String? _guestEmail;
  final TextEditingController _codeController = TextEditingController();
  bool _verifying = false;
  int _resendCooldown = 0;
  Timer? _resendTimer;

  bool get _loggedIn {
    try {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        return auth.userID.value.isNotEmpty;
      }
    } catch (_) {}
    return false;
  }

  Future<String?> _getAuthToken() async {
    // Try common sources for token
    try {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        // Try a few likely fields without crashing if null
        final dynamic t1 = (auth as dynamic).token;
        if (t1 is RxString && t1.value.isNotEmpty) return t1.value;
        if (t1 is String && t1.isNotEmpty) return t1;
        final dynamic t2 = (auth as dynamic).userToken;
        if (t2 is RxString && t2.value.isNotEmpty) return t2.value;
        if (t2 is String && t2.isNotEmpty) return t2;
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in ['token', 'authToken', 'accessToken']) {
        final v = prefs.getString(key);
        if (v != null && v.isNotEmpty) return v;
      }
    } catch (_) {}
    return null;
  }

  bool _isValidEmail(String email) {
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(email);
  }

  // Center popup like "Added to cart" (overlay-based, auto-dismiss)
  void _showCenterPopup(String message, {IconData icon = Icons.rate_review}) {
    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: Builder(
              builder: (context) {
                final double maxW = (MediaQuery.of(context).size.width * 0.8).clamp(220.0, 360.0);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: SizedBox(
                    width: maxW,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(icon, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (entry.mounted) entry.remove();
    });
  }

  void _startResendTimer([int seconds = 60]) {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCooldown = (_resendCooldown - 1).clamp(0, seconds);
        if (_resendCooldown == 0) t.cancel();
      });
    });
  }

  Future<void> _verifyCode() async {
    if (_verifying) return;
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showCenterPopup('product_review_enter_code'.tr, icon: Icons.info);
      return;
    }
    if (_verificationId == null) {
      _showCenterPopup('product_review_verification_not_initialized'.tr, icon: Icons.error);
      return;
    }
    setState(() => _verifying = true);
    try {
      final uri = Uri.parse(Configss.verifyReviewEmail);
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'verificationId': _verificationId, 'code': code}),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        _showCenterPopup('product_review_verified_success'.tr, icon: Icons.check_circle);
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) Navigator.pop(context, true);
      } else {
        String msg = 'product_review_invalid_code'.tr;
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] is String) msg = body['message'];
        } catch (_) {}
        _showCenterPopup(msg, icon: Icons.error);
      }
    } catch (_) {
      _showCenterPopup('product_review_verification_failed'.tr, icon: Icons.error);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resendVerification() async {
    if (_resendCooldown > 0 || _verificationId == null) return;
    try {
      final uri = Uri.parse(Configss.resendReviewVerification);
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'verificationId': _verificationId}),
      );
      if (res.statusCode == 200) {
        _showCenterPopup('product_review_code_resent'.tr, icon: Icons.check_circle);
        _startResendTimer(60);
      } else {
        _showCenterPopup('product_review_resend_failed'.tr, icon: Icons.error);
      }
    } catch (_) {
      _showCenterPopup('product_review_resend_failed'.tr, icon: Icons.error);
    }
  }

  Future<void> _submitReview() async {
    if (_submitting) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final comment = _reviewController.text.trim();
    final int ratingInt = _rating.round();

    if (ratingInt <= 0 || comment.isEmpty) {
      _showCenterPopup('product_review_rating_comment_required'.tr, icon: Icons.info);
      return;
    }
    // Guests must provide name and valid email
    if (!_loggedIn) {
      if (name.isEmpty || email.isEmpty) {
        _showCenterPopup('product_review_name_email_required'.tr, icon: Icons.info);
        return;
      }
      if (!_isValidEmail(email)) {
        _showCenterPopup('product_review_invalid_email'.tr, icon: Icons.info);
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final endpoint = Configss.postReview;
      final uri = Uri.parse(endpoint);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      // Attach token if logged-in
      if (_loggedIn) {
        final token = await _getAuthToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      final payload = <String, dynamic>{
        'productId': widget.productId,
        'rating': ratingInt,
        'comment': comment,
      };
      if (!_loggedIn) {
        payload['name'] = name;
        payload['email'] = email;
      }

      final res = await http.post(uri, headers: headers, body: jsonEncode(payload));

      if (res.statusCode == 201 || res.statusCode == 200) {
        // Parse for guest verification path
        Map<String, dynamic> body = {};
        try {
          body = json.decode(res.body) as Map<String, dynamic>;
        } catch (_) {}
        final bool requiresVerification = (body['requiresVerification'] == true) && !_loggedIn;
        final String? verificationId = body['verificationId']?.toString();

        if (requiresVerification && verificationId != null && verificationId.isNotEmpty) {
          // Removed popup "Code sent to ..."
          setState(() {
            _verificationId = verificationId;
            _awaitingVerification = true;
            _guestEmail = email;
          });
          _startResendTimer(60);
        } else {
          // Authenticated or immediate success
          _showCenterPopup('product_review_submitted'.tr, icon: Icons.check_circle);
          await Future.delayed(const Duration(milliseconds: 900));
          if (mounted) Navigator.pop(context, true);
        }
      } else {
        String msg = 'product_review_submit_failed'.tr;
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] is String) {
            msg = body['message'];
          }
        } catch (_) {}
        _showCenterPopup(msg, icon: Icons.error);
      }
    } catch (e) {
      _showCenterPopup('product_review_submit_failed'.tr, icon: Icons.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _cancelReview() {
    _nameController.clear();
    _reviewController.clear();
    Get.back();
    setState(() {
      _rating = 5.0;
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.decelerate,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // lift with keyboard
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: _awaitingVerification
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('product_review_verify_email'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 6),
                    Text(
                      _guestEmail != null ? 'product_review_code_sent_to'.trParams({'email': _guestEmail!}) : 'product_review_code_sent_generic'.tr,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'product_review_enter_code'.tr,
                        counterText: "",
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _verifying ? null : _verifyCode,
                            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                            child: _verifying
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text('product_review_verify_btn'.tr, style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: (_resendCooldown > 0) ? null : _resendVerification,
                            child: Text(
                              _resendCooldown > 0 ? 'product_review_resend_in'.trParams({'seconds': _resendCooldown.toString()}) : 'product_review_resend_code'.tr,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('cancel'.tr),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('product_review_rating_label'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        RatingBar(
                          initialRating: _rating,
                          filledIcon: Icons.star,
                          emptyIcon: Icons.star_border,
                          size: 32,
                          onRatingChanged: (rating) {
                            setState(() {
                              _rating = rating;
                            });
                          },
                          maxRating: 5,
                        ),
                        SizedBox(width: 10),
                        Text('product_review_stars'.trParams({'count': _rating.toInt().toString()})),
                      ],
                    ),
                    SizedBox(height: 20),
                    if (!_loggedIn) ...[
                      Text('product_review_name_label'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'product_review_name_hint'.tr,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('product_review_email_label'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'product_review_email_hint'.tr,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text('product_review_write_label'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    TextField(
                      controller: _reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'product_review_comment_hint'.tr,
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submitReview,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: _submitting
                                ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text('product_review_submit_btn'.tr, style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _cancelReview,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                            child: Text('cancel'.tr, style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
