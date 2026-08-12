import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/feedback/app_haptics.dart';
import '../../../../core/network/session_handler.dart';
import '../../../../shared/widgets/tindog_text_field.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../pets/data/pet_repository.dart';
import '../profile_providers.dart';
import '../widgets/profile_section_scaffold.dart';

class ProfilePetScreen extends ConsumerStatefulWidget {
  const ProfilePetScreen({super.key});

  @override
  ConsumerState<ProfilePetScreen> createState() => _ProfilePetScreenState();
}

class _ProfilePetScreenState extends ConsumerState<ProfilePetScreen> {
  final _petNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _colorController = TextEditingController();
  final _breedController = TextEditingController();
  final _favoriteToyController = TextEditingController();

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
    _petNameController.dispose();
    _ageController.dispose();
    _colorController.dispose();
    _breedController.dispose();
    _favoriteToyController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final pet = await ref.read(petRepositoryProvider).getMyPet();
      _petNameController.text = pet.name ?? '';
      _ageController.text = pet.age?.toString() ?? '';
      _colorController.text = pet.color ?? '';
      _breedController.text = pet.breed ?? '';
      _favoriteToyController.text = pet.favoriteToy ?? '';
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

  int? _parseAge(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final age = int.tryParse(trimmed);
    if (age == null || age < 0 || age > 30) return null;
    return age;
  }

  Future<void> _save() async {
    final petName = _petNameController.text.trim();
    if (petName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre de tu mascota es requerido')),
      );
      return;
    }

    final ageText = _ageController.text.trim();
    int? age;
    if (ageText.isNotEmpty) {
      age = _parseAge(ageText);
      if (age == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresá una edad válida (0–30 años)')),
        );
        return;
      }
    }

    setState(() {
      _saving = true;
      _saveSuccess = false;
    });
    try {
      await ref.read(petRepositoryProvider).updateMyPet(
            name: petName,
            age: age,
            color: _colorController.text.trim(),
            breed: _breedController.text.trim(),
            favoriteToy: _favoriteToyController.text.trim(),
          );
      ref.invalidate(myPetProvider);
      final wasOnboarding =
          ref.read(needsPetOnboardingProvider).valueOrNull == true;
      if (wasOnboarding) {
        await ref.read(authRepositoryProvider).saveNeedsPetOnboarding(false);
        ref.invalidate(needsPetOnboardingProvider);
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveSuccess = true;
      });
      AppHaptics.success();
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      showTindogSuccessSnackBar(context, 'Datos caninos guardados');
      if (wasOnboarding) {
        context.go('/profile');
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
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
    final onboarding =
        ref.watch(needsPetOnboardingProvider).valueOrNull == true;
    return PopScope(
      canPop: !onboarding,
      child: ProfileSectionScaffold(
        title: onboarding ? 'Tu mascota' : 'Datos caninos',
        showBack: !onboarding,
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
            onboarding
                ? 'En tinDog el perfil principal es tu perro o gato. '
                    'Empezá por su nombre (el tuyo va en Datos personales).'
                : 'Contanos sobre tu perro o gato',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 16),
          TindogTextField(
            controller: _petNameController,
            label: 'Nombre de tu mascota',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TindogTextField(
            controller: _ageController,
            label: 'Edad (años)',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TindogTextField(
            controller: _breedController,
            label: 'Raza',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TindogTextField(
            controller: _colorController,
            label: 'Color',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TindogTextField(
            controller: _favoriteToyController,
            label: 'Juguete favorito',
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
      ),
    );
  }
}
