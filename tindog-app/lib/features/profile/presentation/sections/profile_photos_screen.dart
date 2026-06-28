import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/media/image_compressor.dart';
import '../../../../core/network/session_handler.dart';
import '../../../../core/session/user_data_cache.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/tindog_filled_button.dart';
import '../../../../shared/widgets/tindog_gradient_progress_bar.dart';
import '../../../media/data/media_repository.dart';
import '../../../pets/data/pet_media_model.dart';
import '../../../pets/data/pet_media_repository.dart';
import '../widgets/profile_section_scaffold.dart';

enum _UploadStage { idle, compressing, uploading, saving }

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
  _UploadStage _uploadStage = _UploadStage.idle;
  double? _uploadProgress;
  List<PetMediaModel> _photos = [];
  String? _deletingPhotoId;

  String? get _uploadStatus => switch (_uploadStage) {
        _UploadStage.compressing => 'Optimizando imagen…',
        _UploadStage.uploading => 'Subiendo foto…',
        _UploadStage.saving => 'Guardando…',
        _UploadStage.idle => null,
      };

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
      final photos = await ref.read(petMediaRepositoryProvider).listMyPhotos();
      if (mounted) {
        setState(() {
          _photos = photos;
          _loading = false;
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

  void _invalidateCache() {
    ref.read(userDataCacheGenerationProvider.notifier).update((n) => n + 1);
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= maxPetPhotos) {
      showTindogErrorSnackBar(
        context,
        'Alcanzaste el máximo de $maxPetPhotos fotos',
      );
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;

    setState(() {
      _uploadingPhoto = true;
      _uploadStage = _UploadStage.compressing;
      _uploadProgress = null;
    });

    try {
      final rawBytes = await picked.readAsBytes();
      final compressed = await ImageCompressor.compressForUpload(rawBytes);

      if (mounted) {
        setState(() {
          _uploadStage = _UploadStage.uploading;
          _uploadProgress = 0;
        });
      }

      final upload = await ref.read(mediaRepositoryProvider).uploadImageBytes(
            compressed,
            filename: picked.name,
            onProgress: (sent, total) {
              if (!mounted || total <= 0) return;
              setState(() => _uploadProgress = sent / total);
            },
          );

      if (mounted) {
        setState(() => _uploadStage = _UploadStage.saving);
      }

      final media = await ref.read(petMediaRepositoryProvider).addPhoto(
            url: upload.url,
            publicId: upload.publicId,
          );

      _invalidateCache();
      if (!mounted) return;
      setState(() => _photos = [..._photos, media]..sort(
            (a, b) => a.sortOrder.compareTo(b.sortOrder),
          ));
      showTindogSuccessSnackBar(context, 'Foto agregada a la galería');
    } catch (e) {
      if (isUnauthorizedError(e)) {
        if (mounted) handleSessionExpired(ref, context, e);
        return;
      }
      if (mounted) {
        showTindogErrorSnackBar(context, readableError(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
          _uploadStage = _UploadStage.idle;
          _uploadProgress = null;
        });
      }
    }
  }

  Future<void> _setPrimary(PetMediaModel photo) async {
    if (photo.isPrimary) return;

    try {
      final photos =
          await ref.read(petMediaRepositoryProvider).setPrimary(photo.id);
      _invalidateCache();
      if (!mounted) return;
      setState(() => _photos = photos);
      showTindogSuccessSnackBar(context, 'Foto principal actualizada');
    } catch (e) {
      if (isUnauthorizedError(e)) {
        if (mounted) handleSessionExpired(ref, context, e);
        return;
      }
      if (mounted) showTindogErrorSnackBar(context, readableError(e));
    }
  }

  Future<void> _deletePhoto(PetMediaModel photo) async {
    setState(() => _deletingPhotoId = photo.id);
    showTindogInfoSnackBar(context, 'Eliminando foto…');

    try {
      final photos =
          await ref.read(petMediaRepositoryProvider).deletePhoto(photo.id);
      _invalidateCache();
      if (!mounted) return;
      setState(() => _photos = photos);
      showTindogSuccessSnackBar(context, 'Foto eliminada');
    } catch (e) {
      if (isUnauthorizedError(e)) {
        if (mounted) handleSessionExpired(ref, context, e);
        return;
      }
      if (mounted) showTindogErrorSnackBar(context, readableError(e));
    } finally {
      if (mounted) setState(() => _deletingPhotoId = null);
    }
  }

  Future<void> _showPhotoOptions(PetMediaModel photo) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!photo.isPrimary)
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('Establecer como principal'),
                  onTap: () {
                    Navigator.pop(context);
                    _setPrimary(photo);
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red.shade700),
                title: Text(
                  'Eliminar foto',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deletePhoto(photo);
                },
              ),
            ],
          ),
        );
      },
    );
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
            'Subí hasta $maxPetPhotos fotos. La principal aparece en Home y en el swipe.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_photos.length} de $maxPetPhotos fotos',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _photos.length + (_photos.length < maxPetPhotos ? 1 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              if (index >= _photos.length) {
                return _AddPhotoTile(
                  enabled: !_uploadingPhoto && _deletingPhotoId == null,
                  onTap: _pickPhoto,
                );
              }

              final photo = _photos[index];
              return _GalleryPhotoTile(
                photo: photo,
                isDeleting: _deletingPhotoId == photo.id,
                onTap: _deletingPhotoId != null ? null : () => _showPhotoOptions(photo),
              );
            },
          ),
          if (_deletingPhotoId != null) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Eliminando foto…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (_uploadingPhoto) ...[
            const SizedBox(height: 20),
            Text(
              _uploadStatus ?? 'Subiendo…',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (_uploadProgress != null) ...[
              const SizedBox(height: 8),
              TindogGradientProgressBar(value: _uploadProgress!),
            ],
          ],
          if (_photos.isEmpty && !_uploadingPhoto) ...[
            const SizedBox(height: 24),
            TindogFilledButton(
              onPressed: _pickPhoto,
              child: const Text('Agregar primera foto'),
            ),
          ],
        ],
      ),
    );
  }
}

class _GalleryPhotoTile extends StatelessWidget {
  const _GalleryPhotoTile({
    required this.photo,
    required this.isDeleting,
    this.onTap,
  });

  final PetMediaModel photo;
  final bool isDeleting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo.url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: AppColors.border,
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
            if (photo.isPrimary)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Principal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isDeleting)
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Eliminando…',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border, width: 1.5),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 28,
              color: enabled ? AppColors.accent : AppColors.border,
            ),
            const SizedBox(height: 6),
            Text(
              'Agregar',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.border,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
