import 'package:flutter/material.dart';

import '../../../theme/app_effects.dart';

/// ──────────────────────────────────────────────────────────────
///  Y2K / kawaii visual kit for the dress-up experience.
///
///  Pure Flutter, built on top of the shared juice toolkit
///  (TapBounce / AmbientSparkles). Holographic gradients, sticker
///  buttons and glossy cards — the look that makes the closet feel
///  like a real dress-up game instead of a form.
/// ──────────────────────────────────────────────────────────────

class Y2kColors {
  static const pink = Color(0xFFFF7FC4);
  static const purple = Color(0xFFB388FF);
  static const blue = Color(0xFF7FD1FF);
  static const mint = Color(0xFF9DF7DA);
  static const lemon = Color(0xFFFFF1A6);
  static const ink = Color(0xFF54214B);
  static const inkSoft = Color(0xFF9B5E80);
  static const cream = Color(0xFFFFF6FC);

  /// The signature holographic sweep used for borders and accents.
  static const holo = [pink, purple, blue, mint];

  /// Soft page wash behind everything.
  static const pageWash = [
    Color(0xFFFFE3F4),
    Color(0xFFEAD9FF),
    Color(0xFFDAF1FF),
    Color(0xFFFFF7DC),
  ];
}

/// Full-screen holographic backdrop with floating sparkles and two soft
/// colour blobs. Drop any [child] on top.
class Y2kBackground extends StatelessWidget {
  final Widget child;
  final bool sparkles;

  const Y2kBackground({super.key, required this.child, this.sparkles = true});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: Y2kColors.pageWash,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -60,
            left: -50,
            child: _Blob(size: 220, color: Color(0x55FF9FDD)),
          ),
          const Positioned(
            bottom: -70,
            right: -40,
            child: _Blob(size: 260, color: Color(0x4F8FD0FF)),
          ),
          if (sparkles)
            const Positioned.fill(
              child: AmbientSparkles(count: 18, color: Colors.white),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// A glossy card with a holographic gradient hairline border. The signature
/// surface for the doll stage and wardrobe drawer.
class HoloCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color fill;

  const HoloCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 26,
    this.fill = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          colors: Y2kColors.holo,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Y2kColors.purple.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius - 2.5),
        ),
        child: child,
      ),
    );
  }
}

/// Chunky rounded "sticker" button — white outline, drop shadow, springy tap.
/// Use for primary actions and toolbar buttons.
class StickerButton extends StatelessWidget {
  final String? label;
  final String? emoji;
  final IconData? icon;
  final VoidCallback? onTap;
  final List<Color> colors;
  final Color textColor;
  final bool isLoading;
  final EdgeInsetsGeometry padding;

  const StickerButton({
    super.key,
    this.label,
    this.emoji,
    this.icon,
    required this.onTap,
    this.colors = const [Y2kColors.pink, Y2kColors.purple],
    this.textColor = Colors.white,
    this.isLoading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (emoji != null) ...[
                    Text(emoji!, style: const TextStyle(fontSize: 16)),
                    if (label != null) const SizedBox(width: 6),
                  ],
                  if (icon != null) ...[
                    Icon(icon, color: textColor, size: 18),
                    if (label != null) const SizedBox(width: 6),
                  ],
                  if (label != null)
                    Text(
                      label!,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// A circular sticker icon button for compact toolbars (back, reset…).
class StickerIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final String? tooltip;

  const StickerIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = TapBounce(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Y2kColors.purple.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Y2kColors.ink, size: 21),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// A glossy translucent pill — used to wrap the live coin badge etc.
class HoloPill extends StatelessWidget {
  final Widget child;
  const HoloPill({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Y2kColors.pink.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
