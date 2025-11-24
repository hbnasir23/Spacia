import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../consumer/screens/auth/login_screen.dart'; // ✅ make sure this path matches your structure

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // ✅ Navigate to login after fade completes (2.5 seconds)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.lightBrown,
      body: FadeTransition(
        opacity: _fade,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ✅ Single centered line + lamp
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 2,
                      height: h * 0.22,
                      color: AppColors.darkBrown,
                    ),
                    Transform.translate(
                      offset: const Offset(0, -1.5),
                      child: const Icon(
                        Icons.light,
                        size: 60,
                        color: AppColors.darkBrown,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: h * 0.22),

                  // Logo
                  Image.asset(
                    "assets/logo.png",
                    height: h * 0.12,
                  ),
                  SizedBox(height: h * 0.02),

                  // App Name
                  Text(
                    "Spacia",
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontWeight: FontWeight.w900,
                      fontSize: h * 0.045,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: h * 0.008),

                  // Tagline
                  Text(
                    "Decor that defines your space",
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontWeight: FontWeight.w400,
                      fontSize: h * 0.018,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: h * 0.05),

                  // Painting
                  const Icon(
                    Icons.photo_size_select_actual_rounded,
                    size: 70,
                    color: AppColors.darkBrown,
                  ),
                  SizedBox(height: h * 0.05),

                  // Table + chairs
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.table_bar,
                        size: 95,
                        color: AppColors.darkBrown,
                      ),
                      Positioned(
                        left: w * 0.22,
                        bottom: 0,
                        child: Transform.rotate(
                          angle: -0.1,
                          child: const Icon(
                            Icons.chair,
                            size: 70,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      ),
                      Positioned(
                        right: w * 0.22,
                        bottom: 0,
                        child: Transform.rotate(
                          angle: 0.1,
                          child: const Icon(
                            Icons.chair,
                            size: 70,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}