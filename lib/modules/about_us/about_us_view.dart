import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Interface for AboutUsService (ISP, DIP)
abstract class IAboutUsService {
  Future<Map<String, String>> getAboutUsContent();
}

// Concrete service implementation (SRP)
class AboutUsService implements IAboutUsService {
  @override
  Future<Map<String, String>> getAboutUsContent() async {
    // Mock data; replace with API call or actual content from https://aswdc.in/About-Us
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay
    return {
      'title': 'About ASWDC',
      'description': '''
The App & Software Development Center (ASWDC) is dedicated to fostering innovation and excellence in technology. We aim to empower students and professionals by providing cutting-edge solutions, training, and resources in app and software development.

Our mission is to bridge the gap between academic learning and industry requirements by offering hands-on experience in real-world projects. We specialize in developing mobile applications, web solutions, and software products that cater to modern business needs.
      ''',
      'mission': 'To provide innovative solutions and empower the next generation of developers through education and practical experience.',
      'vision': 'To be a global leader in technology education and software development, driving innovation and excellence.',
      // New data from screenshot
      'computerDeptTitle': 'About Computer Department',
      'computerDeptDescription': '''
Computer Engineering has enabled technological revolution in fields like medical, missiles, satellite, communication, transportation, etc. Due to the rapid growth of computer & internet and its impact on our lives, Computer Engineering has become one of the fastest growing segments of world's economy.

The department has well qualified, experienced and dedicated faculty providing excellent teaching & learning environment. Faculties with industrial background bridge the gap between academic learning and industrial needs. Faculties are easily accessible and enjoy mentoring students.

The department regularly conducts various seminars, Expert talks and training programs on advanced technologies for the up-gradation of student's & staff knowledge and makes them compatible with market requirements.
      ''',
      'instituteTitle': 'About Darshan Institute of Engineering & Technology',
      'instituteDescription': '''
The Institute is affiliated to the Gujarat Technological University and approved by the AICTE. New Delhi. The Institute was established in the year 2009, by Shree G.N.Patel Education & Charitable Trust with undergraduate, graduate and postgraduate programs in engineering.

Darshan is managed by technical experienced & well qualified management team, under leadership of Dr. R.G. Dhamsaniya. From its inception, the college has grown steadily and is imparting quality technical education.

The Institute has well experienced, highly qualified and dedicated faculty for committed education. All head of the departments and senior faculties are reputed industrial consultants. Institute also runs many consultancies in different departments.
      ''',
      'aswdcDescription': 'ASWDC is established by Department of Computer Engineering where students work on live projects under guidance of staff and industry experts. Students are getting extensive knowledge and industrial experience of cutting-edge technologies. ASWDC fills gap between academic curriculum and industry expectation.',
      'links': 'About Us\nTeam\nPortfolio\nLatest News\nContact Us',
      'contact': 'At. Hadala, Near Water Sump,\nRajkot - Morbi Highway, Rajkot\n+91-92777 47317\n+91-98255 63616\naswdc@darshan.ac.in\nwww.darshan.ac.in',
    };
  }
}

// Controller for state management (SRP, GetX)
class AboutUsController extends GetxController {
  final IAboutUsService service;
  var content = <String, String>{}.obs;
  var isLoading = true.obs;

  AboutUsController({required this.service});

  @override
  void onInit() {
    super.onInit();
    fetchContent();
  }

  Future<void> fetchContent() async {
    try {
      isLoading.value = true;
      content.value = await service.getAboutUsContent();
    } finally {
      isLoading.value = false;
    }
  }
}

// Reusable widget for content sections (OCP, SRP)
class SectionWidget extends StatelessWidget {
  final String title;
  final String content;

