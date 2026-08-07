import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tindog_loader.dart';
import '../../matching/data/chat_models.dart';
import '../../matching/data/discover_candidate.dart';
import '../../matching/presentation/chats_providers.dart';
import '../../matching/presentation/likes_providers.dart';
import '../../safety/presentation/safety_sheets.dart';
import '../data/chat_repository.dart';
import 'stream_chat_providers.dart';
import 'widgets/chat_presence_avatar.dart';
import 'widgets/stream_chat_icebreakers.dart';
import 'widgets/tindog_channel_status.dart';
import 'widgets/tindog_message_leading.dart';
import 'widgets/tindog_message_sender.dart';

class StreamChatThreadScreen extends ConsumerStatefulWidget {
  const StreamChatThreadScreen({
    super.key,
    required this.matchId,
    this.thread,
  });

  final String matchId;
  final MatchThread? thread;

  @override
  ConsumerState<StreamChatThreadScreen> createState() =>
      _StreamChatThreadScreenState();
}

class _StreamChatThreadScreenState
    extends ConsumerState<StreamChatThreadScreen> {
  Channel? _channel;
  Object? _error;
  bool _loading = true;
  StreamChatUserDto? _ensureOther;
  Map<String, StreamChatUserDto> _membersById = const {};

  String get _petName =>
      widget.thread?.otherPet.name ?? _ensureOther?.name ?? 'Chat';

  String? get _otherPhoto {
    // Preferí datos frescos de ensure/members (el thread puede traer fotos cacheadas).
    final ownerId = widget.thread?.otherPet.ownerUserId ?? _ensureOther?.id;
    if (ownerId != null) {
      final fromMember = _membersById[ownerId]?.image?.trim();
      if (fromMember != null && fromMember.isNotEmpty) return fromMember;
    }
    final fromEnsure = _ensureOther?.image?.trim();
    if (fromEnsure != null && fromEnsure.isNotEmpty) return fromEnsure;
    final fromThread = widget.thread?.otherPet.photoUrls;
    if (fromThread != null && fromThread.isNotEmpty) return fromThread.first;
    return null;
  }

  DiscoverCandidate? get _otherPet {
    final threadPet = widget.thread?.otherPet;
    if (threadPet != null) return threadPet;
    if (_ensureOther == null) return null;
    return DiscoverCandidate(
      id: _ensureOther!.id,
      name: _ensureOther!.name,
      photoUrls: [
        if (_ensureOther!.image != null &&
            _ensureOther!.image!.trim().isNotEmpty)
          _ensureOther!.image!,
      ],
      ownerUserId: _ensureOther!.id,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openChannel());
  }

  Future<void> _openChannel() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = await ref.read(streamChatClientProvider.future);
      if (client == null) {
        throw StateError('Stream no conectado. Volvé a iniciar sesión.');
      }

      final ensured = await ref
          .read(chatRepositoryProvider)
          .ensureChannel(widget.matchId);

      final channel = client.channel(
        ensured.channelType,
        id: ensured.channelId,
      );
      await channel.watch();

      final membersById = {
        for (final m in ensured.members) m.id: m,
      };

      if (membersById.isNotEmpty) {
        try {
          await client.queryUsers(
            filter: Filter.in_('id', membersById.keys.toList()),
            presence: true,
          );
        } catch (_) {
          // Best-effort
        }
      }

      if (!mounted) return;
      setState(() {
        _channel = channel;
        _ensureOther = ensured.other;
        _membersById = membersById;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (isSessionError(e)) {
        handleSessionExpired(ref, context, e);
        return;
      }
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Message _displayMessage(BuildContext context, Message message) {
    final client = StreamChat.of(context).client;
    final senderId = message.user?.id;
    final live = senderId != null ? client.state.users[senderId] : null;

    return resolveIncomingSender(
      message: message,
      currentUser: client.state.currentUser,
      otherPet: _otherPet,
      liveSender: live,
      membersById: _membersById,
    );
  }

  Future<void> _openSafety() async {
    final otherUserId =
        widget.thread?.otherPet.ownerUserId ?? _ensureOther?.id;
    if (otherUserId == null || otherUserId.isEmpty) return;

    final result = await showSafetyActionsSheet(
      context: context,
      ref: ref,
      otherUserId: otherUserId,
      otherName: _petName,
      matchId: widget.matchId,
    );
    if (!mounted || result == null) return;

    if (result.removedFromChats) {
      ref.invalidate(matchesProvider);
      ref.invalidate(receivedLikesProvider);
      ref.invalidate(sentLikesProvider);
      ref.invalidate(likesSummaryProvider);
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/chats');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: TindogLoader(message: 'Abriendo chat…'),
        ),
      );
    }

    if (_error != null || _channel == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          title: Text(_petName),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  readableError(_error ?? 'No se pudo abrir el chat'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _openChannel,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final channel = _channel!;
    final otherPhoto = _otherPhoto;
    final otherName = _petName;

    return StreamChannel(
      channel: channel,
      child: StreamComponentFactory(
        builders: StreamComponentBuilders(
          extensions: streamChatComponentBuilders(
            messageLeading: (context, props) {
              final me = StreamChat.of(context).currentUser?.id;
              final senderId = props.message.user?.id;
              if (senderId == null || senderId == me) {
                return DefaultStreamMessageLeading(props: props);
              }
              final member = _membersById[senderId];
              return TindogMessageLeading(
                props: props,
                imageUrl: member?.image ?? otherPhoto,
                name: member?.name ?? otherName,
              );
            },
          ),
        ),
        child: Scaffold(
          backgroundColor: AppColors.surface,
          appBar: StreamChannelHeader(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            automaticallyImplyLeading: false,
            // Título = con quién hablás. Avatar en trailing evita overflow del AppBar.
            title: Text(
              _petName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            subtitle: TindogChannelStatus(channel: channel),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Seguridad',
                  onPressed: () => _openSafety(),
                  icon: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChatPresenceAvatar(
                    photoUrl: otherPhoto,
                    streamUserId:
                        widget.thread?.otherPet.ownerUserId ??
                        _ensureOther?.id,
                    radius: 16,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamMessageListView(
                  messageBuilder: (context, message, props) {
                    final display = _displayMessage(context, message);
                    return DefaultStreamMessageItem(
                      props: props.copyWith(message: display),
                    );
                  },
                  builders: StreamMessageListViewBuilders(
                    empty: (_) => _EmptyMatchHint(
                      petName: _petName,
                      channel: channel,
                    ),
                  ),
                ),
              ),
              StreamMessageComposer(
                enableVoiceRecording: false,
                allowedAttachmentPickerTypes: const [
                  AttachmentPickerType.images,
                  AttachmentPickerType.videos,
                  AttachmentPickerType.files,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMatchHint extends StatelessWidget {
  const _EmptyMatchHint({
    required this.petName,
    required this.channel,
  });

  final String petName;
  final Channel channel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pets_rounded,
              size: 44,
              color: AppColors.primary.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 14),
            Text(
              '¡Match con $petName!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vas a ver cuándo está en línea o escribiendo. '
              'Empezá con una frase rápida:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.95),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            StreamChatIcebreakers(
              channel: channel,
              wrap: true,
            ),
          ],
        ),
      ),
    );
  }
}
