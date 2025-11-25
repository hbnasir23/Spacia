import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../constants/app_colors.dart';

class ProductARViewScreen extends StatefulWidget {
  final String modelUrl;
  final String name;

  const ProductARViewScreen({
    super.key,
    required this.modelUrl,
    required this.name,
  });

  @override
  State<ProductARViewScreen> createState() => _ProductARViewScreenState();
}

class _ProductARViewScreenState extends State<ProductARViewScreen> {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.lightBrown,
      appBar: AppBar(
        title: Text(
          widget.name,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.darkBrown,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ⭐ FIXED: No more overflow. Instructions scroll if needed.
      body: Column(
        children: [
          Flexible(
            flex: 2,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: AppColors.lightBrown,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Controls",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInstructionRow(Icons.touch_app, "1 Finger to Rotate"),
                    _buildInstructionRow(Icons.pan_tool_alt, "2 Fingers to Move"),
                    _buildInstructionRow(Icons.pinch, "Pinch to Zoom"),
                    _buildInstructionRow(Icons.view_in_ar, "Tap Bottom-Right for AR"),
                  ],
                ),
              ),
            ),
          ),

          // ⭐ MODEL VIEWER AREA
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),

                // ⭐ FIXED AR VIEW + MODEL SIZE + SMOOTH CAMERA
                child: ModelViewer(
                  backgroundColor: Colors.white,
                  src: widget.modelUrl,
                  alt: "3D model of ${widget.name}",

                  ar: true,
                  arModes: const ['scene-viewer', 'webxr', 'quick-look'],

                  autoRotate: true,
                  cameraControls: true,

                  // ⭐ FIX MODEL SCALE ISSUE → This keeps it centered & inside screen
                  cameraOrbit: "0deg 75deg auto",
                  cameraTarget: "0m 0m 0m",
                  exposure: 1,
                  disableZoom: false,

                  // ⭐ THIS FIXES BIG-MODEL ISSUE!
                  // Ensures model is framed correctly regardless of actual mesh size.
                  minCameraOrbit: "-45deg auto auto",
                  maxCameraOrbit: "45deg auto auto",
                  fieldOfView: "10deg",
                  minFieldOfView: "8deg",
                  maxFieldOfView: "30deg",

                  // ⭐ Smooth interaction
                  interactionPrompt: InteractionPrompt.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
