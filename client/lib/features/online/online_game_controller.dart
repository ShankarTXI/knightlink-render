import 'package:chess_controller/chess_controller.dart' as chess;
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/chess_helpers.dart';
import 'models.dart';
import 'online_service.dart';

class OnlineGameController extends ChangeNotifier {
  OnlineGameController({required this.session, required this.service});

  final OnlineSession session;
  final OnlineService service;

  io.Socket? _socket;
  chess.Chess currentGame = chess.Chess();
  RoomSnapshot? room;

  String? selectedSquare;
  Set<String> legalTargets = <String>{};
  bool connecting = true;
  String? transientError;

  RoomPlayer? get me =>
      session.color == 'white' ? room?.whitePlayer : room?.blackPlayer;

  RoomPlayer? get opponent =>
      session.color == 'white' ? room?.blackPlayer : room?.whitePlayer;

  bool get canMove {
    return room != null &&
        room!.status == 'active' &&
        room!.turn == session.turnKey &&
        room!.result == null;
  }

  bool get whiteBottom => session.color == 'white';

  String get statusMessage {
    final snapshot = room;
    if (snapshot == null) {
      return connecting ? 'Connecting to room...' : 'Waiting for room state...';
    }

    if (snapshot.status == 'waiting') {
      return 'Waiting for someone to join room ${snapshot.roomCode}.';
    }
    if (snapshot.result != null && snapshot.result!.trim().isNotEmpty) {
      return snapshot.result!;
    }
    if (snapshot.status == 'finished') {
      return 'Game finished.';
    }
    final myColor = session.color == 'white'
        ? chess.Color.WHITE
        : chess.Color.BLACK;
    return playerFacingStatus(
      currentGame,
      playerColor: myColor,
      opponentName: opponent?.name ?? 'Your friend',
    );
  }

  List<String> get moveHistory => room?.moveHistory ?? const [];

  List<ChatMessage> get chatMessages => room?.chat ?? const [];

  void init() {
    _socket = service.connect(
      session,
      onState: _applyState,
      onError: (message) {
        transientError = message;
        notifyListeners();
      },
      onConnected: () {
        connecting = false;
        notifyListeners();
      },
      onDisconnected: () {
        connecting = false;
        transientError = 'Disconnected from the server.';
        notifyListeners();
      },
    );
  }

  Future<void> handleSquareTap(BuildContext context, String square) async {
    if (!canMove) {
      return;
    }

    final piece = currentGame.get(square);
    final myColor = session.color == 'white'
        ? chess.Color.WHITE
        : chess.Color.BLACK;
    final isMyPiece = piece != null && piece.color == myColor;

    if (selectedSquare != null) {
      if (selectedSquare == square) {
        _clearSelection();
        return;
      }

      final options = moveChoicesForSquare(
        currentGame,
        selectedSquare!,
      ).where((choice) => choice.to == square).toList(growable: false);
      if (options.isNotEmpty) {
        String? promotion = options.first.promotion;
        if (options.any((choice) => choice.promotion != null)) {
          promotion = await _askPromotionChoice(context);
          if (promotion == null) {
            return;
          }
        }
        try {
          await service.sendMove(
            _socket!,
            from: selectedSquare!,
            to: square,
            promotion: promotion,
          );
          _clearSelection();
        } catch (error) {
          transientError = error.toString().replaceFirst('Exception: ', '');
          notifyListeners();
        }
        return;
      }
    }

    if (isMyPiece) {
      selectedSquare = square;
      legalTargets = moveChoicesForSquare(
        currentGame,
        square,
      ).map((choice) => choice.to).toSet();
      notifyListeners();
      return;
    }

    _clearSelection();
  }

  Future<String?> _askPromotionChoice(BuildContext context) {
    const promotions = ['q', 'r', 'b', 'n'];
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose promotion',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: promotions
                      .map(
                        (promotion) => OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(promotion),
                          child: Text(promotionLabel(promotion)),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> sendChat(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _socket == null) {
      transientError = 'Type a message before sending.';
      notifyListeners();
      return false;
    }
    if (_socket!.disconnected) {
      transientError = 'Chat is unavailable until the room reconnects.';
      notifyListeners();
      return false;
    }
    try {
      await service.sendChat(_socket!, trimmed);
      return true;
    } catch (error) {
      transientError = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearTransientError() {
    if (transientError == null) {
      return;
    }
    transientError = null;
    notifyListeners();
  }

  void _applyState(RoomSnapshot snapshot) {
    room = snapshot;
    currentGame = chess.Chess.fromFEN(snapshot.fen);
    if (selectedSquare != null && currentGame.get(selectedSquare!) == null) {
      _clearSelection(notify: false);
    }
    transientError = null;
    notifyListeners();
  }

  void _clearSelection({bool notify = true}) {
    selectedSquare = null;
    legalTargets = <String>{};
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    service.disconnect(_socket);
    super.dispose();
  }
}
