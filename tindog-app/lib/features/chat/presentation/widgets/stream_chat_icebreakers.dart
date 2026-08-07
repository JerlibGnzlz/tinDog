import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';

const kDogChatIcebreakers = <String>[
  '¡Hola! ¿Salimos a pasear?',
  '¿Conocés algún parque bueno por acá?',
  '¿Tu perro se lleva bien con otros?',
  '¿Quedamos este finde?',
];

class StreamChatIcebreakers extends StatelessWidget {
  const StreamChatIcebreakers({super.key, required this.channel});

  final Channel channel;

  Future<void> _send(String text) async {
    await channel.sendMessage(Message(text: text));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: AppColors.card,
            side: const BorderSide(color: AppColors.border),
            onPressed: () => _send(text),
          );
        },
      ),
    );
  }
}
