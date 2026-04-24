import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app/app_theme.dart';
import '../../widgets/chess_board_widget.dart';
import 'online_game_controller.dart';
import 'online_service.dart';
import 'models.dart';

class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({
    super.key,
    required this.session,
    required this.service,
  });

  final OnlineSession session;
  final OnlineService service;

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  late final OnlineGameController controller;
  late final TextEditingController messageController;
  late final ScrollController chatScrollController;
  int _lastChatCount = 0;
  bool sendingMessage = false;

  @override
  void initState() {
    super.initState();
    controller = OnlineGameController(
      session: widget.session,
      service: widget.service,
    )..init();
    controller.addListener(_handleControllerUpdate);
    messageController = TextEditingController();
    chatScrollController = ScrollController();
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerUpdate);
    messageController.dispose();
    chatScrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _handleControllerUpdate() {
    final chatCount = controller.chatMessages.length;
    if (chatCount != _lastChatCount) {
      _lastChatCount = chatCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollChatToBottom(animated: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<KnightLinkPalette>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Room ${widget.session.roomCode}'),
        actions: [
          IconButton(
            tooltip: 'Copy room code',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(
                ClipboardData(text: widget.session.roomCode),
              );
              if (!mounted) {
                return;
              }
              messenger.showSnackBar(
                const SnackBar(content: Text('Room code copied.')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.transientError != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(controller.transientError!)),
              );
              controller.clearTransientError();
            });
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final boardSize = math.min(constraints.maxWidth - 32, 520.0);
              final recentMoves = controller.moveHistory.reversed
                  .take(12)
                  .toList();

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      controller.statusMessage,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.sage.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      'You are ${widget.session.color == 'white' ? 'White' : 'Black'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(color: palette.sage),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _PlayerLine(
                                label: 'White',
                                player: controller.room?.whitePlayer,
                                placeholder:
                                    controller.room == null &&
                                        controller.connecting
                                    ? 'Connecting...'
                                    : 'Open seat',
                              ),
                              const SizedBox(height: 8),
                              _PlayerLine(
                                label: 'Black',
                                player: controller.room?.blackPlayer,
                                placeholder:
                                    controller.room == null &&
                                        controller.connecting
                                    ? 'Connecting...'
                                    : 'Open seat',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: SizedBox(
                          width: boardSize,
                          child: ChessBoardWidget(
                            game: controller.currentGame,
                            whiteBottom: controller.whiteBottom,
                            selectedSquare: controller.selectedSquare,
                            legalTargets: controller.legalTargets,
                            lastMoveFrom: controller.room?.lastMoveFrom,
                            lastMoveTo: controller.room?.lastMoveTo,
                            interactive: controller.canMove,
                            onSquareTap: (square) =>
                                controller.handleSquareTap(context, square),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Moves',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              if (recentMoves.isEmpty)
                                Text(
                                  'No moves yet.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: recentMoves
                                      .map(
                                        (move) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE1D7CA),
                                            ),
                                          ),
                                          child: Text(move),
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 320,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Room chat',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: controller.chatMessages.isEmpty
                                      ? Center(
                                          child: Text(
                                            'Messages in this room stay between the two players.',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        )
                                      : ListView.builder(
                                          controller: chatScrollController,
                                          itemCount:
                                              controller.chatMessages.length,
                                          itemBuilder: (context, index) {
                                            final message =
                                                controller.chatMessages[index];
                                            final mine =
                                                message.senderId ==
                                                widget.session.playerId;
                                            return Align(
                                              alignment: message.system
                                                  ? Alignment.center
                                                  : mine
                                                  ? Alignment.centerRight
                                                  : Alignment.centerLeft,
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                constraints:
                                                    const BoxConstraints(
                                                      maxWidth: 280,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: message.system
                                                      ? const Color(0xFFF0E6D7)
                                                      : mine
                                                      ? palette.navy
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: message.system
                                                      ? null
                                                      : Border.all(
                                                          color: const Color(
                                                            0xFFE2D8CB,
                                                          ),
                                                        ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      message.system
                                                          ? 'System'
                                                          : message.senderName,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelLarge
                                                          ?.copyWith(
                                                            color:
                                                                message.system
                                                                ? palette.navy
                                                                : mine
                                                                ? Colors.white
                                                                : palette.navy,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      message.message,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color:
                                                                message.system
                                                                ? palette.navy
                                                                : mine
                                                                ? Colors.white
                                                                : null,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      DateFormat.Hm().format(
                                                        message.createdAt
                                                            .toLocal(),
                                                      ),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color:
                                                                message.system
                                                                ? palette.navy
                                                                      .withValues(
                                                                        alpha:
                                                                            0.7,
                                                                      )
                                                                : mine
                                                                ? Colors.white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.7,
                                                                      )
                                                                : palette.ink
                                                                      .withValues(
                                                                        alpha:
                                                                            0.6,
                                                                      ),
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: messageController,
                                        maxLength: 280,
                                        enabled: !sendingMessage,
                                        decoration: const InputDecoration(
                                          counterText: '',
                                          hintText: 'Type a message',
                                        ),
                                        textInputAction: TextInputAction.send,
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    FilledButton(
                                      onPressed: sendingMessage
                                          ? null
                                          : _sendMessage,
                                      child: Text(
                                        sendingMessage ? 'Sending...' : 'Send',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || sendingMessage) {
      return;
    }
    setState(() {
      sendingMessage = true;
    });
    final sent = await controller.sendChat(text);
    if (!mounted) {
      return;
    }
    setState(() {
      sendingMessage = false;
    });
    if (!sent) {
      return;
    }
    messageController.clear();
    _scrollChatToBottom(animated: true);
  }

  void _scrollChatToBottom({required bool animated}) {
    if (!chatScrollController.hasClients) {
      return;
    }
    final offset = chatScrollController.position.maxScrollExtent;
    if (animated) {
      chatScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    chatScrollController.jumpTo(offset);
  }
}

class _PlayerLine extends StatelessWidget {
  const _PlayerLine({
    required this.label,
    required this.player,
    required this.placeholder,
  });

  final String label;
  final RoomPlayer? player;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<KnightLinkPalette>()!;
    final connected = player?.connected ?? false;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: connected ? palette.sage : palette.terracotta,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ${player?.name ?? placeholder}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
