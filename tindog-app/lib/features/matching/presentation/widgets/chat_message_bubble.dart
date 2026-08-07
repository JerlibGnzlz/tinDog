import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/swipe_preview_media.dart';
import '../../../../shared/widgets/pet_photo_viewer_screen.dart';
import '../../../../shared/widgets/pet_video_player_screen.dart';
import '../../data/chat_models.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMe;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: message.type == ChatMessageType.text
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
            : const EdgeInsets.all(6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: switch (message.type) {
          ChatMessageType.text => Text(
              message.body,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ChatMessageType.image => _ImageBody(message: message),
          ChatMessageType.video => _VideoBody(message: message),
        },
      ),
    );
  }
}

class _ImageBody extends StatelessWidget {
  const _ImageBody({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final url = message.mediaUrl;
    if (url == null || url.isEmpty) {
      return const Text('📷 Foto', style: TextStyle(color: Colors.white));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PetPhotoViewerScreen(url: url),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                height: 220,
                color: Colors.black26,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (_, _, _) => Container(
                height: 120,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, color: Colors.white70),
              ),
            ),
          ),
        ),
        if (message.body.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              message.body,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }
}

class _VideoBody extends StatelessWidget {
  const _VideoBody({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final url = message.mediaUrl;
    if (url == null || url.isEmpty) {
      return const Text('🎬 Video', style: TextStyle(color: Colors.white));
    }

    final thumb = message.thumbnailUrl?.isNotEmpty == true
        ? message.thumbnailUrl!
        : cloudinaryVideoPosterUrl(url);
    final duration = message.durationSec;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PetVideoPlayerScreen(
                  url: url,
                  title: duration != null
                      ? formatMediaDuration(duration)
                      : 'Video',
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: thumb,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    height: 220,
                    color: Colors.black26,
                  ),
                  errorWidget: (_, _, _) => Container(
                    height: 220,
                    color: Colors.black45,
                    alignment: Alignment.center,
                    child: const Icon(Icons.videocam, color: Colors.white70),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                if (duration != null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formatMediaDuration(duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (message.body.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              message.body,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }
}
