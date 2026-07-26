import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_quest/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/character_creation_controller.dart';
import '../widgets/class_picker.dart';

/// Flagship character-creation flow: name, avatar picker, and class selection
/// with a live gradient preview. On success it flips auth status to
/// authenticated and the router lands the user on the dashboard.
class CharacterCreationScreen extends ConsumerStatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  ConsumerState<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends ConsumerState<CharacterCreationScreen> {
  final _nameController = TextEditingController();

  static const _avatars = [
    'avatar_01', 'avatar_02', 'avatar_03', 'avatar_04', 'avatar_05', 'avatar_06',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref.read(characterCreationControllerProvider.notifier).submit();
    if (ok && mounted) {
      // Flip global auth status; router redirect handles navigation.
      ref.read(authControllerProvider.notifier).markCharacterCreated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(characterCreationControllerProvider);
    final controller = ref.read(characterCreationControllerProvider.notifier);
    final selectedClass = state.selectedClass;

    ref.listen<CharacterCreationState>(characterCreationControllerProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!.message)));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Live hero preview ────────────────────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.all(AppSpacing.lg),
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      decoration: BoxDecoration(
                        gradient: selectedClass.gradient,
                        borderRadius: AppRadius.rXl,
                        boxShadow: [
                          BoxShadow(
                            color: selectedClass.color.withValues(alpha: 0.4),
                            blurRadius: 32,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 96,
                            width: 96,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white70, width: 2),
                            ),
                            child: Icon(selectedClass.icon, size: 52, color: Colors.white),
                          ),
                          AppSpacing.vMd,
                          Text(
                            state.name.trim().isEmpty ? l10n.heroPreviewName : state.name.trim(),
                            style: text.headlineLarge?.copyWith(color: Colors.white),
                          ),
                          Text(
                            '${selectedClass.label} • ${selectedClass.tagline}',
                            style: text.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    // ── Name ─────────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.heroName, style: text.titleMedium),
                          AppSpacing.vSm,
                          TextField(
                            controller: _nameController,
                            maxLength: 20,
                            textCapitalization: TextCapitalization.words,
                            onChanged: controller.setName,
                            decoration: InputDecoration(
                              hintText: l10n.heroNameHint,
                              prefixIcon: const Icon(Icons.badge_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Avatar ───────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.sm, AppSpacing.xxl, AppSpacing.md),
                      child: Text(l10n.chooseAvatar, style: text.titleMedium),
                    ),
                    SizedBox(
                      height: 76,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                        itemCount: _avatars.length,
                        separatorBuilder: (_, __) => AppSpacing.hMd,
                        itemBuilder: (context, i) {
                          final key = _avatars[i];
                          final selected = key == state.avatarKey;
                          return GestureDetector(
                            onTap: () => controller.selectAvatar(key),
                            child: Container(
                              height: 64,
                              width: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.surface,
                                border: Border.all(
                                  color: selected ? AppColors.accent : Theme.of(context).colorScheme.outline,
                                  width: selected ? 2.4 : 1.2,
                                ),
                              ),
                              child: Icon(
                                Icons.face_retouching_natural_rounded,
                                color: selected ? AppColors.accent : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Class ────────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxl, AppSpacing.md),
                      child: Text(l10n.chooseClass, style: text.titleMedium),
                    ),
                    ClassPicker(
                      selected: selectedClass,
                      onSelected: controller.selectClass,
                    ),
                    AppSpacing.vXl,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: PrimaryButton(
                label: l10n.beginJourney,
                icon: Icons.auto_awesome_rounded,
                isLoading: state.isSubmitting,
                onPressed: state.canSubmit ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
