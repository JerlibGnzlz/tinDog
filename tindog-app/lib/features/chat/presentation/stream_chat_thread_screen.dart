import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tindog_brand_atmosphere.dart';
import '../../../shared/widgets/tindog_loader.dart';
import '../../matching/data/chat_models.dart';
import '../../matching/data/discover_candidate.dart';
import '../../matching/presentation/chats_providers.dart';
import '../../matching/presentation/likes_providers.dart';
import '../../matching/presentation/delete_conversation.dart';
import '../../notifications/data/devices_repository.dart';
import '../../notifications/presentation/push_notifications.dart';
import '../../safety/presentation/safety_sheets.dart';
import '../data/chat_repository.dart';
import 'stream_chat_errors.dart';
import 'stream_chat_providers.dart';
import 'widgets/channel_search_sheet.dart';
import 'widgets/chat_presence_avatar.dart';
import 'widgets/chat_time_format.dart';
import 'widgets/match_profile_sheet.dart';
import 'widgets/stream_chat_error_panel.dart';
import 'widgets/stream_chat_icebreakers.dart';
import 'widgets/tindog_channel_status.dart';
import 'widgets/tindog_chat_attachments.dart';
import 'widgets/tindog_composer_emoji.dart';
import 'widgets/tindog_composer_input_center.dart';
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

