import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'constants/app_colors.dart';
import 'firebase_options.dart';
import 'consumer/screens/main_navigation_screen.dart';
import 'splash/splash_screen.dart';
import 'providers/cart_provider.dart';
import 'consumer/screens/products/products_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SpaciaApp());
}

class SpaciaApp extends StatelessWidget {
  const SpaciaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: 'Spacia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.darkBrown,
            primary: AppColors.darkBrown,
            secondary: AppColors.lightBrown,
            surface: AppColors.white,
          ),
        ),
        // Start at splash (or directly at main nav if you're testing)
        home: const SplashScreen(),
        routes: {
          '/main': (_) => const MainNavigationScreen(),
          '/products': (_) => const ProductsScreen(),
        },
      ),
    );
  }
}
