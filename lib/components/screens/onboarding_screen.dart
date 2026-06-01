import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    // Load appropriate image based on theme
    final img1 = 'assets/images/onboarding_1.png';
    final img2 = 'assets/images/onboarding_2.png';

    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
            });
          },
          children: [
            // Page 1
            _buildPage(
              imagePath: img1,
              text: "Find hidden kuliner around you",
              buttonText: "Explore Now", // right arrow
              onButtonPressed: _nextPage,
            ),
            // Page 2
            _buildPage(
              imagePath: img2,
              text: "You know it, you share it",
              buttonText: "Join Now",
              onButtonPressed: _nextPage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String imagePath,
    required String text,
    required String buttonText,
    required VoidCallback onButtonPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Empty spacing or top logo if needed
          const SizedBox(height: 20),
          
          // Illustration Image
          Expanded(
            child: Center(
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Title Text
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              
              fontSize: 22,
              fontWeight: FontWeight.normal,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 50),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: TextButton(
              onPressed: onButtonPressed,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFF7260), // Coral orange/red
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // pill button
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.black,
                  
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}