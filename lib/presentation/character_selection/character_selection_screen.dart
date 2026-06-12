import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../application/character_provider.dart';
import '../../data/models/character_customization.dart';
import '../../data/repositories/character_repository.dart';
import '../../data/repositories/fashion_catalog.dart';
import '../../data/models/clothing_item.dart';
import '../../theme/app_effects.dart';
import '../../theme/app_theme.dart';
import '../dressing/widgets/dressup_widgets.dart';
import '../dressing/widgets/interactive_doll_view.dart';
import '../widgets/character_preview.dart';

/// First-run character creator — pick body, skin tone and hair, then save.
/// Same Y2K/kawaii language as the dress-up studio.
class CharacterSelectionScreen extends ConsumerStatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  ConsumerState<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState
    extends ConsumerState<CharacterSelectionScreen> {
  bool _isSaving = false;
  ClothingCategory _selectedCategory = ClothingCategory.hair;

  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);
    try {
      await CharacterRepository().save(ref.read(characterProvider));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('character_saved', 'true');
      if (mounted) context.go('/menu');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final character = ref.watch(characterProvider);
    final controller = ref.read(characterProvider.notifier);

    return Scaffold(
      body: Y2kBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Doll preview ──
                Expanded(
                  flex: 5,
                  child: HoloCard(
                    padding: const EdgeInsets.all(12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: const Alignment(0, 0.9),
                          child: Container(
                            width: 150,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Y2kColors.purple.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        PulseGlow(
                          color: Y2kColors.pink,
                          borderRadius: BorderRadius.circular(20),
                          child: InteractiveDollView(
                            width: 230,
                            selectedCategory: _selectedCategory,
                            onCategorySelected: (c) =>
                                setState(() => _selectedCategory = c),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: StickerIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Menu',
                            onTap: () => context.go('/menu'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // ── Options ──
                Expanded(
                  flex: 6,
                  child: HoloCard(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Shimmer(
                          child: Text(
                            'Create Your Character',
                            style: AppTextStyles.heading.copyWith(
                              color: Y2kColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              const _Label('Body'),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ChoiceSticker(
                                      label: 'Girl',
                                      emoji: '👧',
                                      selected: character.gender ==
                                          CharacterGender.girl,
                                      onTap: () => controller
                                          .updateGender(CharacterGender.girl),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _ChoiceSticker(
                                      label: 'Boy',
                                      emoji: '👦',
                                      selected: character.gender ==
                                          CharacterGender.boy,
                                      onTap: () => controller
                                          .updateGender(CharacterGender.boy),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const _Label('Skin Tone'),
                              _PreviewChoices(
                                options: FashionCatalog.skinTones,
                                isSelected: (o) => o.value == character.skinTone,
                                previewFor: (o) => character.copyWith(
                                  skinTone: o.value,
                                  outfit: {},
                                ),
                                onTap: (o) => controller.updateSkinTone(o.value),
                              ),
                              const SizedBox(height: 14),
                              const _Label('Hair'),
                              _PreviewChoices(
                                options: FashionCatalog.hairOptionsFor(
                                    character.gender.name),
                                isSelected: (o) =>
                                    o.value == character.hairStyle,
                                previewFor: (o) => character.copyWith(
                                  hairAsset: o.value,
                                  outfit: {},
                                ),
                                onTap: (o) => controller.updateHair(o.value),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: StickerButton(
                              label: 'Confirm & Save',
                              isLoading: _isSaving,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 26, vertical: 15),
                              onTap: _saveAndContinue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.subheading.copyWith(
          color: Y2kColors.ink,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ChoiceSticker extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceSticker({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [Y2kColors.pink, Y2kColors.purple])
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: (selected ? Y2kColors.pink : Y2kColors.purple)
                  .withValues(alpha: selected ? 0.4 : 0.15),
              blurRadius: selected ? 14 : 7,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: selected ? Colors.white : Y2kColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal strip of doll-preview thumbnails (skin / hair choices).
class _PreviewChoices extends StatelessWidget {
  final List<CharacterOption> options;
  final bool Function(CharacterOption) isSelected;
  final CharacterCustomization Function(CharacterOption) previewFor;
  final ValueChanged<CharacterOption> onTap;

  const _PreviewChoices({
    required this.options,
    required this.isSelected,
    required this.previewFor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final option = options[i];
          final selected = isSelected(option);
          return TapBounce(
            onTap: () => onTap(option),
            child: Container(
              width: 84,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFFFFE6F6), Color(0xFFF1E6FF)],
                      )
                    : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? Y2kColors.pink : const Color(0xFFF0E4F0),
                  width: selected ? 2.5 : 1.5,
                ),
              ),
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.62,
                  child: CharacterPreview(
                    character: previewFor(option),
                    width: 72,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
