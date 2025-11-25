import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../constants/app_colors.dart';
import '../../../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ===========================
  // LOGOUT POPUP
  // ===========================
  Future<void> _confirmLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.darkBrown,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Text(
                "Confirm Logout",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: const Text(
                "Are you sure you want to logout?",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.darkBrown),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: AppColors.darkBrown,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Logout button
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await AuthService.signOut();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logged out successfully'),
                          backgroundColor: AppColors.darkBrown,
                        ),
                      );

                      await Future.delayed(const Duration(milliseconds: 500));

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBrown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================
  // CUSTOM POPUP FOR DETAILS
  // ===========================
  void _showPopup(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.darkBrown,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                content,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),

            // Close Button
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBrown,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Close",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================
  // MAIN UI
  // ===========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: AppColors.lightBrown,
        foregroundColor: AppColors.darkBrown,
      ),
      backgroundColor: AppColors.lightBrown,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const Text(
                "Settings",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 20),

              // ABOUT US
              _settingItem(
                icon: Icons.info_outline,
                title: "About Us",
                onTap: () => _showPopup(
                  context,
                  "About Us",
                  "Welcome to Spacia — proudly built by Haris Bin Nasir, a student of "
                      "Energy Engineering Technology based in Karachi.\n\n"
                      "Spacia provides a seamless furniture browsing experience with AR previews "
                      "and beautifully designed UI.",
                ),
              ),

              // HELP & SUPPORT
              _settingItem(
                icon: Icons.help_outline,
                title: "Help & Support",
                onTap: () => _showPopup(
                  context,
                  "Help & Support",
                  "📞 Phone: +92 331 811 5853\n"
                      "📧 Email: hbnasir23@gmail.com\n\n"
                      "We are Karachi-based and always ready to assist you with any issue.",
                ),
              ),

              // PRIVACY POLICY
              _settingItem(
                icon: Icons.privacy_tip_outlined,
                title: "Privacy Policy",
                onTap: () => _showPopup(
                  context,
                  "Privacy Policy",
                  "Your privacy is important to us. Spacia follows standard data protection "
                      "laws and industry compliance. Your information is never shared without permission.\n\n"
                      "We ensure encrypted storage and strict security measures.",
                ),
              ),

              // TERMS & CONDITIONS
              _settingItem(
                icon: Icons.description_outlined,
                title: "Terms & Conditions",
                onTap: () => _showPopup(
                  context,
                  "Terms & Conditions",
                  "By using Spacia, you agree not to copy, steal, or redistribute our content, "
                      "UI, or data.\n\nAll rights reserved © Spacia.",
                ),
              ),

              const SizedBox(height: 30),

              // LOGOUT BUTTON → WITH POPUP
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "Logout",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================
  // SETTING ITEM WIDGET
  // ===========================
  Widget _settingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBrown.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.darkBrown),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing:
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
