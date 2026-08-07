import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Frases rápidas pensadas para dueños que coordinan encuentros de perros.
const kDogChatIcebreakers = <String>[
  '¡Hola! ¿Salimos a pasear?',
  '¿Conocés algún parque bueno por acá?',
  '¿Tu perro se lleva bien con otros?',
  '¿Quedamos este finde?',
];

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.sending,
    required this.petName,
    required this.onSend,
    required this.onAttach,
    this.showIcebreakers = false,
    this.onIcebreaker,
  });

  final TextEditingController controller;
  final bool sending;
  final String petName;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool showIcebreakers;
  final ValueChanged<String>? onIcebreaker;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcebreakers && onIcebreaker != null)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              itemCount: kDogChatIcebreakers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final text = kDogChatIcebreakers[index];
                return ActionChip(
                  label: Text(
                    text,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF2A2A2A),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.55),
                  ),
                  onPressed: sending ? null : () => onIcebreaker!(text),
                );
              },
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 12, 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: sending ? null : onAttach,
                  icon: Icon(
                    Icons.add_circle_rounded,
                    color: AppColors.primary.withValues(alpha: 0.95),
                    size: 28,
                  ),
                  tooltip: 'Foto o video del perro',
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'Escribile a $petName…',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: sending ? null : onSend,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.35),
                  ),
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet de adjuntos con copy orientado a mascotas.
Future<void> showDogChatAttachSheet({
  required BuildContext context,
  required VoidCallback onPhotoGallery,
  required VoidCallback onPhotoCamera,
  required VoidCallback onVideoGallery,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Compartir del paseo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text(
                  'Foto de la galería',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Mostrá a tu perro',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onPhotoGallery();
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                title: const Text(
                  'Tomar foto',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onPhotoCamera();
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.videocam_outlined, color: AppColors.primary),
                title: const Text(
                  'Video corto',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Hasta 60 segundos',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onVideoGallery();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