class _StreamChatThreadScreenState extends ConsumerState<StreamChatThreadScreen>
    with WidgetsBindingObserver {
  Channel? _channel;
  Object? _error;
  bool _loading = true;
  StreamChatUserDto? _ensureOther;
  Map<String, StreamChatUserDto> _membersById = const {};
  final _composerController = StreamMessageComposerController();
  StreamSubscription<Event>? _readSub;
  Timer? _activeChatHeartbeat;
  /// Mensaje al que saltar tras Buscar (Stream lo usa + highlight en la lista).
  String? _jumpToMessageId;
  int _messageListEpoch = 0;

  String get _petName =>
      widget.thread?.otherPet.name ?? _ensureOther?.name ?? 'Chat';

  /// Dueño humano (para el subtítulo del header).
  String? get _ownerName {
    final fromThread = widget.thread?.otherPet.ownerName?.trim();
    if (fromThread != null && fromThread.isNotEmpty) return fromThread;

    final ownerId = widget.thread?.otherPet.ownerUserId ?? _ensureOther?.id;
    if (ownerId != null) {
      final fromMember = _membersById[ownerId]?.name.trim();
      if (fromMember != null &&
          fromMember.isNotEmpty &&
          fromMember != _petName) {
        return fromMember;
      }
    }

    final fromEnsure = _ensureOther?.name.trim();
    if (fromEnsure != null &&
        fromEnsure.isNotEmpty &&
        fromEnsure != _petName) {
      return fromEnsure;
    }
    return null;
  }

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
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openChannel());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _readSub?.cancel();
    _stopActiveChatPresence();
    final channel = _channel;
    if (channel != null) {
      unawaited(_markChannelRead(channel));
    }
    _composerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al minimizar, liberar "chat activo" para que lleguen pushes.
    switch (state) {
      case AppLifecycleState.resumed:
        if (_channel != null && !_loading && _error == null) {
          _startActiveChatPresence();
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _stopActiveChatPresence();
      case AppLifecycleState.inactive:
        // No clear acá: al abrir el teclado/shade también pasa por inactive.
        break;
    }
  }

  void _startActiveChatPresence() {
    _activeChatHeartbeat?.cancel();
    final matchId = widget.matchId;
    final devices = ref.read(devicesRepositoryProvider);
    ref.read(pushNotificationsProvider).setActiveMatchId(matchId);
    unawaited(devices.setActiveChat(matchId));
    // < TTL Nest (75s): si el clear al salir falla, el skip no dura minutos.
    _activeChatHeartbeat = Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(devices.setActiveChat(matchId));
    });
  }

  void _stopActiveChatPresence() {
    _activeChatHeartbeat?.cancel();
    _activeChatHeartbeat = null;
    // Local primero (banner foreground); Nest enseguida (FCM background).
    ref.read(pushNotificationsProvider).setActiveMatchId(null);
    unawaited(ref.read(devicesRepositoryProvider).setActiveChat(null));
  }

  Future<void> _markChannelRead(Channel channel) async {
    try {
      await channel.markRead();
    } catch (_) {
      // Best-effort.
    }
  }

  /// Presencia + leído + listeners sin bloquear “Abriendo chat…”.
  Future<void> _warmupChannelPresence(
    StreamChatClient client,
    Channel channel,
    Map<String, StreamChatUserDto> membersById,
  ) async {
    final memberIds = membersById.keys.toList(growable: false);
    if (memberIds.isNotEmpty) {
      try {
        await client.queryUsers(
          filter: Filter.in_('id', memberIds),
          presence: true,
        );
      } catch (_) {}
    }

    await _markChannelRead(channel);

    await _readSub?.cancel();
    _readSub = channel.on().listen((event) {
      final type = event.type;
      if (type == EventType.messageNew ||
          type == EventType.notificationMessageNew) {
        unawaited(_markChannelRead(channel));
      }
      if (type == EventType.userPresenceChanged ||
          type == EventType.userUpdated) {
        if (memberIds.isNotEmpty) {
          unawaited(
            client.queryUsers(
              filter: Filter.in_('id', memberIds),
              presence: true,
            ),
          );
        }
      }
    });
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
      // Solo watch bloquea la UI; presencia / leído van en background.
      await channel.watch(presence: true);

      final membersById = {
        for (final m in ensured.members) m.id: m,
      };

      if (!mounted) return;
      _startActiveChatPresence();
      // Sync mute Stream → Nest (por si el canal ya estaba muteado).
      if (channel.isMuted) {
        unawaited(
          ref.read(devicesRepositoryProvider).setChatMuted(
                matchId: widget.matchId,
                muted: true,
              ),
        );
      }
      setState(() {
        _channel = channel;
        _ensureOther = ensured.other;
        _membersById = membersById;
        _loading = false;
      });

      unawaited(_warmupChannelPresence(client, channel, membersById));
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
    return withVisibleMediaAttachments(withSender);
  }

  Future<void> _toggleMuteChat() async {
    final channel = _channel;
    if (channel == null) return;
    final muted = channel.isMuted;
    try {
      if (muted) {
        await channel.unmute();
      } else {
        await channel.mute();
      }
      await ref.read(devicesRepositoryProvider).setChatMuted(
            matchId: widget.matchId,
            muted: !muted,
          );
      if (!mounted) return;
      showTindogInfoSnackBar(
        context,
        muted ? 'Notificaciones activadas' : 'Chat silenciado',
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      showTindogErrorSnackBar(context, readableError(e));
    }
  }

  void _leaveChat() {
    // Preferí go_router: maybePop a veces no hace nada si el focus/IME
    // o el árbol de Stream absorbe el gesto.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chats');
    }
  }

  Future<void> _openSearch() async {
    final channel = _channel;
    if (channel == null) return;
    final messageId = await showChannelSearchSheet(
      context: context,
      channel: channel,
    );
    if (!mounted || messageId == null || messageId.isEmpty) return;
    setState(() {
      _jumpToMessageId = messageId;
      _messageListEpoch++;
    });
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
        backgroundColor: Colors.transparent,
        body: TindogBrandAtmosphere(
          kind: TindogAtmosphereKind.shell,
          child: Center(
            child: TindogLoader(message: 'Abriendo chat…'),
          ),
        ),
      );
    }

    if (_error != null || _channel == null) {
      final failure = classifyStreamChatError(
        _error ?? StateError('No se pudo abrir el chat'),
      );
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: TindogBrandAtmosphere(
          kind: TindogAtmosphereKind.shell,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
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
          ),
        ),
      );
    }

    final channel = _channel!;
    final otherPhoto = _otherPhoto;
    final otherName = _petName;

    return StreamChannel(
      channel: channel,
      // Canal ya viene de watch en _openChannel; evitar flash al saltar.
      showLoading: false,
      initialMessageId: _jumpToMessageId,
      child: StreamComponentFactory(
        builders: StreamComponentBuilders(
          extensions: streamChatComponentBuilders(
            messageComposerLeading: (context, props) {
              return TindogComposerLeading(props: props);
            },
            messageComposerInputCenter: (context, props) {
              return TindogComposerInputCenter(props: props);
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
        child: TindogBrandAtmosphere(
          kind: TindogAtmosphereKind.shell,
          child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Volver',
              onPressed: _leaveChat,
            ),
            titleSpacing: 0,
            title: InkWell(
              onTap: _openMatchProfile,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _petName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    TindogChannelStatus(
                      channel: channel,
                      ownerName: _ownerName,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Seguridad',
                onPressed: () => unawaited(_openSafety()),
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
                  } else if (value == 'search') {
                    unawaited(_openSearch());
                  } else if (value == 'mute') {
                    unawaited(_toggleMuteChat());
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
                  const PopupMenuItem(
                    value: 'search',
                    child: Text(
                      'Buscar en el chat',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'mute',
                    child: Text(
                      channel.isMuted
                          ? 'Activar notificaciones'
                          : 'Silenciar notificaciones',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Eliminar match',
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
          body: Column(
            children: [
              Expanded(
                child: StreamMessageListView(
                  // Remonta para que Stream ejecute scroll+highlight al mensaje.
                  key: ValueKey('mlv-$_messageListEpoch'),
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
                  config: StreamMessageListViewConfiguration(
                    swipeToReply: true,
                    showFloatingDateDivider: true,
                    highlightInitialMessage: _jumpToMessageId != null,
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
                    // Sin chip "Hoy"; sí Ayer / fechas anteriores.
                    dateDivider: _chatDateDivider,
                    floatingDateDivider: _chatDateDivider,
                  ),
                ),
              ),
              if (channel.isMuted)
                Material(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_off_outlined,
                          size: 18,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Notificaciones silenciadas',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => unawaited(_toggleMuteChat()),
                          child: const Text('Activar'),
                        ),
                      ],
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
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

Widget _chatDateDivider(DateTime date) {
  if (isSameCalendarDay(date, DateTime.now())) {
    return const SizedBox.shrink();
  }
  return StreamDateDivider(
    dateTime: date,
    backgroundColor: AppColors.card,
    textStyle: const TextStyle(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w700,
      fontSize: 12,
    ),
  );
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_rounded,
            size: 36,
            color: AppColors.primary.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 10),
          Text(
            '¡Match con $petName!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Elegí una frase o escribí la tuya abajo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.95),
              height: 1.35,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          StreamChatIcebreakers(
            channel: channel,
            wrap: true,
            compact: true,
            maxItems: 3,
          ),
        ],
      ),
    );
  }
}
