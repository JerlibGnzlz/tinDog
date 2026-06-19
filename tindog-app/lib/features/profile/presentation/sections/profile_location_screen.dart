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

class ProfileLocationScreen extends ConsumerStatefulWidget {
  const ProfileLocationScreen({super.key});

  @override
  ConsumerState<ProfileLocationScreen> createState() =>
      _ProfileLocationScreenState();
}

class _ProfileLocationScreenState extends ConsumerState<ProfileLocationScreen> {
  final _locationController = TextEditingController();

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
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await ref.read(profileRepositoryProvider).getMyProfile();
      _locationController.text = profile.location ?? '';
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
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá tu ubicación')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _saveSuccess = false;
    });
    try {
      await ref.read(profileRepositoryProvider).updateMyProfile(
            location: location,
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
      showTindogSuccessSnackBar(context, 'Ubicación guardada');
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
      title: 'Ubicación',
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
            '¿Dónde estás?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 16),
          TindogTextField(
            controller: _locationController,
            label: 'Ciudad o barrio',
          ),
        ],
      ),
    );
  }
}
