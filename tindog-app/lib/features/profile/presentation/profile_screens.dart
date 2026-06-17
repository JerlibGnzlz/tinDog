import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/no_stretch_scroll_behavior.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/pet_photo_picker.dart';
import '../../../shared/widgets/tindog_network_image.dart';
import '../../../shared/widgets/tindog_text_field.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../media/data/media_repository.dart';
import '../../pets/data/pet_model.dart';
import '../../pets/data/pet_repository.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(myPetProvider);

    ref.listen(myPetProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) => handleSessionExpired(ref, context, error),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('tinDog'),
        actions: [
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar perfil',
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authSessionProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: petAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _HomeBody(
          onEdit: () => context.go('/profile'),
          errorMessage: readableError(error),
        ),
        data: (pet) => _HomeBody(
          petName: pet.name,
          photoUrl: pet.photoUrl,
          onEdit: () => context.go('/profile'),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.onEdit,
    this.petName,
    this.photoUrl,
    this.errorMessage,
  });

  final VoidCallback onEdit;
  final String? petName;
  final String? photoUrl;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final hasPetProfile = petName != null && petName!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (photoUrl != null && photoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: TindogNetworkImage(
                imageUrl: photoUrl,
                width: double.infinity,
                height: 220,
                borderRadius: 24,
              ),
            )
          else
            const Icon(Icons.pets, size: 80, color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            hasPetProfile ? '¡Hola, ${petName!}!' : 'Bienvenido a tinDog',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red.shade700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            hasPetProfile
                ? 'Tu perfil está listo. Pronto podrás empezar a hacer match.'
                : 'Completa el perfil de tu mascota para continuar.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            onPressed: onEdit,
            child: Text(hasPetProfile ? 'Editar perfil' : 'Completar perfil'),
          ),
        ],
      ),
    );
  }
}

final myProfileProvider = FutureProvider<ProfileModel>((ref) {
  return ref.watch(profileRepositoryProvider).getMyProfile();
});

final myPetProvider = FutureProvider<PetModel>((ref) {
  return ref.watch(petRepositoryProvider).getMyPet();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _petNameController = TextEditingController();
  final _picker = ImagePicker();

  bool _loading = true;
  String? _loadError;
  bool _saving = false;
  bool _uploadingPhoto = false;
  XFile? _localPhoto;
  Uint8List? _localPhotoBytes;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _petNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        ref.read(profileRepositoryProvider).getMyProfile(),
        ref.read(petRepositoryProvider).getMyPet(),
      ]);

      final profile = results[0] as ProfileModel;
      final pet = results[1] as PetModel;

      _nameController.text = profile.name ?? '';
      _bioController.text = profile.bio ?? '';
      _locationController.text = profile.location ?? '';
      _petNameController.text = pet.name ?? '';
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
      if (!mounted) return;
      setState(() => _photoUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto subida correctamente')),
      );
    } catch (e) {
      if (isUnauthorizedError(e)) {
        if (mounted) handleSessionExpired(ref, context, e);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(readableError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<String?> _ensurePhotoUploaded() async {
    if (_localPhoto == null) return _photoUrl;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref.read(mediaRepositoryProvider).uploadImage(_localPhoto!);
      if (mounted) setState(() => _photoUrl = url);
      return url;
    } catch (e) {
      if (isUnauthorizedError(e)) {
        if (mounted) handleSessionExpired(ref, context, e);
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    final petName = _petNameController.text.trim();
    if (petName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _photoUrl != null || _localPhotoBytes != null
                ? 'Ingresa el nombre de tu mascota para guardar la foto'
                : 'El nombre de tu mascota es requerido',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      String? photoUrl = _photoUrl;
      if (_localPhoto != null) {
        photoUrl = await _ensurePhotoUploaded();
      }

      await Future.wait([
        ref.read(profileRepositoryProvider).updateMyProfile(
              name: _nameController.text.trim(),
              bio: _bioController.text.trim(),
              location: _locationController.text.trim(),
            ),
        ref.read(petRepositoryProvider).updateMyPet(
              name: petName,
              photoUrl: photoUrl,
            ),
      ]);

      ref.invalidate(myProfileProvider);
      ref.invalidate(myPetProvider);

      if (!mounted) return;

      setState(() {
        _localPhoto = null;
        _localPhotoBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado correctamente')),
      );
      context.go('/home');
    } catch (e) {
      if (isUnauthorizedError(e)) {
        if (mounted) handleSessionExpired(ref, context, e);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(readableError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_loadError!),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadData,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : ScrollConfiguration(
                  behavior: const NoStretchScrollBehavior(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      Text(
                        'Tu mascota',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      PetPhotoPicker(
                        photoUrl: _photoUrl,
                        localImageBytes: _localPhotoBytes,
                        localFile: _localPhoto != null && _localPhotoBytes == null
                            ? File(_localPhoto!.path)
                            : null,
                        isLoading: _uploadingPhoto,
                        onTap: _pickPhoto,
                      ),
                      const SizedBox(height: 16),
                      TindogTextField(
                        controller: _petNameController,
                        label: 'Nombre de tu mascota',
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Sobre ti',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 16),
                      TindogTextField(
                        controller: _locationController,
                        label: 'Ubicación',
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _saving || _uploadingPhoto ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Guardar'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
