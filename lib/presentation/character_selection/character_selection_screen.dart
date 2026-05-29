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
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomSpace = isWide ? 88.0 : 0.0;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF3F6), Color(0xFFEAF7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: _PreviewPanel(
                              character: character,
                              maxHeight: constraints.maxHeight - bottomSpace,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _OptionsPanel(
                              character: character,
                              controller: controller,
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          _PreviewPanel(character: character, maxHeight: 430),
                          const SizedBox(height: 20),
                          _OptionsPanel(
                            character: character,
                            controller: controller,
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/dressing');
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Commencer'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: const Color(0xFFE95D8C),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
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

  const _PreviewPanel({
    required this.character,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final panelHeight = (maxHeight - 110).clamp(260.0, 430.0).toDouble();
    final previewWidth = (panelHeight * 0.7).clamp(190.0, 285.0).toDouble();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Crée ton personnage',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF4F355B),
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go('/menu'),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Menu'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF7E3565),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                blurRadius: 30,
                color: Color(0x22000000),
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: CharacterPreview(
              character: character,
              width: previewWidth,
              height: panelHeight - 36,
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionsPanel extends StatelessWidget {
  final CharacterCustomization character;
  final CharacterController controller;

  const _OptionsPanel({
    required this.character,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final genderName = character.gender.name;
    final hairOptions = FashionCatalog.hairOptionsFor(genderName);
    final faceOptions = FashionCatalog.faceOptionsFor(genderName);

    return ListView(
      shrinkWrap: true,
      children: [
        const SectionTitle('Genre'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ChoiceButton(
              label: 'Fille',
              icon: Icons.face_3_rounded,
              onTap: () => controller.updateGender(CharacterGender.girl),
            ),
            _ChoiceButton(
              label: 'Garçon',
              icon: Icons.face_rounded,
              onTap: () => controller.updateGender(CharacterGender.boy),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionTitle('Couleur de peau'),
        _AssetChoices(
          options: FashionCatalog.skinTones,
          onSelected: (option) => controller.updateSkinTone(option.value),
        ),
        if (hairOptions.isNotEmpty) ...[
          const SizedBox(height: 18),
          const SectionTitle('Cheveux'),
          _AssetChoices(
            options: hairOptions,
            onSelected: (option) => controller.updateHair(option.value),
          ),
        ],
        if (faceOptions.isNotEmpty) ...[
          const SizedBox(height: 18),
          const SectionTitle('Visage'),
          _AssetChoices(
            options: faceOptions,
            onSelected: (option) => controller.updateFace(option.value),
          ),
        ],
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 20),
      label: Text(label),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.pink.shade100),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}

class _AssetChoices extends StatelessWidget {
  final List<CharacterOption> options;
  final ValueChanged<CharacterOption> onSelected;

  const _AssetChoices({
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final option = options[index];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onSelected(option),
            child: Container(
              width: 92,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFB4CB)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(option.assetPath, fit: BoxFit.contain),
                  ),
                  Text(
                    option.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
