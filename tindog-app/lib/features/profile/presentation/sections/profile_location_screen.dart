import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/feedback/app_haptics.dart';
import '../../../../core/network/session_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/tindog_text_field.dart';
import '../../data/device_location.dart';
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
  bool _gpsBusy = false;
  bool _hasGps = false;

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
      if (mounted) {
        setState(() {
          _loading = false;
          _hasGps = profile.hasGps;
        });
      }
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

  Future<void> _useGps() async {
    setState(() => _gpsBusy = true);
    try {
      final coords = await DeviceLocation.getCurrent();
      await ref.read(profileRepositoryProvider).updateMyProfile(
            latitude: coords.latitude,
            longitude: coords.longitude,
            location: _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
          );
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      setState(() {
        _gpsBusy = false;
        _hasGps = true;
      });
      AppHaptics.success();
      showTindogSuccessSnackBar(
        context,
        'Ubicación GPS guardada. Ya podés usar Cerca.',
      );
    } on DeviceLocationException catch (e) {
      if (!mounted) return;
      setState(() => _gpsBusy = false);
      showTindogErrorSnackBar(context, e.message);
    } catch (e) {
      if (isUnauthorizedError(e)) {
        if (mounted) handleSessionExpired(ref, context, e);
        return;
      }
      if (mounted) {
        setState(() => _gpsBusy = false);
        showTindogErrorSnackBar(context, readableError(e));
      }
    }
  }

  Future<void> _save() async {
    final location = _locationController.text.trim();
    if (location.isEmpty && !_hasGps) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresá ciudad/barrio o usá tu ubicación GPS'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _saveSuccess = false;
    });
    try {
      await ref.read(profileRepositoryProvider).updateMyProfile(
            location: location.isEmpty ? null : location,
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
      saving: _saving || _gpsBusy,
      saveSuccess: _saveSuccess,
      onSave: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ciudad o barrio (opcional) y GPS para el modo Cerca.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 16),
          TindogTextField(
            controller: _locationController,
            label: 'Ciudad o barrio',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: (_saving || _gpsBusy) ? null : _useGps,
            icon: _gpsBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(_hasGps ? 'Actualizar ubicación GPS' : 'Usar mi ubicación GPS'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          if (_hasGps) ...[
            const SizedBox(height: 10),
            Text(
              'GPS activo: el modo Cerca usará tu posición.',
              style: TextStyle(
                color: AppColors.primaryDark.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
