import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/quest.dart';
import '../../domain/entities/quest_enums.dart';
import '../providers/quests_controller.dart';

/// Create / edit bottom sheet for a quest. Bound to [QuestsController] for
/// persistence. Reward numbers are derived server-side from difficulty.
class QuestEditSheet extends ConsumerStatefulWidget {
  const QuestEditSheet({super.key, this.existing});
  final Quest? existing;

  static Future<void> show(BuildContext context, {Quest? existing}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: QuestEditSheet(existing: existing),
        ),
      );

  @override
  ConsumerState<QuestEditSheet> createState() => _QuestEditSheetState();
}

class _QuestEditSheetState extends ConsumerState<QuestEditSheet> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late QuestCadence _cadence;
  late QuestDifficulty _difficulty;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    _title = TextEditingController(text: q?.title ?? '');
    _desc = TextEditingController(text: q?.description ?? '');
    _cadence = q?.cadence ?? QuestCadence.daily;
    _difficulty = q?.difficulty ?? QuestDifficulty.medium;
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final draft = QuestDraft(
      id: widget.existing?.id,
      title: _title.text,
      description: _desc.text,
      cadence: _cadence,
      difficulty: _difficulty,
    );
    final controller = ref.read(questsControllerProvider.notifier);
    try {
      if (draft.isEditing) {
        await controller.saveQuest(draft);
      } else {
        await controller.create(draft);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.existing == null ? 'New quest' : 'Edit quest', style: text.headlineMedium),
          AppSpacing.vXl,
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. 30 minutes of deep work',
            ),
          ),
          AppSpacing.vLg,
          TextField(
            controller: _desc,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          AppSpacing.vXl,
          Text('Cadence', style: text.titleSmall),
          AppSpacing.vSm,
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final c in QuestCadence.values)
                ChoiceChip(
                  label: Text(c.label),
                  selected: _cadence == c,
                  onSelected: (_) => setState(() => _cadence = c),
                ),
            ],
          ),
          AppSpacing.vLg,
          Text('Difficulty', style: text.titleSmall),
          AppSpacing.vSm,
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final d in QuestDifficulty.values)
                ChoiceChip(
                  label: Text(d.label),
                  selected: _difficulty == d,
                  selectedColor: d.color.withValues(alpha: 0.25),
                  onSelected: (_) => setState(() => _difficulty = d),
                ),
            ],
          ),
          AppSpacing.vXxl,
          PrimaryButton(
            label: widget.existing == null ? 'Create quest' : 'Save changes',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
