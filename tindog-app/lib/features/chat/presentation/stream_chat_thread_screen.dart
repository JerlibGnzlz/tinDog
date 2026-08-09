import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tindog_loader.dart';
import '../../matching/data/chat_models.dart';
import '../../matching/data/discover_candidate.dart';
import '../../matching/presentation/chats_providers.dart';
import '../../matching/presentation/likes_providers.dart';
import '../../matching/presentation/delete_conversation.dart';
import '../../notifications/data/devices_repository.dart';
import '../../safety/presentation/safety_sheets.dart';
import '../data/chat_repository.dart';
import 'stream_chat_errors.dart';
import 'stream_chat_providers.dart';
import 'widgets/chat_presence_avatar.dart';
import 'widgets/match_profile_sheet.dart';
import 'widgets/stream_chat_error_panel.dart';
import 'widgets/stream_chat_icebreakers.dart';
import 'widgets/tindog_channel_status.dart';
import 'widgets/tindog_chat_attachments.dart';
import 'widgets/tindog_composer_emoji.dart';
import 'widgets/tindog_message_actions.dart';
import 'widgets/tindog_message_edit.dart';
import 'widgets/tindog_message_footer.dart';
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
  final _composerController = StreamMessageComposerController();
  StreamSubscription<Event>? _readSub;
  Timer? _activeChatHeartbeat;

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

  @override
  void dispose() {
    _readSub?.cancel();
    _stopActiveChatPresence();
    final channel = _channel;
    if (channel != null) {
      unawaited(_markChannelRead(channel));
    }
    _composerController.dispose();
    super.dispose();
  }

  void _startActiveChatPresence() {
    _activeChatHeartbeat?.cancel();
    final matchId = widget.matchId;
    final devices = ref.read(devicesRepositoryProvider);
    unawaited(devices.setActiveChat(matchId));
    _activeChatHeartbeat = Timer.periodic(const Duration(seconds: 90), (_) {
      unawaited(devices.setActiveChat(matchId));
    });
  }

  void _stopActiveChatPresence() {
    _activeChatHeartbeat?.cancel();
    _activeChatHeartbeat = null;
    unawaited(ref.read(devicesRepositoryProvider).setActiveChat(null));
  }

  Future<void> _markChannelRead(Channel channel) async {
    try {
      await channel.markRead();
    } catch (_) {
      // Best-effort.
    }
  }

  Future<StreamChatClient> _requireStreamClient() async {
    final current = ref.read(streamChatClientProvider);
    if (current.hasError || current.valueOrNull == null) {
      await ref.read(streamChatClientProvider.notifier).reconnect();
    }
    final client = ref.read(streamChatClientProvider).valueOrNull;
    if (client != null) return client;

    // Último intento vía future (puede lanzar con el error real).
    final viaFuture = await ref.read(streamChatClientProvider.future);
    if (viaFuture == null) {
      throw StateError('Stream no conectado. Volvé a iniciar sesión.');
    }
    return viaFuture;
  }

  Future<void> _openChannel() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = await _requireStreamClient();

      final ensured = await ref
          .read(chatRepositoryProvider)
          .ensureChannel(widget.matchId);

      final channel = client.channel(
        ensured.channelType,
        id: ensured.channelId,
      );
      await channel.watch(presence: true);
      // Refresca presencia de los miembros al entrar (sin esperar al teclado).
      try {
        final memberIds = channel.state?.members
                .map((m) => m.userId)
                .whereType<String>()
                .where((id) => id.isNotEmpty)
                .toList(growable: false) ??
            const <String>[];
        if (memberIds.isNotEmpty) {
          await client.queryUsers(
            filter: Filter.in_('id', memberIds),
            presence: true,
          );
        }
      } catch (_) {}

      await _markChannelRead(channel);
      // Segundo intento cuando el state ya tiene mensajes cargados.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await _markChannelRead(channel);

      await _readSub?.cancel();
      _readSub = channel.on().listen((event) {
        final type = event.type;
        if (type == EventType.messageNew ||
            type == EventType.notificationMessageNew) {
          unawaited(_markChannelRead(channel));
        }
        // Mantener En línea / Desconectado al día mientras el chat está abierto.
        if (type == EventType.userPresenceChanged ||
            type == EventType.userUpdated) {
          final ids = ensured.members.map((m) => m.id).toList(growable: false);
          if (ids.isNotEmpty) {
            unawaited(
              client.queryUsers(
                filter: Filter.in_('id', ids),
                presence: true,
              ),
            );
          }
        }
      });

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
      _startActiveChatPresence();
      setState(() {
        _channel = channel;
        _ensureOther = ensured.other;
        _membersById = membersById;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (isSessionError(e)) {
        setState(() => _loading = false);
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

    final withSender = resolveIncomingSender(
      message: message,
      currentUser: client.state.currentUser,
      otherPet: _otherPet,
      liveSender: live,
      membersById: _membersById,
    );
    return withVisibleImageAttachments(withSender);
  }

  Future<void> _openMatchProfile() async {
    final pet = _otherPet;
    if (pet == null) return;
    await showMatchProfileSheet(
      context: context,
      pet: pet,
      onSafety: () => unawaited(_openSafety()),
      onDeleteChat: () => unawaited(_deleteConversation()),
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
      await _leaveChatAfterRemoval();
    }
  }

  Future<void> _deleteConversation() async {
    final thread = widget.thread ??
        MatchThread(
          id: widget.matchId,
          matchedAt: DateTime.now().toUtc(),
          otherPet: DiscoverCandidate(
            id: _ensureOther?.id ?? widget.matchId,
            name: _petName,
            photoUrls: [
              if (_otherPhoto != null && _otherPhoto!.isNotEmpty) _otherPhoto!,
            ],
            ownerUserId: _ensureOther?.id,
          ),
          hasMessages: true,
          lastMessage: null,
        );
    final deleted = await confirmAndDeleteConversation(
      context: context,
      ref: ref,
      thread: thread,
    );
    if (!mounted || !deleted) return;
    await _leaveChatAfterRemoval();
  }

  Future<void> _leaveChatAfterRemoval() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      unawaited(() async {
        try {
          await channel.stopWatching();
        } catch (_) {}
        channel.dispose();
      }());
    }
    ref.invalidate(matchesProvider);
    ref.invalidate(receivedLikesProvider);
    ref.invalidate(sentLikesProvider);
    ref.invalidate(likesSummaryProvider);
    // Forzar fetch antes de volver para que Chats no muestre el match viejo.
    try {
      await ref.read(matchesProvider.future);
    } catch (_) {}
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chats');
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
      final failure = classifyStreamChatError(
        _error ?? StateError('No se pudo abrir el chat'),
      );
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          title: Text(_petName),
        ),
        body: StreamChatErrorPanel(
          error: _error ?? StateError(failure.message),
          onRetry: _openChannel,
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/chats');
            }
          },
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
            messageComposerLeading: (context, props) {
              return TindogComposerLeading(props: props);
            },
            messageFooter: (context, props) {
              return TindogMessageFooter(props: props);
            },
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
            title: GestureDetector(
              onTap: _openMatchProfile,
              behavior: HitTestBehavior.opaque,
              child: Text(
                _petName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            subtitle: GestureDetector(
              onTap: _openMatchProfile,
              behavior: HitTestBehavior.opaque,
              child: TindogChannelStatus(channel: channel),
            ),
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
                PopupMenuButton<String>(
                  tooltip: 'Más',
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                  ),
                  color: AppColors.card,
                  onSelected: (value) {
                    if (value == 'delete') {
                      unawaited(_deleteConversation());
                    } else if (value == 'profile') {
                      unawaited(_openMatchProfile());
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Text(
                        'Ver perfil',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Eliminar conversación',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChatPresenceAvatar(
                    photoUrl: otherPhoto,
                    streamUserId:
                        widget.thread?.otherPet.ownerUserId ??
                        _ensureOther?.id,
                    radius: 16,
                    onTap: _openMatchProfile,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamMessageListView(
                  messageFilter: (message) {
                    // Oculta soft-deletes ("Message deleted") y shadowed.
                    if (message.isDeleted || message.deletedAt != null) {
                      return false;
                    }
                    final me = StreamChat.of(context).currentUser?.id;
                    final isMine = me != null && message.user?.id == me;
                    if (message.shadowed && !isMine) return false;
                    return true;
                  },
                  config: const StreamMessageListViewConfiguration(
                    swipeToReply: true,
                  ),
                  onReplyTap: (message) {
                    _composerController.quotedMessage = message;
                  },
                  onEditMessageTap: (message) {
                    if (!canEditChatMessage(
                      message,
                      currentUserId:
                          StreamChat.of(context).currentUser?.id,
                    )) {
                      showTindogInfoSnackBar(
                        context,
                        'Solo podés editar durante '
                        '${kChatEditWindow.inMinutes} minutos.',
                      );
                      return;
                    }
                    _composerController.editMessage(message);
                  },
                  messageBuilder: (context, message, props) {
                    final display = _displayMessage(context, message);
                    final me = StreamChat.of(context).currentUser?.id;
                    return DefaultStreamMessageItem(
                      props: props.copyWith(
                        message: display,
                        swipeToReply: true,
                        onReplyTap: (msg) {
                          _composerController.quotedMessage = msg;
                        },
                        onEditMessageTap: (msg) {
                          if (!canEditChatMessage(
                            msg,
                            currentUserId: me,
                          )) {
                            showTindogInfoSnackBar(
                              context,
                              'Solo podés editar durante '
                              '${kChatEditWindow.inMinutes} minutos.',
                            );
                            return;
                          }
                          _composerController.editMessage(msg);
                        },
                        onMessageActions: (ctx, msg) {
                          showTindogMessageActions(
                            context: ctx,
                            message: msg,
                            onEdit: (m) {
                              if (!canEditChatMessage(
                                m,
                                currentUserId: me,
                              )) {
                                showTindogInfoSnackBar(
                                  ctx,
                                  'Solo podés editar durante '
                                  '${kChatEditWindow.inMinutes} minutos.',
                                );
                                return;
                              }
                              _composerController.editMessage(m);
                            },
                            onReply: (m) {
                              _composerController.quotedMessage = m;
                            },
                          );
                        },
                      ),
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
                messageComposerController: _composerController,
                enableVoiceRecording: true,
                onQuotedMessageCleared: _composerController.clearQuotedMessage,
                allowedAttachmentPickerTypes: const [
                  AttachmentPickerType.images,
                  AttachmentPickerType.videos,
                  AttachmentPickerType.command,
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
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vas a ver cuándo está en línea o escribiendo.\n'
              'Elegí una frase o escribí la tuya abajo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.95),
                height: 1.4,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 22),
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
