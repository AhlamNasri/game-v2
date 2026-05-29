import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:fashion_room_girls/data/services/soundtrack_service.dart';
import 'package:fashion_room_girls/presentation/room_design/theme/room_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundtrack = ref.watch(soundtrackServiceProvider);

    return AnimatedBuilder(
      animation: soundtrack,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFEEF7),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'room_assets/room_bg.jpeg',
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.38),
                      const Color(0xFFFFC6DF).withValues(alpha: 0.52),
                      const Color(0xFF4C2449).withValues(alpha: 0.40),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _SettingsHeader(onBack: () => _goBack(context)),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  _SoundtrackPanel(service: soundtrack),
                                  const SizedBox(height: 12),
                                  _PreferencePanel(service: soundtrack),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/menu');
    }
  }
}

class _SettingsHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _SettingsHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RoomUi.softPanel.withValues(alpha: 0.96),
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Tooltip(
              message: 'Back',
              child: IconButton.filled(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: RoomUi.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.settings, color: RoomUi.accent),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Settings',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: RoomUi.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundtrackPanel extends StatelessWidget {
  final SoundtrackService service;

  const _SoundtrackPanel({required this.service});

  @override
  Widget build(BuildContext context) {
    final volumeLabel = '${(service.volume * 100).round()}%';

    return _SettingsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.music_note, color: RoomUi.accent),
            title: const Text(
              'Soundtrack',
              style: TextStyle(
                color: RoomUi.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              _statusText(service),
              style: const TextStyle(
                color: RoomUi.pillText,
                fontWeight: FontWeight.w700,
              ),
            ),
            value: service.musicEnabled,
            activeThumbColor: RoomUi.accent,
            onChanged: (value) => unawaited(service.setMusicEnabled(value)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.volume_down, color: RoomUi.pillText),
              Expanded(
                child: Slider(
                  value: service.volume,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  label: volumeLabel,
                  activeColor: RoomUi.accent,
                  inactiveColor: const Color(0xFFF3B7D3),
                  onChanged: (value) => unawaited(service.setVolume(value)),
                ),
              ),
              const Icon(Icons.volume_up, color: RoomUi.pillText),
              SizedBox(
                width: 48,
                child: Text(
                  volumeLabel,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: RoomUi.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AudioActionButton(
                icon: Icons.play_arrow,
                label: 'Play',
                onPressed: () => unawaited(service.play()),
              ),
              _AudioActionButton(
                icon: Icons.pause,
                label: 'Pause',
                onPressed: () => unawaited(service.pause()),
              ),
              _AudioActionButton(
                icon: Icons.stop,
                label: 'Stop',
                onPressed: () => unawaited(service.stop()),
              ),
            ],
          ),
          if (service.errorMessage != null) ...[
            const SizedBox(height: 12),
            _AudioNotice(message: service.errorMessage!),
          ],
        ],
      ),
    );
  }

  String _statusText(SoundtrackService service) {
    if (!service.musicEnabled) return 'Off';
    if (service.volume <= 0) return 'Muted';
    if (service.playerState == PlayerState.playing) return 'Playing';
    if (service.playerState == PlayerState.paused) return 'Paused';
    return 'Ready';
  }
}

class _PreferencePanel extends StatelessWidget {
  final SoundtrackService service;

  const _PreferencePanel({required this.service});

  @override
  Widget build(BuildContext context) {
    return _SettingsPanel(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: RoomUi.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.save, color: RoomUi.accent),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Audio preferences are saved on this device.',
              style: TextStyle(
                color: RoomUi.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(
            service.initialized ? Icons.check_circle : Icons.hourglass_bottom,
            color: service.initialized
                ? const Color(0xFF4B9E67)
                : const Color(0xFF8A5BE8),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final Widget child;

  const _SettingsPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RoomUi.softPanel.withValues(alpha: 0.96),
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF2A6CA), width: 1.5),
        ),
        child: child,
      ),
    );
  }
}

class _AudioActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _AudioActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: RoomUi.accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _AudioNotice extends StatelessWidget {
  final String message;

  const _AudioNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0A221)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF7B5B00), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF6B4F00),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
