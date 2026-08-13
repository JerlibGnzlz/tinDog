import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/constants/dog_chat_icebreakers.dart';

export '../../../../shared/constants/dog_chat_icebreakers.dart'
    show kDogChatIcebreakers;

class StreamChatIcebreakers extends StatelessWidget {
  const StreamChatIcebreakers({
    super.key,
    required this.channel,
    this.wrap = false,
    /// En empty state: pocas frases, sin forzar scroll.
    this.maxItems,
    this.compact = false,
  });

  final Channel channel;
  final bool wrap;
  final int? maxItems;
  final bool compact;

  Future<void> _send(String text) async {
    await channel.sendMessage(Message(text: text));
  }

  List<String> get _items {
    final all = kDogChatIcebreakers;
    final limit = maxItems;
    if (limit == null || limit >= all.length) return all;
    return all.take(limit).toList();
  }

  Widget _chip(String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _send(text),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.55),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 10 : 12,
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    if (wrap) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rompe el hielo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 14 : 15,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            'Coordiná en un lugar público y de día',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: compact ? 11.5 : 12,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.22),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                compact ? 10 : 14,
                12,
                compact ? 10 : 14,
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final text in items) _chip(text),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _chip(items[index]),
      ),
    );
  }
}
