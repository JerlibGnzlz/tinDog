import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/media/image_compressor.dart';
import '../../../../core/network/session_handler.dart';
import '../../../../core/session/user_data_cache.dart';
import '../../../../shared/widgets/pet_photo_picker.dart';
import '../../../media/data/media_repository.dart';
import '../../../pets/data/pet_repository.dart';
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
  XFile? _localPhoto;
  Uint8List? _localImageBytes;
  String? _photoUrl;

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
      final pet = await ref.read(petRepositoryProvider).getMyPet();
      _photoUrl = pet.photoUrl;
      _localPhoto = null;
      _localImageBytes = null;
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
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;

    setState(() {
      _localPhoto = picked;
      _uploadingPhoto = true;
      _uploadStage = _UploadStage.compressing;
      _uploadProgress = null;
    });

    try {
      final rawBytes = await picked.readAsBytes();
      if (mounted) {
        setState(() => _localImageBytes = rawBytes);
      }

      final compressed = await ImageCompressor.compressForUpload(rawBytes);
      if (mounted) {
        setState(() {
          _localImageBytes = compressed;
          _uploadStage = _UploadStage.uploading;
          _uploadProgress = 0;
        });
      }

      final url = await ref.read(mediaRepositoryProvider).uploadImageBytes(
            compressed,
            filename: picked.name,
            onProgress: (sent, total) {
              if (!mounted || total <= 0) return;
              setState(() => _uploadProgress = sent / total);
            },
          );

      if (mounted) {
        setState(() {
          _uploadStage = _UploadStage.saving;
          _uploadProgress = null;
        });
      }

      await ref.read(petRepositoryProvider).updateMyPet(photoUrl: url);
      ref.read(userDataCacheGenerationProvider.notifier).update((n) => n + 1);

      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _localPhoto = null;
        _localImageBytes = null;
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
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
          _uploadStage = _UploadStage.idle;
          _uploadProgress = null;
        });
      }
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
            localImageBytes: _localImageBytes,
            localFile: _localPhoto != null && _localImageBytes == null
                ? File(_localPhoto!.path)
                : null,
            isLoading: _uploadingPhoto,
            uploadProgress: _uploadProgress,
            uploadStatus: _uploadStatus,
            onTap: _pickPhoto,
          ),
        ],
      ),
    );
  }
}
