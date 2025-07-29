import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/colors.dart';

/// bottomsheet - appears when clicked images icon in CHAT SCREEN
class ImageSelectionBottomSheet extends StatelessWidget {
  final VoidCallback? onCameraTap;
  final VoidCallback? onPhotosTap;
  final VoidCallback? onFilesTap;

  const ImageSelectionBottomSheet({
    super.key,
    this.onCameraTap,
    this.onPhotosTap,
    this.onFilesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.appBar,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOption(
                    icon: 'assets/camera.svg',
                    label: 'Camera',
                    onTap: onCameraTap,
                  ),
                  _buildOption(
                    icon: 'assets/photo.svg',
                    label: 'Photos',
                    onTap: onPhotosTap,
                  ),
                  _buildOption(
                    icon: 'assets/files.svg',
                    label: 'Files',
                    onTap: onFilesTap,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.userBubbleLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    icon,
                    color: Colors.white,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
} 