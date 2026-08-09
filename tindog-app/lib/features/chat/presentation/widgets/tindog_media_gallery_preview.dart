import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';

/// Galería fullscreen con chrome más compacto (evita overflow de AppBar Stream).
Widget buildTindogMediaGalleryPreview(
  BuildContext context,
  StreamMediaGalleryPreviewProps props,
) {
  final mq = MediaQuery.of(context);
  return MediaQuery(
    data: mq.copyWith(
      textScaler: mq.textScaler.clamp(
        minScaleFactor: 0.85,
        maxScaleFactor: 1.0,
      ),
    ),
    child: StreamAppBarTheme(
      data: const StreamAppBarThemeData(
        style: StreamAppBarStyle(
          backgroundColor: AppColors.surface,
          // Menos padding vertical → más aire para título + “Enviado…”.
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            height: 1.15,
          ),
          subtitleTextStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.15,
          ),
        ),
      ),
      child: StreamBottomAppBarTheme(
        data: const StreamBottomAppBarThemeData(
          style: StreamBottomAppBarStyle(
            backgroundColor: AppColors.card,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              height: 1.1,
            ),
          ),
        ),
        child: DefaultStreamMediaGalleryPreview(props: props),
      ),
    ),
  );
}
