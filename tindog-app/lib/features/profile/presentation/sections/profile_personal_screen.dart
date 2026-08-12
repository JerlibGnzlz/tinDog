import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/feedback/app_haptics.dart';
import '../../../../core/network/session_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/google_logo.dart';
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
  final _emailController = TextEditingController();

  bool _loading = true;
  String? _loadError;
  bool _saving = false;
  bool _saveSuccess = false;
  String? _avatarUrl;
  bool _googleLinked = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
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
      _emailController.text = profile.email ?? '';
      _avatarUrl = profile.avatarUrl;
      _googleLinked = profile.googleLinked;
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
            'Así te ven otros dueños. La mascota se edita en Datos caninos.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary.withValues(alpha: 0.18),
              backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(_avatarUrl!)
                  : null,
              child: _avatarUrl == null || _avatarUrl!.isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      size: 44,
                      color: AppColors.primaryDark,
                    )
                  : null,
            ),
          ),
          if (_googleLinked) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GoogleLogo(size: 16),
                const SizedBox(width: 8),
                Text(
                  'Conectado con Google',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          TindogTextField(
            controller: _emailController,
            label: 'Email',
            enabled: false,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TindogTextField(
            controller: _nameController,
            label: 'Tu nombre',
          ),
          const SizedBox(height: 16),
          TindogTextField(
            controller: _bioController,
            label: 'Sobre vos',
            hintText: 'Ej. Trabajo remoto, salimos a pasear por Palermo…',
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
