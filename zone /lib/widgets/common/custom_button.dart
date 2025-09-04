import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor; 
  final Color? textColor;
  final IconData? icon;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor, 
    this.textColor,
    this.icon,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final Color actualBackgroundColor = backgroundColor ?? AppColors.primary;
    final Color actualTextColor = textColor ?? (isOutlined ? AppColors.primary : Colors.white);
    final Color actualBorderColor = isOutlined ? (backgroundColor ?? AppColors.primary) : Colors.transparent;

    Widget buttonChild = isLoading
        ? SizedBox(
            height: height * 0.4,
            width: height * 0.4,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(isOutlined ? AppColors.primary : Colors.white),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: actualTextColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: actualTextColor,
                ),
              ),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: actualBorderColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                foregroundColor: actualTextColor,
                padding: EdgeInsets.zero,
              ),
              child: buttonChild,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: actualBackgroundColor,
                foregroundColor: actualTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
                padding: EdgeInsets.zero,
              ),
              child: buttonChild,
            ),
    );
  }
}