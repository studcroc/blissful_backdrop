import 'package:flutter/material.dart';

class AboutApp extends StatelessWidget {
  const AboutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
            maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Blissful Backdrop',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 8),
              Text(
                'About',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 8),
              Text(
                  "Blissful Backdrop brings tranquility to your device by offering a curated collection of breathtaking wallpapers designed to elevate your mood and inspire your day.\nVersion 1.0.0"),
              SizedBox(height: 12),
              Text(
                'Disclaimer & Terms',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 8),
              Text(
                "This application retrieves wallpapers from various websites for display purposes only. We do not claim ownership or rights to any of the images displayed within the application. The wallpapers are sourced from publicly available websites (https://www.dualmonitorbackgrounds.com, https://www.triplemonitorbackgrounds.com) and are displayed under the principles of fair use. We make every effort to ensure that the wallpapers displayed are appropriate and do not infringe upon any copyrights or trademarks. However, if you believe that any content displayed within the application violates your intellectual property rights, please contact us immediately so that we can take appropriate action. Please note that the availability and quality of wallpapers may vary, as they are sourced from external websites. We do not endorse or guarantee the accuracy, reliability, or legality of any content provided by third-party websites. By using this application, you acknowledge and agree that we shall not be held responsible for any issues arising from the use of the wallpapers displayed within the application. Thank you for using Blissful Backdrop responsibly.",
              ),
              SizedBox(height: 12),
              Text(
                'Contact Us',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 8),
              Text('''Email: developer.hvg24@gmail.com
Website: https://theharshgautam.netlify.app/'''),
            ],
          ),
        ),
      ),
    );
  }
}
