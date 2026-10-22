import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Controllers/authController.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RequestForm extends StatefulWidget {
  const RequestForm({super.key});

  @override
  State<RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<RequestForm> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  AuthController _authController = Get.put(AuthController());
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }

  getData() async {
    await _authController.loadUserData();
    nameController.text = _authController.fullName.value;
    emailController.text = _authController.email.value;
    setState(() {});
  }

  bool isloading = false;
  Future<void> postcallsubmission(
      String name, String email, String phone) async {
    String url =
        "${Configss.requestCallback}"; // <-- Replace with your actual URL
    isloading = true;
    SharedPreferences sp = await SharedPreferences.getInstance();
    String token = sp.getString('token') ?? ''; // <-- Replace with actual token
    setState(() {});
    final Map<String, dynamic> bodyData = {
      "name": name,
      "email": email,
      "phone": phone
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyData),
    );
    isloading = false;
    setState(() {});
    if (response.statusCode == 200 || response.statusCode == 201) {
      // Success

      EasyLoading.showSuccess('product_callback_submitted'.tr);
      Navigator.pop(context);
      print('Request Submitted');
      print('Response: ${response.body}');
    }
    if (response.statusCode == 400) {
      // Success
      final data = jsonDecode(response.body);
      EasyLoading.showError('${data['message']}');
      // Navigator.pop(context);
    } else {
      // Error
      print('Failed to post review. Status code: ${response.statusCode}');
      print('Error response: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image at the top
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(
                  'assets/images/pic.png'), // Replace with your image
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'product_callback_title'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Name Field
          TextField(
            controller: nameController,
            decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                labelText: 'product_review_name_label'.tr,
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey))),
          ),
          const SizedBox(height: 12),

          // Email Field
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'product_review_email_label'.tr,
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey)),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 12),

          // Phone Field
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                labelText: 'product_callback_phone_label'.tr,
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey))),
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff8BC34A), // light green
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                if (phoneController.text.isNotEmpty) {
                  postcallsubmission(
                      nameController.text.toString(),
                      emailController.text.toString(),
                      phoneController.text.toString());
                }

                // Handle request here...
              },
              child: isloading
                  ? CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : Text('product_callback_submit'.tr,
                      style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }
}
