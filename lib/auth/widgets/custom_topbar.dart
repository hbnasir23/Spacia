import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';

class CustomTopBar extends StatelessWidget {
  final String title;
  const CustomTopBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSizes.h(context, 0.012),
        bottom: AppSizes.h(context, 0.02),
        left: AppSizes.w(context, 0.04),
        right: AppSizes.w(context, 0.04),
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkBrown,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset('assets/logo.png', height: 48),
          SizedBox(width: AppSizes.w(context, 0.03)),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
