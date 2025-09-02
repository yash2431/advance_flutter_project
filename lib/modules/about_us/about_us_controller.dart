import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'about_us_model.dart';

class AboutController extends GetxController {
  final about = AboutModel(
    appName: "Hacky Voice Recorder",
    version: "1.0.0",
    developer: "Yash Pipalava (23010101208)",
    mentor: "Prof. Mehul Bhundiya (Computer Engineering)",
    exploredBy: "ASWDC, School of Computer Science",
    eulogizedBy: "Darshan University, Rajkot, Gujarat - INDIA",
    voiceRecorderDescription:
        "🎤 Voice Recorder:\n"
        "Record high-quality audio directly within the app."
        "Easily save, manage, and playback your recordings anytime.\n\n"
        "🗣️ Speech-to-Text:\n"
        "Convert your voice into text seamlessly using advanced speech recognition."
        "Perfect for quick notes, transcriptions, or hands-free interaction.",
    aswdcDescription:
        "ASWDC is an Application, Software, and Website Development Center at Darshan University, run by students & faculty members of the School of Computer Science.",
    vision:
        "The sole purpose of ASWDC is to bridge the gap between university curriculum & industry demands. Students learn cutting-edge technologies, develop real-world applications, and gain professional experience under expert guidance.",
    email: "aswdc@darshan.ac.in",
    phone: "+91-9727747317",
    website: "https://www.darshan.ac.in",
    privacyPolicyUrl: "https://darshan.ac.in/aswdc-privacy-policy-general",
    moreAppUrl:
        "https://play.google.com/store/apps/developer?id=Darshan+University",
    rateAppUrl:
        "https://play.google.com/store/apps/details?id=com.example.hacky_voice_recorder",
    facebookUrl: "https://www.facebook.com/DarshanUniversity",

    // 🔹 Added footer URLs (from screenshot reference)
    youtubeUrl: "https://www.youtube.com/channel/UC3TJzmjHMJGtgK-jI4I-Eaw",
    linkedinUrl: "https://in.linkedin.com/school/darshanuniversity",
  ).obs;

  /// Open any URL safely (web/social/privacy/etc.)
  Future<void> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
          Get.snackbar("Error", "Cannot open link: $url");
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Invalid URL: $url");
    }
  }

  /// Send email
  Future<void> sendEmail(String email) async {
    try {
      final uri = Uri(scheme: "mailto", path: email);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        Get.snackbar("Error", "No email app found");
      }
    } catch (e) {
      Get.snackbar("Error", "Cannot send email");
    }
  }

  /// Call phone
  Future<void> callPhone(String phone) async {
    try {
      final uri = Uri(scheme: "tel", path: phone);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        Get.snackbar("Error", "No phone app found");
      }
    } catch (e) {
      Get.snackbar("Error", "Cannot make call");
    }
  }

  /// Share app link
  void shareApp() {
    Share.share(
      "Check out this awesome Voice Recorder app: ${about.value.rateAppUrl}",
    );
  }

  // 🔹 Footer helpers
  void openMoreApps() => openUrl(about.value.moreAppUrl);

  void openPrivacyPolicy() => openUrl(about.value.privacyPolicyUrl);

  void rateUs() => openUrl(about.value.rateAppUrl);

  // 🔹 Social Media actions
  void openFacebook() => openUrl(about.value.facebookUrl);

  void openYouTube() => openUrl(about.value.youtubeUrl!);

  void openLinkedIn() => openUrl(about.value.linkedinUrl!);
}
