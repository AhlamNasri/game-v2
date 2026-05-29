import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/character_provider.dart';
import '../dressing/dressing_screen.dart';
import '../widgets/character_preview.dart';

class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  final _characterCaptureKey = GlobalKey();

  Future<void> _captureCharacter() async {
    final boundary = _characterCaptureKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      return;
    }

    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data?.buffer.asUint8List();
    if (!mounted || bytes == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => _CaptureDialog(bytes: bytes),
    );
  }

  void _applyStyle() {
    ref.read(characterProvider.notifier).applyBestStyle();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Look style applique.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final character = ref.watch(characterProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'room_assets/room_bg.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.pink.withOpacity(0.14),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final navHeight = isWide ? 76.0 : 70.0;
                  final headerHeight = isWide ? 64.0 : 58.0;
                  final previewHeight =
                      (constraints.maxHeight - navHeight - headerHeight - 26)
                          .clamp(250.0, isWide ? 455.0 : 360.0)
                          .toDouble();
                  final previewWidth = (previewHeight * 0.72)
                      .clamp(185.0, isWide ? 320.0 : 255.0)
                      .toDouble();

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ma chambre',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: const Color(0xFF4F355B),
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          _RoundIconButton(
                            icon: Icons.person_rounded,
                            label: 'Personnage',
                            onTap: () {
                              Navigator.of(context)
                                  .pushReplacementNamed('/character');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              CharacterPreview(
                                character: character,
                                width: previewWidth,
                                height: previewHeight,
                                repaintKey: _characterCaptureKey,
                              ),
                              Positioned(
                                right: -8,
                                top: previewHeight * 0.28,
                                child: _FloatingActionPill(
                                  icon: Icons.auto_awesome_rounded,
                                  label: 'Style',
                                  onTap: _applyStyle,
                                ),
                              ),
                              Positioned(
                                left: -8,
                                top: previewHeight * 0.42,
                                child: _FloatingActionPill(
                                  icon: Icons.photo_camera_rounded,
                                  label: 'Photo',
                                  onTap: _captureCharacter,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _NavigationBar(
                        height: navHeight,
                        onDress: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DressingScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  final double height;
  final VoidCallback onDress;

  const _NavigationBar({
    required this.height,
    required this.onDress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.86),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              blurRadius: 24,
              color: Color(0x26000000),
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: _NavButton(
            icon: Icons.checkroom_rounded,
            label: 'Habiller',
            onTap: onDress,
          ),
        ),
      ),
    );
  }
}

class _FloatingActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FloatingActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF7FA),
      elevation: 8,
      shadowColor: const Color(0x22000000),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFFE95D8C), size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF4F355B),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureDialog extends StatelessWidget {
  final Uint8List bytes;

  const _CaptureDialog({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(22),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Photo du personnage',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Fermer',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFE95D8C)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF4F355B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton.filledTonal(
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
  }
}
