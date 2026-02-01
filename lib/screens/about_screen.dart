import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'About',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),

            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.play_circle_outline,
                size: 60,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 24),

            // App Name
            const Text(
              'NEXT-GEN VIDEO PLAYER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Version
            Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),

            const SizedBox(height: 8),

            // Build Number
            Text(
              'Build 20240101',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),

            const SizedBox(height: 32),

            // Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'NEXT-GEN VIDEO PLAYER is a professional video player application designed for the best viewing experience. With support for multiple video formats, gesture controls, and advanced features, it provides everything you need for video playback.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Features
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Key Features',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('• Support for multiple video formats'),
                  _buildFeatureItem('• Gesture controls for easy navigation'),
                  _buildFeatureItem('• Adjustable playback speed'),
                  _buildFeatureItem('• Multiple aspect ratio options'),
                  _buildFeatureItem('• Subtitle support'),
                  _buildFeatureItem('• Hardware acceleration'),
                  _buildFeatureItem('• Performance optimization'),
                  _buildFeatureItem('• Dark theme interface'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Developer Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Developer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Professional Flutter Development',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Built with Flutter and Riverpod',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contact & Links
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connect',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLinkItem(
                    'Report Issues',
                    Icons.bug_report,
                    () => _launchUrl('https://github.com/issues'),
                  ),
                  _buildLinkItem(
                    'Request Features',
                    Icons.lightbulb_outline,
                    () => _launchUrl('https://github.com/features'),
                  ),
                  _buildLinkItem(
                    'Rate App',
                    Icons.star,
                    () => _launchUrl('https://play.google.com/store'),
                  ),
                  _buildLinkItem('Share App', Icons.share, () => _shareApp()),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Legal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Legal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLinkItem(
                    'Privacy Policy',
                    Icons.privacy_tip,
                    () => _showPrivacyPolicy(context),
                  ),
                  _buildLinkItem(
                    'Terms of Service',
                    Icons.description,
                    () => _showTermsOfService(context),
                  ),
                  _buildLinkItem(
                    'Licenses',
                    Icons.info,
                    () => _showLicenses(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Copyright
            Text(
              '© 2024 NEXT-GEN VIDEO PLAYER',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),

            const SizedBox(height: 8),

            Text(
              'All rights reserved',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _buildLinkItem(String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  void _shareApp() {
    // Implement share functionality
    debugPrint('Share app functionality');
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy for Video Player Lite\n\n'
            'Last updated: January 1, 2024\n\n'
            'This privacy policy explains how Video Player Lite collects, uses, and protects your information.\n\n'
            'Information We Collect:\n'
            '- Usage analytics and crash reports\n'
            '- Device information for optimization\n'
            '- User preferences and settings\n\n'
            'How We Use Information:\n'
            '- To improve app performance and features\n'
            '- To fix bugs and crashes\n'
            '- To provide customer support\n\n'
            'Data Protection:\n'
            '- All data is stored locally on your device\n'
            '- No personal information is shared with third parties\n'
            '- We use industry-standard security measures\n\n'
            'Contact Us:\n'
            'If you have questions about this privacy policy, please contact us.',
            style: TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Terms of Service',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service for Video Player Lite\n\n'
            'Last updated: January 1, 2024\n\n'
            'By using Video Player Lite, you agree to these terms:\n\n'
            '1. Acceptance of Terms\n'
            'By using this app, you accept these terms and conditions.\n\n'
            '2. Use of the App\n'
            '- You may use this app for personal, non-commercial purposes\n'
            '- You must not reverse engineer or modify the app\n'
            '- You must not violate any applicable laws\n\n'
            '3. Intellectual Property\n'
            'All content and features are owned by Video Player Lite or its licensors.\n\n'
            '4. Disclaimer\n'
            'The app is provided "as is" without warranties of any kind.\n\n'
            '5. Limitation of Liability\n'
            'Video Player Lite is not liable for any damages arising from app use.\n\n'
            '6. Changes to Terms\n'
            'We reserve the right to modify these terms at any time.\n\n'
            '7. Contact Information\n'
            'For questions about these terms, please contact us.',
            style: TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'NEXT-GEN VIDEO PLAYER',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.play_circle_outline, color: Colors.red),
      applicationLegalese: '© 2024 NEXT-GEN VIDEO PLAYER. All rights reserved.',
    );
  }
}
