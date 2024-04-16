import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AboutApp extends StatelessWidget {
  AboutApp({required this.appVersion, super.key});

  final String appVersion;

  final List<String> externalWebsites = [
    "https://www.dualmonitorbackgrounds.com",
    "https://www.triplemonitorbackgrounds.com",
  ];

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      content: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
            maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Blissful Backdrop',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 8),
              const Text(
                'About',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                  "Blissful Backdrop brings tranquility to your device by offering a curated collection of breathtaking wallpapers designed to elevate your mood and inspire your day.\nVersion $appVersion"),
              const SizedBox(height: 12),
              const Text(
                'Disclaimer & Terms',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 8),
              const Text(
                "This application retrieves wallpapers from various websites for display purposes only. We do not claim ownership or rights to any of the images displayed within the application. The wallpapers are sourced from publicly available websites and are displayed under the principles of fair use. We make every effort to ensure that the wallpapers displayed are appropriate and do not infringe upon any copyrights or trademarks. However, if you believe that any content displayed within the application violates your intellectual property rights, please contact us immediately so that we can take appropriate action. Please note that the availability and quality of wallpapers may vary, as they are sourced from external websites. We do not endorse or guarantee the accuracy, reliability, or legality of any content provided by third-party websites. By using this application, you acknowledge and agree that we shall not be held responsible for any issues arising from the use of the wallpapers displayed within the application. Thank you for using Blissful Backdrop responsibly.",
              ),
              Text("\nExternal websites: \n${externalWebsites.join('\n')}"),
              const SizedBox(height: 12),
              const Text(
                'Contact Us',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: "Email: "),
                    TextSpan(
                      text: "developer.hvg24@gmail.com\n",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrlString("mailto:developer.hvg24@gmail.com");
                        },
                    ),
                    // const TextSpan(text: "Website: "),
                    // TextSpan(
                    //   text: "https://theharshgautam.netlify.app/",
                    //   style: const TextStyle(fontWeight: FontWeight.w500),
                    //   recognizer: TapGestureRecognizer()
                    //     ..onTap = () {
                    //       launchUrlString(
                    //           "https://theharshgautam.netlify.app/");
                    //     },
                    // )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
