import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/tindog_media_gallery_preview.dart';

/// Tema Stream con paleta tinDog (crema + verde salvia).
StreamTheme tindogStreamTheme() {
  final brand = StreamColorSwatch.fromColor(AppColors.primary);

  return StreamTheme(
    brightness: Brightness.light,
    colorScheme: StreamColorScheme.light(
      brand: brand,
      accentPrimary: AppColors.primary,
      accentSuccess: AppColors.accent,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      textTertiary: AppColors.textSecondary.withValues(alpha: 0.75),
      textLink: AppColors.accent,
      textOnAccent: Colors.white,
      backgroundApp: AppColors.surface,
      backgroundSurface: AppColors.card,
      backgroundSurfaceSubtle: AppColors.surface,
      backgroundSurfaceStrong: const Color(0xFFF0E6D4),
      backgroundSurfaceCard: AppColors.card,
      backgroundElevation0: AppColors.surface,
      backgroundElevation1: AppColors.card,
      borderDefault: AppColors.border,
      borderSubtle: AppColors.border.withValues(alpha: 0.7),
      borderFocus: AppColors.primary,
    ),
    messageItemTheme: StreamMessageItemThemeData(
      bubble: StreamMessageBubbleStyle(
        backgroundColor: StreamMessageLayoutProperty.resolveWith((p) {
          final mine = p.alignment == StreamMessageAlignment.end;
          // Míos: verde salvia. Otros: crema con tinte verde suave.
          return mine ? AppColors.primary : const Color(0xFFE8EFDF);
        }),
      ),
      text: StreamMessageTextStyle(
        textColor: StreamMessageLayoutProperty.resolveWith((p) {
          final mine = p.alignment == StreamMessageAlignment.end;
          return mine ? Colors.white : AppColors.textPrimary;
        }),
        linkColor: StreamMessageLayoutProperty.resolveWith((p) {
          final mine = p.alignment == StreamMessageAlignment.end;
          return mine ? Colors.white : AppColors.accent;
        }),
      ),
      metadata: StreamMessageMetadataStyle(
        timestampColor: StreamMessageLayoutProperty.resolveWith((p) {
          final mine = p.alignment == StreamMessageAlignment.end;
          // Verde oscuro sobre burbuja salvia (blanco casi no se ve).
          return mine ? AppColors.primaryDark : AppColors.textSecondary;
        }),
        editedColor: StreamMessageLayoutProperty.resolveWith((p) {
          final mine = p.alignment == StreamMessageAlignment.end;
          return mine
              ? AppColors.primaryDark.withValues(alpha: 0.85)
              : AppColors.textSecondary;
        }),
        statusColor: StreamMessageLayoutProperty.resolveWith((p) {
          final mine = p.alignment == StreamMessageAlignment.end;
          return mine ? AppColors.primaryDark : AppColors.accent;
        }),
      ),
    ),
  );
}

StreamChatThemeData tindogStreamChatTheme() {
  return StreamChatThemeData(
    channelHeaderTheme: const StreamAppBarThemeData(
      style: StreamAppBarStyle(
        backgroundColor: AppColors.surface,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        subtitleTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
    ),
    messageListViewTheme: const StreamMessageListViewThemeData(
      backgroundColor: AppColors.surface,
    ),
  );
}

/// Envuelve el árbol Stream con Theme + StreamTheme tinDog.
Widget wrapWithTindogStreamTheme({
  required StreamChatClient client,
  required Widget child,
}) {
  return Builder(
    builder: (context) {
      final base = Theme.of(context);
      return Theme(
        data: base.copyWith(
          scaffoldBackgroundColor: AppColors.surface,
          extensions: [
            ...base.extensions.values.where((e) => e is! StreamTheme),
            tindogStreamTheme(),
          ],
        ),
        child: StreamChat(
          client: client,
          themeData: tindogStreamChatTheme(),
          // Solo reacción ❤️ (love). Unique: un corazón por usuario.
          configData: StreamChatConfigurationData(
            reactionIconResolver: const _HeartOnlyReactionResolver(),
            enforceUniqueReactions: true,
          ),
          componentBuilders: StreamComponentBuilders(
            extensions: streamChatComponentBuilders(
              mediaGalleryPreview: buildTindogMediaGalleryPreview,
            ),
          ),
          child: child,
        ),
      );
    },
  );
}

/// Una sola reacción rápida: ❤️
class _HeartOnlyReactionResolver extends DefaultReactionIconResolver {
  const _HeartOnlyReactionResolver();

  @override
  Set<String> get defaultReactions => const {'love'};

  @override
  Set<String> get supportedReactions => const {'love'};
}
