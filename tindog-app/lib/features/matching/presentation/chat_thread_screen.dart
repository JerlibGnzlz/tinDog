import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../media/data/media_repository.dart';
import '../../../shared/models/swipe_preview_media.dart';
import '../../../shared/widgets/tindog_loader.dart';
import '../data/chat_models.dart';
import '../data/matching_repository.dart';
import 'chats_providers.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_message_bubble.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.matchId,
    this.thread,
  });

  final String matchId;
  final MatchThread? thread;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshAndScroll() async {
    ref.invalidate(chatMessagesProvider(widget.matchId));
    ref.invalidate(matchesProvider);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendText([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(matchingRepositoryProvider)
          .sendTextMessage(widget.matchId, text);
      _controller.clear();
      await _refreshAndScroll();
    } catch (e) {
      if (!mounted) return;
      _handleSendError(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendMedia({
    required bool video,
    ImageSource source = ImageSource.gallery,
  }) async {
    if (_sending) return;

    final file = video
        ? await _picker.pickVideo(
            source: source,
            maxDuration: const Duration(seconds: 60),
          )
        : await _picker.pickImage(
            source: source,
            imageQuality: 85,
            maxWidth: 1920,
          );
    if (file == null || !mounted) return;

    setState(() => _sending = true);
    showTindogInfoSnackBar(
      context,
      video ? 'Subiendo video…' : 'Subiendo foto…',
    );

    try {
      final mediaRepo = ref.read(mediaRepositoryProvider);
      final uploaded = video
          ? await mediaRepo.uploadVideo(file)
          : await mediaRepo.uploadImage(file);

      await ref.read(matchingRepositoryProvider).sendMessage(
            widget.matchId,
            type: video ? ChatMessageType.video : ChatMessageType.image,
            body: _controller.text.trim(),
            mediaUrl: uploaded.url,
            mediaPublicId: uploaded.publicId,
            durationSec: uploaded.durationSec,
            thumbnailUrl: video
                ? cloudinaryVideoPosterUrl(uploaded.url)
                : null,
          );
      _controller.clear();
      await _refreshAndScroll();
    } catch (e) {
      if (!mounted) return;
      _handleSendError(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _handleSendError(Object e) {
    if (isSessionError(e)) {
      handleSessionExpired(ref, context, e);
      return;
    }
    showTindogErrorSnackBar(context, readableError(e));
  }

  void _showAttachSheet() {
    showDogChatAttachSheet(
      context: context,
      onPhotoGallery: () => _pickAndSendMedia(video: false),
      onPhotoCamera: () => _pickAndSendMedia(
        video: false,
        source: ImageSource.camera,
      ),
      onVideoGallery: () => _pickAndSendMedia(video: true),
    );
  }

  String get _petName => widget.thread?.otherPet.name ?? 'tu match';

  String? get _subtitle {
    final pet = widget.thread?.otherPet;
    if (pet == null) return null;
    final parts = <String>[
      if (pet.breed?.trim().isNotEmpty == true) pet.breed!.trim(),
      if (pet.age != null) '${pet.age} años',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.matchId));
    final photo = widget.thread?.otherPet.photoUrls.isNotEmpty == true
        ? widget.thread!.otherPet.photoUrls.first
        : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.border,
              backgroundImage:
                  photo != null ? CachedNetworkImageProvider(photo) : null,
              child: photo == null
                  ? const Icon(
                      Icons.pets,
                      size: 18,
                      color: AppColors.primaryDark,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _petName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  if (_subtitle != null)
                    Text(
                      _subtitle!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: TindogLoader(message: 'Cargando…'),
              ),
              error: (error, _) => Center(
                child: Text(
                  chatErrorMessage(error),
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pets_rounded,
                            size: 40,
                            color: AppColors.primary.withValues(alpha: 0.85),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '¡Match con $_petName!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Coordiná un paseo, compartí una foto o usá '
                            'una frase rápida abajo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return ChatMessageBubble(message: messages[index]);
                  },
                );
              },
            ),
          ),
          ChatComposer(
            controller: _controller,
            sending: _sending,
            petName: _petName,
            showIcebreakers: messagesAsync.valueOrNull?.isEmpty ?? true,
            onSend: _sendText,
            onAttach: _showAttachSheet,
            onIcebreaker: _sendText,
          ),
        ],
      ),
    );
  }
}
