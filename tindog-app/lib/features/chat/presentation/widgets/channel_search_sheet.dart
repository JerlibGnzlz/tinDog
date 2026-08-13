import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/tindog_form_sheet_scaffold.dart';

/// Busca mensajes de texto dentro del canal actual.
///
/// Devuelve el `message.id` elegido, o `null` si se cierra sin seleccionar.
Future<String?> showChannelSearchSheet({
  required BuildContext context,
  required Channel channel,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) {
      return _ChannelSearchSheet(channel: channel);
    },
  );
}

class _ChannelSearchSheet extends StatefulWidget {
  const _ChannelSearchSheet({required this.channel});

  final Channel channel;

  @override
  State<_ChannelSearchSheet> createState() => _ChannelSearchSheetState();
}

class _ChannelSearchSheetState extends State<_ChannelSearchSheet> {
  final _queryController = TextEditingController();
  StreamMessageSearchListController? _controller;
  Timer? _debounce;
  var _hasQuery = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _onQueryChanged(String raw) {
    _debounce?.cancel();
    final query = raw.trim();
    setState(() => _hasQuery = query.length >= 2);
    if (query.length < 2) {
      _controller?.dispose();
      _controller = null;
      setState(() {});
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final client = StreamChat.of(context).client;
      final cid = widget.channel.cid;
      if (cid == null || cid.isEmpty) return;

      _controller?.dispose();
      final next = StreamMessageSearchListController(
        client: client,
        filter: Filter.equal('cid', cid),
        searchQuery: query,
        limit: 20,
      );
      _controller = next;
      setState(() {});
      unawaited(next.doInitialLoad());
    });
  }

  @override
  Widget build(BuildContext context) {
    return TindogFormSheetScaffold(
      scrollable: false,
      maxHeightFactor: 0.85,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Buscar en el chat',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _queryController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Escribí al menos 2 letras…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            Expanded(
              child: !_hasQuery
                  ? const Center(
                      child: Text(
                        'Buscá palabras de mensajes de este chat.',
                        style: TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _controller == null
                      ? const Center(child: CircularProgressIndicator())
                      : StreamMessageSearchListView(
                          controller: _controller!,
                          emptyBuilder: (_) => const Center(
                            child: Text(
                              'No hay resultados',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          onMessageTap: (result) {
                            Navigator.pop(context, result.message.id);
                          },
                        ),
            ),
          ],
        ),
    );
  }
}
