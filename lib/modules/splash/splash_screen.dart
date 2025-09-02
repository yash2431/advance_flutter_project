import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hacky_voice_recorder/routes/app_routes.dart';
import 'package:lottie/lottie.dart';
import 'connectivity_controller.dart';

// Splash screen widget with dynamic animation and WiFi status
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller for dynamic effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
    // Navigate to record screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Get.toNamed(AppRoutes.RECORD);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivityController = Get.find<ConnectivityController>();

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient for attractive design
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlue],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Centered Lottie animation for dynamic effect
          Center(
            child: Lottie.asset(
              'lib/assets/animations/Search Mic wave.json',
              controller: _animationController,
              width: 600,
              height: 600,
              fit: BoxFit.contain,
              onLoaded: (composition) {
                _animationController.duration = composition.duration;
                _animationController.repeat();
              },
            ),
          ),
          // App title
          const Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Text(
              'Voice Recorder',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black45,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
          // Logo at extreme footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'lib/assets/logos/Gemini_Generated_Image_30w8wq30w8wq30w8.png', // Update this path to your saved image
                width: double.infinity, // Adjust width as needed
                height: 100, // Adjust height as needed
                fit: BoxFit.contain,
              ),
            ),
          ),
          // WiFi symbol in top right corner
          Positioned(
            top: 40,
            right: 20,
            child: Obx(
              () => Icon(
                connectivityController.isConnected.value
                    ? Icons.wifi
                    : Icons.wifi_off,
                color: connectivityController.isConnected.value
                    ? Colors.green.shade800
                    : Colors.red,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
