import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/network/session_handler.dart';
import '../../../../core/session/user_data_cache.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/swipe_preview_media.dart';
import '../../../../shared/widgets/pet_video_player_screen.dart';
import '../../../../shared/widgets/tindog_filled_button.dart';
import '../../../../shared/widgets/tindog_gradient_progress_bar.dart';
import '../../../media/data/media_repository.dart';
import '../../../pets/data/pet_media_model.dart';
import '../../../pets/data/pet_media_repository.dart';
import '../widgets/profile_section_scaffold.dart';

enum _UploadStage { idle, uploading, saving }

class ProfileVideosScreen extends ConsumerStatefulWidget {
  const ProfileVideosScreen({super.key});

  @override
  ConsumerState<ProfileVideosScreen> createState() =>
      _ProfileVideosScreenState();
}

class _ProfileVideosScreenState extends ConsumerState<ProfileVideosScreen> {
  final _picker = ImagePicker();

  bool _loading = true;
  String? _loadError;
  bool _uploadingVideo = false;
  _UploadStage _uploadStage = _UploadStage.idle;
  double? _uploadProgress;
  List<PetMediaModel> _videos = [];
  String? _deletingVideoId;

  String? get _uploadStatus => switch (_uploadStage) {
        _UploadStage.uploading => 'Subiendo video…',
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
      final videos = await ref.read(petMediaRepositoryProvider).listMyVideos();
      if (mounted) {
        setState(() {
          _videos = videos;
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

  Future<void> _pickVideo() async {
    if (_videos.length >= maxPetVideos) {
      showTindogErrorSnackBar(
        context,
        'Alcanzaste el máximo de $maxPetVideos videos',
      );
      return;
    }

    final picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: maxVideoDurationSec),
    );
    if (picked == null) return;

    setState(() {
      _uploadingVideo = true;
      _uploadStage = _UploadStage.uploading;
      _uploadProgress = 0;
    });

    try {
      final upload = await ref.read(mediaRepositoryProvider).uploadVideo(
            picked,
            onProgress: (sent, total) {
              if (!mounted || total <= 0) return;
              setState(() => _uploadProgress = sent / total);
            },
          );

      if (upload.durationSec != null &&
          upload.durationSec! > maxVideoDurationSec) {
        throw Exception(
          'El video no puede durar más de $maxVideoDurationSec segundos',
        );
      }

      if (mounted) {
        setState(() => _uploadStage = _UploadStage.saving);
      }

      final media = await ref.read(petMediaRepositoryProvider).addVideo(
            url: upload.url,
            publicId: upload.publicId,
            durationSec: upload.durationSec,
          );

      _invalidateCache();
      if (!mounted) return;
      setState(() => _videos = [..._videos, media]..sort(
            (a, b) => a.sortOrder.compareTo(b.sortOrder),
          ));
      showTindogSuccessSnackBar(context, 'Video agregado');
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
          _uploadingVideo = false;
          _uploadStage = _UploadStage.idle;
          _uploadProgress = null;
        });
      }
    }
  }

  Future<void> _deleteVideo(PetMediaModel video) async {
    setState(() => _deletingVideoId = video.id);
    showTindogInfoSnackBar(context, 'Eliminando video…');

    try {
      final videos =
          await ref.read(petMediaRepositoryProvider).deleteVideo(video.id);
      _invalidateCache();
      if (!mounted) return;
      setState(() => _videos = videos);
      showTindogSuccessSnackBar(context, 'Video eliminado');
    } catch (e) {
      if (isUnauthorizedError(e)) {
        if (mounted) handleSessionExpired(ref, context, e);
        return;
      }
      if (mounted) showTindogErrorSnackBar(context, readableError(e));
    } finally {
      if (mounted) setState(() => _deletingVideoId = null);
    }
  }

  Future<void> _showVideoOptions(PetMediaModel video) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('Reproducir'),
                onTap: () {
                  Navigator.pop(context);
                  _playVideo(video);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red.shade700),
                title: Text(
                  'Eliminar video',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteVideo(video);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _playVideo(PetMediaModel video) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PetVideoPlayerScreen(
          url: video.url,
          title: video.durationSec != null
              ? formatMediaDuration(video.durationSec!)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSectionScaffold(
      title: 'Videos',
      loading: _loading,
      loadError: _loadError,
      onRetry: _loadData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Subí hasta $maxPetVideos clips de hasta $maxVideoDurationSec segundos.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_videos.length} de $maxPetVideos videos',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _videos.length + (_videos.length < maxPetVideos ? 1 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              if (index >= _videos.length) {
                return _AddVideoTile(
                  enabled: !_uploadingVideo && _deletingVideoId == null,
                  onTap: _pickVideo,
                );
              }

              final video = _videos[index];
              final isDeleting = _deletingVideoId == video.id;
              return _GalleryVideoTile(
                video: video,
                isDeleting: isDeleting,
                onTap: _deletingVideoId != null
                    ? null
                    : () => _showVideoOptions(video),
                onPlay: isDeleting ? null : () => _playVideo(video),
              );
            },
          ),
          if (_deletingVideoId != null) ...[
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
                  'Eliminando video…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (_uploadingVideo) ...[
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
          if (_videos.isEmpty && !_uploadingVideo) ...[
            const SizedBox(height: 24),
            TindogFilledButton(
              onPressed: _pickVideo,
              child: const Text('Agregar primer video'),
            ),
          ],
        ],
      ),
    );
  }
}

class _GalleryVideoTile extends StatelessWidget {
  const _GalleryVideoTile({
    required this.video,
    required this.isDeleting,
    this.onTap,
    this.onPlay,
  });

  final PetMediaModel video;
  final bool isDeleting;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;

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
            CachedNetworkImage(
              imageUrl: cloudinaryVideoPosterUrl(video.url),
              fit: BoxFit.cover,
              placeholder: (_, _) => ColoredBox(
                color: Colors.black.withValues(alpha: 0.85),
              ),
              errorWidget: (_, _, _) => ColoredBox(
                color: Colors.black.withValues(alpha: 0.85),
                child: Icon(
                  Icons.videocam_outlined,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 40,
                ),
              ),
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.22),
              child: Center(
                child: IconButton(
                  onPressed: onPlay,
                  iconSize: 52,
                  color: Colors.white,
                  icon: const Icon(Icons.play_circle_fill),
                ),
              ),
            ),
            if (video.durationSec != null)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatMediaDuration(video.durationSec!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

class _AddVideoTile extends StatelessWidget {
  const _AddVideoTile({
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
              Icons.video_call_outlined,
              size: 32,
              color: enabled ? AppColors.accent : AppColors.border,
            ),
            const SizedBox(height: 8),
            Text(
              'Agregar',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
