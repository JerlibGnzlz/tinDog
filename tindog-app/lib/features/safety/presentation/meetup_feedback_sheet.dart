import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_colors.dart';

enum MeetupFeedbackMood { great, ok, rough }

/// Feedback suave post-encuentro (sin estrellas públicas).
Future<void> showMeetupFeedbackSheet({
  required BuildContext context,
  required String otherPetName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _MeetupFeedbackBody(otherPetName: otherPetName),
  );
}

class _MeetupFeedbackBody extends ConsumerStatefulWidget {
  const _MeetupFeedbackBody({required this.otherPetName});

  final String otherPetName;

  @override
  ConsumerState<_MeetupFeedbackBody> createState() =>
      _MeetupFeedbackBodyState();
}

class _MeetupFeedbackBodyState extends ConsumerState<_MeetupFeedbackBody> {
  MeetupFeedbackMood? _mood;
  final _note = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_mood == null || _sending) return;
    setState(() => _sending = true);
    // MVP: feedback local; API de reviews llega en un módulo futuro.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    Navigator.pop(context);
    showTindogSuccessSnackBar(
      context,
      'Gracias. Tu opinión nos ayuda a cuidar la comunidad.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomSafe = media.padding.bottom;
    final keyboard = media.viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomSafe),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                '¿Cómo fue el encuentro con ${widget.otherPetName}?',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Solo para mejorar tinDog. No se publica en el perfil.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.35,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MoodChip(
                      label: 'Genial',
                      emoji: '👍',
                      selected: _mood == MeetupFeedbackMood.great,
                      onTap: () =>
                          setState(() => _mood = MeetupFeedbackMood.great),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MoodChip(
                      label: 'Bien',
                      emoji: '🙂',
                      selected: _mood == MeetupFeedbackMood.ok,
                      onTap: () =>
                          setState(() => _mood = MeetupFeedbackMood.ok),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MoodChip(
                      label: 'Regular',
                      emoji: '👎',
                      selected: _mood == MeetupFeedbackMood.rough,
                      onTap: () =>
                          setState(() => _mood = MeetupFeedbackMood.rough),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _note,
                maxLines: 3,
                maxLength: 280,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Opcional: ¿algo que debamos saber?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _mood == null || _sending ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(_sending ? 'Enviando…' : 'Enviar'),
              ),
              TextButton(
                onPressed: _sending ? null : () => Navigator.pop(context),
                child: const Text('Ahora no'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.2)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.55)
                  : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
