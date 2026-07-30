import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';

/// Modern, Clean, Material 3 CTA Button with Micro-interactions & Accessibility
class ModernCtaButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isDesktop;

  const ModernCtaButton({
    Key? key,
    required this.onPressed,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  State<ModernCtaButton> createState() => _ModernCtaButtonState();
}

class _ModernCtaButtonState extends State<ModernCtaButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double fontSize = widget.isDesktop ? 13.0 : 12.5;
    final double iconSize = widget.isDesktop ? 18.0 : 16.0;
    final EdgeInsets padding = widget.isDesktop
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 14)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    return Semantics(
      button: true,
      enabled: true,
      label: 'Primeiro Investimento',
      hint: 'Abre a tela de cadastro para adicionar ativos à sua carteira',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isHovered
                      ? [AppColors.primaryBlueHover, AppColors.primaryBlue]
                      : [AppColors.primaryBlue, AppColors.primaryBlueDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: _isHovered ? 0.45 : 0.25),
                    blurRadius: _isHovered ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  borderRadius: BorderRadius.circular(12),
                  splashColor: AppColors.white.withValues(alpha: 0.15),
                  highlightColor: AppColors.white.withValues(alpha: 0.08),
                  child: Padding(
                    padding: padding,
                    child: Row(
                      mainAxisSize: widget.isDesktop ? MainAxisSize.min : MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          'Primeiro Investimento',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedSlide(
                          offset: _isHovered ? const Offset(0.2, 0) : Offset.zero,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: iconSize - 2,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
