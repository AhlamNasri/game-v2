import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/character_provider.dart';
import '../../data/models/character_customization.dart';
import '../../data/repositories/fashion_catalog.dart';
import '../widgets/character_preview.dart';
import '../widgets/section_title.dart';

class CharacterSelectionScreen extends ConsumerWidget {
  const CharacterSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = ref.watch(characterProvider);
    final controller = ref.read(characterProvider.notifier);
    final screenSize = MediaQuery.sizeOf(context);
    final isWide = screenSize.width >= 760;

    return Scaffold(
      backgroundColor: const Color(0xFFFFEEF7),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomSpace = isWide ? 88.0 : 0.0;
          final useTwoColumns = isWide && constraints.maxWidth >= 700;
          final isCompactHeight = constraints.maxHeight < 560;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFEFF7),
                  Color(0xFFF7E8FF),
                  Color(0xFFEAF7FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  const Positioned(
                    top: 26,
                    right: 42,
                    child: _SoftCircle(size: 170, color: Color(0x3ED778C8)),
                  ),
                  const Positioned(
                    left: 20,
                    bottom: 52,
                    child: _SoftCircle(size: 120, color: Color(0x34E95D8C)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: useTwoColumns
                        ? Row(
                            children: [
                              Expanded(
                                flex: 9,
                                child: SingleChildScrollView(
                                  child: _PreviewPanel(
                                    character: character,
                                    maxHeight: constraints.maxHeight -
                                        bottomSpace -
                                        (isCompactHeight ? 36.0 : 0.0),
                                    compact: isCompactHeight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 28),
                              Expanded(
                                flex: 10,
                                child: SingleChildScrollView(
                                  child: _OptionsPanel(
                                    character: character,
                                    controller: controller,
                                    compact: isCompactHeight,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            children: [
                              _PreviewPanel(
                                character: character,
                                maxHeight: 500,
                                compact: isCompactHeight,
                              ),
                              const SizedBox(height: 20),
                              _OptionsPanel(
                                character: character,
                                controller: controller,
                                compact: isCompactHeight,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: FilledButton.icon(
            onPressed: () => context.go('/dressing'),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Commencer'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: const Color(0xFFE95D8C),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  final CharacterCustomization character;
  final double maxHeight;
  final bool compact;

  const _PreviewPanel({
    required this.character,
    required this.maxHeight,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final panelHeight = (maxHeight - (compact ? 58 : 84))
        .clamp(compact ? 260.0 : 340.0, compact ? 390.0 : 520.0)
        .toDouble();
    final previewWidth = (panelHeight * 0.78)
        .clamp(compact ? 195.0 : 245.0, compact ? 300.0 : 360.0)
        .toDouble();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: () => context.go('/menu'),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Menu',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.76),
                foregroundColor: const Color(0xFF8A2D70),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cree ton personnage',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF4F355B),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(width: 58),
          ],
        ),
        const SizedBox(height: 18),
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 20,
            compact ? 12 : 18,
            compact ? 14 : 20,
            compact ? 14 : 22,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.92),
                const Color(0xFFFFDDEC).withOpacity(0.72),
                const Color(0xFFEBD7FF).withOpacity(0.58),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.86)),
            boxShadow: [
              BoxShadow(
                blurRadius: 34,
                color: const Color(0xFFB94B93).withOpacity(0.18),
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            children: [
              CharacterPreview(
                character: character,
                width: previewWidth,
                height: panelHeight - (compact ? 34 : 48),
              ),
              const SizedBox(height: 8),
              Container(
                width: previewWidth * 0.58,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF8F4D78).withOpacity(0.13),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionsPanel extends StatelessWidget {
  final CharacterCustomization character;
  final CharacterController controller;
  final bool compact;

  const _OptionsPanel({
    required this.character,
    required this.controller,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final genderName = character.gender.name;
    final hairOptions = FashionCatalog.hairOptionsFor(
      genderName,
      character.skinTone,
    );
    final faceOptions = FashionCatalog.faceOptionsFor(genderName);

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.64),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.78)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionTitle('Genre'),
          SizedBox(height: compact ? 8 : 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ChoiceButton(
                label: 'Fille',
                icon: Icons.face_3_rounded,
                selected: character.gender == CharacterGender.girl,
                onTap: () => controller.updateGender(CharacterGender.girl),
              ),
              _ChoiceButton(
                label: 'Garcon',
                icon: Icons.face_rounded,
                selected: character.gender == CharacterGender.boy,
                onTap: () => controller.updateGender(CharacterGender.boy),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 22),
          const SectionTitle('Couleur de peau'),
          _AssetChoices(
            options: FashionCatalog.skinTones,
            selectedValue: character.skinTone,
            onSelected: (option) => controller.updateSkinTone(option.value),
            compact: compact,
          ),
          if (hairOptions.isNotEmpty) ...[
            SizedBox(height: compact ? 12 : 18),
            const SectionTitle('Cheveux'),
            _AssetChoices(
              options: hairOptions,
              selectedValue: character.hairStyle,
              onSelected: (option) => controller.updateHair(option.value),
              compact: compact,
            ),
          ],
          if (faceOptions.isNotEmpty) ...[
            SizedBox(height: compact ? 12 : 18),
            const SectionTitle('Visage'),
            _AssetChoices(
              options: faceOptions,
              selectedValue: character.faceAsset,
              onSelected: (option) => controller.updateFace(option.value),
              compact: compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 20),
      label: Text(label),
      selectedColor: const Color(0xFFFFD7E8),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFFE95D8C) : Colors.pink.shade100,
        width: selected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w800,
        color: selected ? const Color(0xFF9C1D67) : const Color(0xFF5C405F),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

class _AssetChoices extends StatelessWidget {
  final List<CharacterOption> options;
  final String selectedValue;
  final ValueChanged<CharacterOption> onSelected;
  final bool compact;

  const _AssetChoices({
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 98 : 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final option = options[index];
          final selected = option.value == selectedValue;

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onSelected(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: compact ? 88 : 100,
              padding: EdgeInsets.all(compact ? 6 : 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFFEDF5) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      selected ? const Color(0xFFE91E8F) : const Color(0xFFFFB4CB),
                  width: selected ? 2 : 1,
                ),
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      blurRadius: 14,
                      color: const Color(0xFFE91E8F).withOpacity(0.18),
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      option.assetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Text(
                    option.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? const Color(0xFF9C1D67)
                          : const Color(0xFF5C405F),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
