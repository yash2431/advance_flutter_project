class AboutModel {
  final String appName;
  final String version;
  final String developer;
  final String mentor;
  final String exploredBy;
  final String eulogizedBy;
  final String voiceRecorderDescription;
  final String aswdcDescription;
  final String vision;
  final String email;
  final String phone;
  final String website;
  final String privacyPolicyUrl;
  final String moreAppUrl;
  final String rateAppUrl;
  final String facebookUrl;

  // 🔹 Add these new fields
  final String? youtubeUrl;
  final String? linkedinUrl;

  AboutModel({
    required this.appName,
    required this.version,
    required this.developer,
    required this.mentor,
    required this.exploredBy,
    required this.eulogizedBy,
    required this.voiceRecorderDescription,
    required this.aswdcDescription,
    required this.vision,
    required this.email,
    required this.phone,
    required this.website,
    required this.privacyPolicyUrl,
    required this.moreAppUrl,
    required this.rateAppUrl,
    required this.facebookUrl,

    // 🔹 Add to constructor
    this.youtubeUrl,
    this.linkedinUrl,
  });
}