  const SectionWidget({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5F7FA), Color(0xFFE0E7F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003087),
                  shadows: [Shadow(color: Colors.black12, offset: Offset(1, 1), blurRadius: 2)],
                ),
              ),
              SizedBox(height: 16),
              Text(
                content,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Color(0xFF4A5568),
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget for the new info section (SRP)
class InfoSectionWidget extends StatelessWidget {
  final String aswdcDescription;
  final String links;
  final String contact;

  const InfoSectionWidget({
    required this.aswdcDescription,
    required this.links,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF1A1A1A), // Dark background
      padding: EdgeInsets.all(24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColumn('ABOUT ASWDC', aswdcDescription),
                SizedBox(height: 20),
                _buildColumn('LINKS', links, showIcons: true),
                SizedBox(height: 20),
                _buildColumn('CONTACT US', contact, showIcons: true),
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildColumn('ABOUT ASWDC', aswdcDescription)),
                SizedBox(width: 24),
                Expanded(child: _buildColumn('LINKS', links, showIcons: true)),
                SizedBox(width: 24),
                Expanded(child: _buildColumn('CONTACT US', contact, showIcons: true)),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildColumn(String title, String content, {bool showIcons = false}) {
    List<String> lines = content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD1D5DB),
          ),
        ),
        SizedBox(height: 16),
        ...lines.map((line) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: showIcons
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _getIconForLine(line),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  line.trim(),
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    color: Color(0xFFB0B7C3),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          )
              : Text(
            line.trim(),
            style: GoogleFonts.lato(
              fontSize: 15,
              color: Color(0xFFB0B7C3),
              height: 1.5,
            ),
          ),
        )),
      ],
    );
  }

  Widget _getIconForLine(String line) {
    if (line.contains('+91')) return Icon(Icons.phone, color: Color(0xFFD1D5DB), size: 18);
    if (line.contains('@')) return Icon(Icons.email, color: Color(0xFFD1D5DB), size: 18);
    if (line.contains('www')) return Icon(Icons.language, color: Color(0xFFD1D5DB), size: 18);
    if (line.contains('Rajkot')) return Icon(Icons.location_on, color: Color(0xFFD1D5DB), size: 18);
    return SizedBox.shrink(); // No icon for other lines
  }
}

// Main About Us page (SRP)
class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Inject dependencies
    final controller = Get.put(AboutUsController(service: AboutUsService()));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About Us',
          style: GoogleFonts.lato(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF003087),
        elevation: 6,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF003087), Color(0xFF0055A4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Obx(
            () => controller.isLoading.value
            ? Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0055A4),
            strokeWidth: 3,
          ),
        )
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Inside the AboutUsPage build method, update the Container for the banner image
              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('lib/assets/logos/Screenshot 2025-08-20 163259.png'), // Update this path to your saved image
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.2),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0xFF003087).withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Content Sections
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionWidget(
                      title: controller.content['title'] ?? 'About ASWDC',
                      content: controller.content['description'] ?? '',
                    ),
                    SectionWidget(
                      title: 'Our Mission',
                      content: controller.content['mission'] ?? '',
                    ),
                    SectionWidget(
                      title: 'Our Vision',
                      content: controller.content['vision'] ?? '',
                    ),
                    SectionWidget(
                      title: controller.content['computerDeptTitle'] ?? 'About Computer Department',
                      content: controller.content['computerDeptDescription'] ?? '',
                    ),
                    SectionWidget(
                      title: controller.content['instituteTitle'] ?? 'About Darshan Institute of Engineering & Technology',
                      content: controller.content['instituteDescription'] ?? '',
                    ),
                  ],
                ),
              ),
              // New Info Section from screenshot
              InfoSectionWidget(
                aswdcDescription: controller.content['aswdcDescription'] ?? '',
                links: controller.content['links'] ?? '',
                contact: controller.content['contact'] ?? '',
              ),
              // Footer
              Container(
                color: Color(0xFF003087),
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '© 2025 ASWDC. All rights reserved.',
                      style: GoogleFonts.lato(color: Colors.white, fontSize: 14),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.copyright, color: Colors.white, size: 14),
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
