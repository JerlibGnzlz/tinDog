import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/feedback/app_haptics.dart';
import '../../../core/network/session_handler.dart';
import '../../../shared/widgets/pet_photo_picker.dart';
import '../../../shared/widgets/tindog_text_field.dart';
import '../../media/data/media_repository.dart';
import '../../pets/data/pet_repository.dart';
import '../data/profile_repository.dart';
import 'profile_providers.dart';
import 'widgets/profile_section_scaffold.dart';

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
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveSuccess = true;
      });
      AppHaptics.success();
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      showTindogSuccessSnackBar(context, 'Datos caninos guardados');
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
      title: 'Datos caninos',
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
            'Contanos sobre tu perro o gato',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 16),
          TindogTextField(
            controller: _petNameController,
            label: 'Nombre',
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
    );
  }
}

class ProfilePhotosScreen extends ConsumerStatefulWidget {
  const ProfilePhotosScreen({super.key});

  @override
  ConsumerState<ProfilePhotosScreen> createState() =>
      _ProfilePhotosScreenState();
}

class _ProfilePhotosScreenState extends ConsumerState<ProfilePhotosScreen> {
  final _picker = ImagePicker();

  bool _loading = true;
  String? _loadError;
  bool _uploadingPhoto = false;
  XFile? _localPhoto;
  Uint8List? _localPhotoBytes;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final pet = await ref.read(petRepositoryProvider).getMyPet();
      _photoUrl = pet.photoUrl;
      _localPhoto = null;
      _localPhotoBytes = null;
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

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _localPhoto = picked;
      _localPhotoBytes = bytes;
      _uploadingPhoto = true;
    });

    try {
      final url = await ref.read(mediaRepositoryProvider).uploadImage(picked);
      await ref.read(petRepositoryProvider).updateMyPet(photoUrl: url);
      ref.invalidate(myPetProvider);
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _localPhoto = null;
        _localPhotoBytes = null;
      });
      showTindogSuccessSnackBar(context, 'Foto guardada correctamente');
    } catch (e) {
      if (isUnauthorizedError(e)) {
        if (mounted) handleSessionExpired(ref, context, e);
        return;
      }
      if (mounted) {
        showTindogErrorSnackBar(context, readableError(e));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSectionScaffold(
      title: 'Fotos',
      loading: _loading,
      loadError: _loadError,
      onRetry: _loadData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Foto principal de tu mascota',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'La galería con varias fotos llegará en una próxima actualización.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 16),
          PetPhotoPicker(
            photoUrl: _photoUrl,
            localImageBytes: _localPhotoBytes,
            localFile: _localPhoto != null && _localPhotoBytes == null
                ? File(_localPhoto!.path)
                : null,
            isLoading: _uploadingPhoto,
            onTap: _pickPhoto,
          ),
        ],
      ),
    );
  }
}

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

class ProfileVideosScreen extends StatelessWidget {
  const ProfileVideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileSectionScaffold(
      title: 'Videos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.videocam_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Próximamente',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Podrás subir clips de tu mascota en una próxima actualización.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
