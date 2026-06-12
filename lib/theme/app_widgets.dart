import 'package:flutter/material.dart';
import 'app_effects.dart';
import 'app_theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color colorStart;
  final Color colorEnd;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.colorStart = AppColors.primary,
    this.colorEnd = AppColors.primaryDark,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [colorStart, colorEnd]),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: colorStart.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(label, style: AppTextStyles.button),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AppPageBackground extends StatelessWidget {
  final Widget child;

  const AppPageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradTop, AppColors.gradMid, AppColors.gradBot],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

class CoinBadge extends StatelessWidget {
  final int coins;

  const CoinBadge(this.coins, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🪙', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text('$coins', style: AppTextStyles.coin),
      ],
    );
  }
}

class XpLevelBar extends StatelessWidget {
  final int level;
  final int xp;

  const XpLevelBar({super.key, required this.level, required this.xp});

  @override
  Widget build(BuildContext context) {
    final double progress = (xp % 100) / 100.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Lv.$level', style: AppTextStyles.caption),
        const SizedBox(width: 6),
        SizedBox(
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.accentLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }
}
