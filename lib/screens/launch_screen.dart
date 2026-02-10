import 'package:flutter/material.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    // Navigate to main screen after shorter delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        try {
          Navigator.of(context).pushReplacementNamed('/main');
        } catch (e) {
          debugPrint('Navigation error: $e');
          // Fallback: try to navigate after a short delay
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              try {
                Navigator.of(context).pushReplacementNamed('/main');
              } catch (e2) {
                debugPrint('Fallback navigation also failed: $e2');
              }
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: _buildContent());
  }

  Widget _buildContent() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF000000), Color(0xFF1A1A1A), Color(0xFF000000)],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // App Name
                    const Text(
                      'PARTHI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'PLAY',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.red.withValues(alpha: 0.8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tagline
                    Text(
                      'Professional Video Experience',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
