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
  const StreamChatIcebreakers({
    super.key,
    required this.channel,
    this.wrap = false,
  });

  final Channel channel;
  final bool wrap;

  Future<void> _send(String text) async {
    await channel.sendMessage(Message(text: text));
  }

  Widget _chip(String text) {
    return ActionChip(
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
      backgroundColor: AppColors.primary.withValues(alpha: 0.16),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onPressed: () => _send(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (wrap) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final text in kDogChatIcebreakers) _chip(text),
        ],
      );
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        itemCount: kDogChatIcebreakers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _chip(kDogChatIcebreakers[index]),
      ),
    );
  }
}
