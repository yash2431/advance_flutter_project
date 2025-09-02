import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'about_us_controller.dart';

class AboutView extends GetView<AboutController> {
  const AboutView({super.key});

  Widget buildCard(String title, List<Widget> children) {
    final isDark = Get.isDarkMode;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isDark ? 8 : 4,
      shadowColor: isDark ? Colors.black54 : Colors.blue.shade200,
      color: isDark
          ? const Color(0xFF1E2A47).withOpacity(0.9)
          : const Color(0xFFE3F2FD),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isDark
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E2A47),
              const Color(0xFF2D3A5F),
            ],
          )
              : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFE3F2FD),
              const Color(0xFFBBDEFB),
            ],
          ),
          border: Border.all(
            color: isDark
                ? Colors.blue.shade300.withOpacity(0.3)
                : Colors.blue.shade100,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.lightBlue : Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isDark ? Colors.lightBlue : Colors.blue.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDark ? Colors.lightBlue.withOpacity(0.6) : Colors.blue.shade300,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final about = controller.about.value;
    final isDark = Get.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1419)
          : const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: const Text(
          "About Us",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark
            ? const Color(0xFF1A2332)
            : Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                const Color(0xFF1A2332),
                const Color(0xFF2D3A5F),
              ]
                  : [
                Colors.blue.shade700,
                Colors.blue.shade900,
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
              const Color(0xFF0F1419),
              const Color(0xFF1A2332),
            ]
                : [
              const Color(0xFFF8FBFF),
              const Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // App Icon with enhanced styling
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                      Colors.lightBlue.shade400,
                      Colors.blue.shade700,
                    ]
                        : [
                      Colors.white,
                      Colors.blue.shade50,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.lightBlue.withOpacity(0.3)
                          : Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: isDark
                        ? Colors.lightBlue.withOpacity(0.5)
                        : Colors.blue.withOpacity(0.2),
                    width: 3,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SvgPicture.asset(
                    "lib/assets/app_icon/voice_recorder_icon.svg",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // App Name & Version with enhanced styling
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                      Colors.lightBlue.withOpacity(0.1),
                      Colors.blue.withOpacity(0.1),
                    ]
                        : [
                      Colors.blue.withOpacity(0.1),
                      Colors.lightBlue.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.lightBlue.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      about.appName,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.lightBlue : Colors.blue.shade800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Version ${about.version}",
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Meet Our Team Card
              buildCard("Meet Our Team", [
                _buildInfoRow(Icons.developer_mode, "Developed by", about.developer, isDark),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.school, "Mentored by", about.mentor, isDark),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.explore, "Explored by", about.exploredBy, isDark),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.star, "Eulogized by", about.eulogizedBy, isDark),
              ]),

              //About voice recorder
              buildCard("About Hacky Voice Recorder", [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.05),
                  ),
                  child: Text(
                    about.voiceRecorderDescription,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: isDark ? Colors.grey.shade200 : Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ]),

              // About ASWDC Card
              buildCard("About ASWDC", [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.7),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            "lib/assets/logos/logo1.jpg",
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            "lib/assets/logos/logo2.jpg",
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  about.aswdcDescription,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade200 : Colors.black87,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
              ]),

              // Our Vision Card
              buildCard("Our Vision", [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                        Colors.lightBlue.withOpacity(0.1),
                        Colors.blue.withOpacity(0.1),
                      ]
                          : [
                        Colors.blue.withOpacity(0.05),
                        Colors.lightBlue.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Text(
                    about.vision,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade200 : Colors.black87,
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                ),
              ]),

              // Contact Us Card
              buildCard("Contact Us", [
                _buildContactTile(
                    Icons.email_rounded,
                    about.email,
                    Colors.red.shade400,
                        () => controller.sendEmail(about.email),
                    isDark
                ),
                _buildContactTile(
                    Icons.phone_rounded,
                    about.phone,
                    Colors.green.shade400,
                        () => controller.callPhone(about.phone),
                    isDark
                ),
                _buildContactTile(
                    Icons.language_rounded,
                    about.website,
                    Colors.blue.shade400,
                        () => controller.openUrl(about.website),
                    isDark
                ),
              ]),

              // More Options Card
              buildCard("More Options", [
                _buildOptionTile(Icons.share_rounded, "Share App", Colors.purple.shade400, () => controller.shareApp(), isDark),
                _buildOptionTile(Icons.apps_rounded, "More App", Colors.indigo.shade400, () => controller.openMoreApps(), isDark),
                _buildOptionTile(Icons.star_rate_rounded, "Rate Us", Colors.amber.shade400, () => controller.rateUs(), isDark),
                _buildOptionTile(Icons.thumb_up_rounded, "Like us on Facebook", Colors.blueAccent, () => controller.openFacebook(), isDark),
                _buildOptionTile(Icons.ondemand_video_rounded, "Watch us on YouTube", Colors.red.shade400, () => controller.openYouTube(), isDark),
                _buildOptionTile(Icons.business_rounded, "Connect on LinkedIn", Colors.blueGrey.shade400, () => controller.openLinkedIn(), isDark),
                _buildOptionTile(Icons.update_rounded, "Check For Update", Colors.teal.shade400, () => controller.openUrl(about.rateAppUrl), isDark),
              ]),

              const SizedBox(height: 24),

              // Footer Section with enhanced styling
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                      const Color(0xFF1E2A47).withOpacity(0.5),
                      const Color(0xFF2D3A5F).withOpacity(0.5),
                    ]
                        : [
                      Colors.blue.withOpacity(0.1),
                      Colors.lightBlue.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.lightBlue.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "© ${DateTime.now().year} Darshan University",
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: () => controller.openPrivacyPolicy(),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(text: "All Rights Reserved - "),
                            TextSpan(
                              text: "Privacy Policy",
                              style: TextStyle(
                                color: isDark ? Colors.lightBlue : Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Made with ",
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                        Icon(
                          Icons.favorite,
                          color: Colors.red.shade400,
                          size: 16,
                        ),
                        Text(
                          " in India",
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.lightBlue.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.lightBlue : Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: isDark ? Colors.grey.shade200 : Colors.black87,
                fontSize: 15,
              ),
              children: [
                TextSpan(
                  text: "$label : ",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile(IconData icon, String title, Color iconColor, VoidCallback onTap, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.grey.shade200 : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, Color iconColor, VoidCallback onTap, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.grey.shade200 : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
