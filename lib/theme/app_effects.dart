import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

/// ──────────────────────────────────────────────────────────────
///  Fashion Room Girls — shared "juice" toolkit.
///
///  Pure-Flutter (no extra packages). Everything here is additive
///  polish: tap feedback, sparkles, shimmer, glow and floating
///  score popups. Drop it on top of existing widgets without
///  touching their logic.
/// ──────────────────────────────────────────────────────────────

/// Springy press feedback. Wrap any tappable widget so every tap
/// feels deliberate: the child dips on press and springs back, with
/// a light haptic tick.
class TapBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  final HitTestBehavior behavior;

  const TapBounce({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.92,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<TapBounce> createState() => _TapBounceState();
}

class _TapBounceState extends State<TapBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    lowerBound: 0,
    upperBound: 1,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(_) => _c.forward();
  void _up(_) => _c.reverse();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? _down : null,
      onTapUp: enabled ? _up : null,
      onTapCancel: enabled ? () => _c.reverse() : null,
      onTap: enabled
          ? () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap!.call();
            }
          : null,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.scale(
          scale: 1 - _c.value * (1 - widget.scale),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// A soft, breathing glow halo behind [child]. Great for the active
/// doll, the winner card, or a call-to-action.
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final double minBlur;
  final double maxBlur;
  final double spread;
  final bool enabled;

  /// When null the glow is circular; otherwise a rounded rectangle.
  final BorderRadius? borderRadius;

  const PulseGlow({
    super.key,
    required this.child,
    this.color = AppColors.primaryLight,
    this.minBlur = 8,
    this.maxBlur = 26,
    this.spread = 1,
    this.enabled = true,
    this.borderRadius,
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PulseGlow old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.enabled && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: widget.borderRadius == null
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: widget.color
                    .withValues(alpha: 0.30 + 0.35 * t),
                blurRadius: widget.minBlur +
                    (widget.maxBlur - widget.minBlur) * t,
                spreadRadius: widget.spread * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Sweeping highlight (the classic shimmer) painted over [child].
/// Use on headings, coin badges, "NEW" tags, loading skeletons.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Color highlight;
  final Duration period;
  final bool enabled;

  const Shimmer({
    super.key,
    required this.child,
    this.highlight = Colors.white,
    this.period = const Duration(milliseconds: 2200),
    this.enabled = true,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    // Defer the sweep until after the first frame to keep cold start light.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (_c.value * 2 - 0.5);
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                widget.highlight.withValues(alpha: 0.55),
                Colors.transparent,
              ],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(dx / bounds.width),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double fraction;
  const _SlideGradient(this.fraction);
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * fraction, 0, 0);
}

/// Ambient twinkling stars, meant to sit in a [Stack] over a
/// gradient background. Cheap: a fixed constellation that fades and
/// scales in and out on individual phases.
class AmbientSparkles extends StatefulWidget {
  final int count;
  final Color color;
  final double maxSize;

  const AmbientSparkles({
    super.key,
    this.count = 22,
    this.color = Colors.white,
    this.maxSize = 14,
  });

  @override
  State<AmbientSparkles> createState() => _AmbientSparklesState();
}

class _AmbientSparklesState extends State<AmbientSparkles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    _stars = List.generate(widget.count, (_) {
      return _Star(
        pos: Offset(rnd.nextDouble(), rnd.nextDouble()),
        phase: rnd.nextDouble(),
        size: 0.4 + rnd.nextDouble() * 0.6,
        speed: 0.6 + rnd.nextDouble() * 0.8,
      );
    });
    // Start looping only after the first frame, so the ambient layer
    // doesn't add work to cold-start paint.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            isComplex: true,
            willChange: true,
            painter: _SparklePainter(
              stars: _stars,
              t: _c.value,
              color: widget.color,
              maxSize: widget.maxSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _Star {
  final Offset pos; // normalized 0..1
  final double phase;
  final double size; // 0..1 multiplier
  final double speed;
  const _Star({
    required this.pos,
    required this.phase,
    required this.size,
    required this.speed,
  });
}

class _SparklePainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  final Color color;
  final double maxSize;

  _SparklePainter({
    required this.stars,
    required this.t,
    required this.color,
    required this.maxSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final phased = (t * s.speed + s.phase) % 1.0;
      // twinkle: 0 -> 1 -> 0
      final tw = math.sin(phased * math.pi);
      if (tw <= 0.02) continue;
      final center = Offset(s.pos.dx * size.width, s.pos.dy * size.height);
      final r = maxSize * s.size * tw;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.85 * tw)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.22;
      // soft center
      canvas.drawCircle(
        center,
        r * 0.28,
        Paint()..color = color.withValues(alpha: 0.5 * tw),
      );
      // four rays
      canvas.drawLine(
          center.translate(0, -r), center.translate(0, r), paint);
      canvas.drawLine(
          center.translate(-r, 0), center.translate(r, 0), paint);
      final d = r * 0.5;
      final thin = Paint()
        ..color = color.withValues(alpha: 0.5 * tw)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.12;
      canvas.drawLine(
          center.translate(-d, -d), center.translate(d, d), thin);
      canvas.drawLine(
          center.translate(d, -d), center.translate(-d, d), thin);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.t != t;
}

/// A one-shot radial burst of sparkles. Build it with a fresh [key]
/// (e.g. a counter) to replay. Fires once then fades.
class SparkleBurst extends StatefulWidget {
  final int particles;
  final Color color;
  final double radius;
  final Duration duration;

  const SparkleBurst({
    super.key,
    this.particles = 14,
    this.color = AppColors.coinGold,
    this.radius = 90,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends State<SparkleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)..forward();
  late final List<double> _angles;
  late final List<double> _dist;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _angles = List.generate(
        widget.particles, (i) => rnd.nextDouble() * math.pi * 2);
    _dist = List.generate(
        widget.particles, (i) => 0.5 + rnd.nextDouble() * 0.5);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.radius * 2),
          painter: _BurstPainter(
            t: Curves.easeOut.transform(_c.value),
            angles: _angles,
            dist: _dist,
            color: widget.color,
            radius: widget.radius,
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double t;
  final List<double> angles;
  final List<double> dist;
  final Color color;
  final double radius;

  _BurstPainter({
    required this.t,
    required this.angles,
    required this.dist,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final alpha = (1 - t).clamp(0.0, 1.0);
    for (var i = 0; i < angles.length; i++) {
      final d = radius * dist[i] * t;
      final p = center +
          Offset(math.cos(angles[i]) * d, math.sin(angles[i]) * d);
      final r = (4 + 4 * dist[i]) * (1 - t * 0.4);
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.4;
      canvas.drawLine(p.translate(0, -r), p.translate(0, r), paint);
      canvas.drawLine(p.translate(-r, 0), p.translate(r, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}

/// Entrance animation: fade + slide-up + slight scale, after an
/// optional [delay]. Use to stagger cards (voting grid, podium) so
/// content reveals with rhythm instead of popping in flat.
class RevealIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slide;

  const RevealIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.slide = 26,
  });

  @override
  State<RevealIn> createState() => _RevealInState();
}

class _RevealInState extends State<RevealIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.slide * (1 - t)),
            child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Floating "+50xp" / "+100🪙" / "⭐" popups that rise and fade.
/// Anchored to an overlay so they float above everything.
void showFloatingReward(
  BuildContext context, {
  required String text,
  Color color = AppColors.primaryDark,
  Offset? from,
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  final box = context.findRenderObject();
  Offset start = from ?? const Offset(0, 0);
  if (from == null && box is RenderBox && box.hasSize) {
    final topLeft = box.localToGlobal(Offset.zero);
    start = topLeft + Offset(box.size.width / 2, box.size.height / 2);
  }

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FloatingReward(
      text: text,
      color: color,
      origin: start,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _FloatingReward extends StatefulWidget {
  final String text;
  final Color color;
  final Offset origin;
  final VoidCallback onDone;

  const _FloatingReward({
    required this.text,
    required this.color,
    required this.origin,
    required this.onDone,
  });

  @override
  State<_FloatingReward> createState() => _FloatingRewardState();
}

class _FloatingRewardState extends State<_FloatingReward>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final rise = 56 * Curves.easeOut.transform(t);
        final scale = t < 0.25
            ? Curves.easeOutBack.transform(t / 0.25)
            : 1.0;
        final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
        return Positioned(
          left: widget.origin.dx - 80,
          top: widget.origin.dy - 20 - rise,
          width: 160,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
