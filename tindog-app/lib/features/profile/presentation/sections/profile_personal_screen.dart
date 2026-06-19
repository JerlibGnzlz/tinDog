import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/feedback/app_haptics.dart';
import '../../../../core/network/session_handler.dart';
import '../../../../shared/widgets/tindog_text_field.dart';
import '../../data/profile_repository.dart';
import '../profile_providers.dart';
import '../widgets/profile_section_scaffold.dart';

class ProfilePersonalScreen extends ConsumerStatefulWidget {
  const ProfilePersonalScreen({super.key});

  @override
  ConsumerState<ProfilePersonalScreen> createState() =>
      _ProfilePersonalScreenState();
}

class _ProfilePersonalScreenState extends ConsumerState<ProfilePersonalScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  bool _loading = true;
  String? _loadError;
  bool _saving = false;
  bool _saveSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await ref.read(profileRepositoryProvider).getMyProfile();
      _nameController.text = profile.name ?? '';
      _bioController.text = profile.bio ?? '';
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (isUnauthorizedError(e)) {
        if (mounted) handleSessionExpired(ref, context, e);
        return;
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = readableError(e);
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveSuccess = false;
    });
    try {
      await ref.read(profileRepositoryProvider).updateMyProfile(
            name: _nameController.text.trim(),
            bio: _bioController.text.trim(),
          );
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveSuccess = true;
      });
      AppHaptics.success();
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      showTindogSuccessSnackBar(context, 'Datos personales guardados');
      context.pop();
    } catch (e) {
      if (isUnauthorizedError(e)) {
        if (mounted) handleSessionExpired(ref, context, e);
        return;
      }
      if (mounted) {
        showTindogErrorSnackBar(context, readableError(e));
        setState(() {
          _saving = false;
          _saveSuccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSectionScaffold(
      title: 'Datos personales',
      loading: _loading,
      loadError: _loadError,
      onRetry: _loadData,
      saving: _saving,
      saveSuccess: _saveSuccess,
      onSave: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Contanos sobre vos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 16),
          TindogTextField(
            controller: _nameController,
            label: 'Tu nombre',
          ),
          const SizedBox(height: 16),
          TindogTextField(
            controller: _bioController,
            label: 'Bio',
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
