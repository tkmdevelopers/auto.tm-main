import 'package:auto_tm/ui_components/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'dart:async';

class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    Timer(Duration(seconds: 5), () {
      Get.offNamed('/navView'); // replace with your main screen
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.tertiary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            // child: Column(
            //   mainAxisSize: MainAxisSize.min,
            //   children: [
               child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  // child: Image.asset(
                  //   AppImages.splashLogoGif,
                  //   height: 300,
                  //   width: 300,
                  //   fit: BoxFit.contain,
                  // ),
                  child: Image.asset(AppImages.appLogoDark).animate(onPlay: (controller) => controller.repeat(),)//onPlay: (controller) => controller.repeat(),
                  .fadeIn(duration: 1000.ms)
                  .then(delay: 500.ms)
                  .fadeOut(duration: 1000.ms)
                  .then(delay: 1000.ms),
                  // .slideY(begin: 1, end: 0),
                ),
                // SizedBox(height: 20),
                // Text(
                //   'YourAppName',
                //   style: TextStyle(
                //     fontSize: 24,
                //     fontWeight: FontWeight.bold,
                //     color: theme.colorScheme.primary,
                //     letterSpacing: 1.2,
                //   ),
                // ),
                // SizedBox(height: 10),
                // CircularProgressIndicator(
                //   color: theme.colorScheme.secondary,
                //   strokeWidth: 2,
                // ),
            //   ],
            // ),
          ),
        ),
      ),
    );
  }
}
