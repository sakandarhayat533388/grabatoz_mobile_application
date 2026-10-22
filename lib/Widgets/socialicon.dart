import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:url_launcher/url_launcher_string.dart'; // Import this


class SocialIcon extends StatelessWidget {

  final String assetPath;

  final String url; // Add this

  final double size;


  const SocialIcon({

    super.key,

    required this.assetPath,

    required this.url, // Add this

    this.size = 20,

    // VoidCallback? onTap, // Remove this if it's only for launching the URL

  });


  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.symmetric(horizontal: 6.0),

      child: InkWell(

        borderRadius: BorderRadius.circular(size * 2), // Make tappable area slightly larger and circular

        onTap: () async { // Modify this

          if (url.isEmpty) {

            print('SocialIcon: URL is empty, cannot launch.');

            ScaffoldMessenger.of(context).showSnackBar(

              SnackBar(content: Text('common_link_unavailable'.tr)),

            );

            return;

          }

          try {

            if (await canLaunchUrlString(url)) {

              await launchUrlString(url);

            } else {

              print('SocialIcon: Could not launch $url (canLaunchUrlString returned false).');

              ScaffoldMessenger.of(context).showSnackBar(

                SnackBar(content: Text('common_link_open_failed'.trParams({'url': url}))),

              );

            }

          } catch (e) {

            print('SocialIcon: Exception trying to launch $url: $e');

            ScaffoldMessenger.of(context).showSnackBar(

              SnackBar(content: Text('common_link_open_error'.tr)),

            );

          }

        },

        child: Container(

          padding: const EdgeInsets.all(10), // space inside the circle

          decoration: BoxDecoration(

            shape: BoxShape.circle,

            border: Border.all(

              color: Colors.grey.shade200, // grey border

              width: 1.5,

            ),

            color: Colors.transparent, // transparent background

          ),

          child: Image.asset(

            assetPath,

            height: size,

            width: size,

            fit: BoxFit.contain,

          ),

        ),

      ),

    );

  }

}
