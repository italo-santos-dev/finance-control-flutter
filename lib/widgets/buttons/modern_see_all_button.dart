import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';

/// Reusable Modern & Minimalist "Ver todos" Pill Button Component
class ModernSeeAllButton extends StatefulWidget {
  final VoidCallback? onTap;
  final String label;

  const ModernSeeAllButton({
    Key? key,
    this.onTap,
    this.label = 'Ver todos',
  }) : super(key: key);

  @override
  State<ModernSeeAllButton> createState() => _ModernSeeAllButtonState();
}

class _ModernSeeAllButtonState extends State<ModernSeeAllButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isHovered
              ? AppColors.primaryBlue.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered
                ? AppColors.primaryBlue.withValues(alpha: 0.5)
                : AppColors.borderDark.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isHovered ? AppColors.white : Colors.grey[300],
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                size: 12,
                color: isHovered ? AppColors.blueAccent : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
