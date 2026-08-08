import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../data/safety_repository.dart';

enum SafetyActionKind { reported, blocked, reportedAndBlocked }

class SafetyActionResult {
  const SafetyActionResult(this.kind);
  final SafetyActionKind kind;

  bool get removedFromChats =>
      kind == SafetyActionKind.blocked ||
      kind == SafetyActionKind.reportedAndBlocked;
}

/// Sheet de seguridad desde un chat/match concreto.
Future<SafetyActionResult?> showSafetyActionsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String otherUserId,
  required String otherName,
  String? matchId,
}) {
  return showModalBottomSheet<SafetyActionResult>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Seguridad · $otherName',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.flag_outlined,
                  color: AppColors.primaryDark,
                ),
                title: const Text(
                  'Reportar',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Avisanos si hay un problema',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  final result = await showReportUserSheet(
                    context: sheetContext,
                    ref: ref,
                    otherUserId: otherUserId,
                    otherName: otherName,
                    matchId: matchId,
                  );
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext, result);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.block, color: Colors.red.shade700),
                title: Text(
                  'Bloquear',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                subtitle: const Text(
                  'No te verán ni podrán escribirte',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  final result = await _confirmAndBlock(
                    context: sheetContext,
                    ref: ref,
                    otherUserId: otherUserId,
                    otherName: otherName,
                  );
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext, result);
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<SafetyActionResult?> showReportUserSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String otherUserId,
  required String otherName,
  String? matchId,
}) {
  return showModalBottomSheet<SafetyActionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _ReportSheet(
        otherUserId: otherUserId,
        otherName: otherName,
        matchId: matchId,
      );
    },
  );
}

Future<SafetyActionResult?> _confirmAndBlock({
  required BuildContext context,
  required WidgetRef ref,
  required String otherUserId,
  required String otherName,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('¿Bloquear?'),
        content: Text(
          'Vas a dejar de ver a $otherName en Desliza, Likes y Chats. '
          'El match y el chat se eliminan.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bloquear'),
          ),
        ],
      );
    },
  );
  if (ok != true || !context.mounted) return null;

  try {
    await ref.read(safetyRepositoryProvider).blockUser(otherUserId);
    if (!context.mounted) return null;
    showTindogInfoSnackBar(context, '$otherName bloqueado');
    return const SafetyActionResult(SafetyActionKind.blocked);
  } catch (e) {
    if (!context.mounted) return null;
    if (isSessionError(e)) {
      handleSessionExpired(ref, context, e);
      return null;
    }
    showTindogErrorSnackBar(context, readableError(e));
    return null;
  }
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({
    required this.otherUserId,
    required this.otherName,
    this.matchId,
  });

  final String otherUserId;
  final String otherName;
  final String? matchId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  ReportReason _reason = ReportReason.spam;
  bool _blockAlso = true;
  bool _submitting = false;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(safetyRepositoryProvider).reportUser(
            userId: widget.otherUserId,
            reason: _reason,
            details: _details.text,
            matchId: widget.matchId,
            blockAlso: _blockAlso,
          );
      if (!mounted) return;
      showTindogInfoSnackBar(
        context,
        _blockAlso
            ? 'Reporte enviado y usuario bloqueado'
            : 'Reporte enviado. Gracias.',
      );
      Navigator.pop(
        context,
        SafetyActionResult(
          _blockAlso
              ? SafetyActionKind.reportedAndBlocked
              : SafetyActionKind.reported,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (isSessionError(e)) {
        handleSessionExpired(ref, context, e);
        return;
      }
      showTindogErrorSnackBar(context, readableError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text(
            'Reportar a ${widget.otherName}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 12),
          for (final reason in ReportReason.values)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _reason == reason
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: _reason == reason
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
              ),
              title: Text(
                reason.label,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: _submitting
                  ? null
                  : () => setState(() => _reason = reason),
            ),
          TextField(
            controller: _details,
            maxLines: 2,
            maxLength: 500,
            enabled: !_submitting,
            decoration: const InputDecoration(
              hintText: 'Detalle opcional',
              border: OutlineInputBorder(),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'También bloquear',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: const Text(
              'Recomendado',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            value: _blockAlso,
            activeThumbColor: AppColors.primary,
            onChanged: _submitting
                ? null
                : (v) => setState(() => _blockAlso = v),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Enviar reporte'),
          ),
        ],
      ),
    );
  }
}

/// Info breve desde el escudo de la lista de Chats (sin usuario concreto).
Future<void> showSafetyInfoSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const Text(
                'Tu seguridad en tinDog',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'En cualquier chat podés reportar o bloquear a la otra persona. '
                'Al bloquear, desaparece de Desliza, Likes y Chats, y el chat '
                'se elimina por completo.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
