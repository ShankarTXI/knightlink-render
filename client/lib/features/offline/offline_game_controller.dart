import 'dart:async';

import 'package:chess_controller/chess_controller.dart' as chess;
import 'package:flutter/material.dart';
import 'package:stockfish_flutter_plus/stockfish_flutter_plus.dart';

import '../../core/chess_helpers.dart';

class OfflineGameController extends ChangeNotifier {
  OfflineGameController({chess.Color initialPlayerColor = chess.Color.WHITE})
    : _playerColor = initialPlayerColor {
    whiteBottom = initialPlayerColor == chess.Color.WHITE;
  }

  final chess.Chess game = chess.Chess();
  chess.Color _playerColor;

  Stockfish? _stockfish;
  StreamSubscription<String>? _stdoutSubscription;
  VoidCallback? _engineStateListener;

  String? selectedSquare;
  Set<String> legalTargets = <String>{};
  bool whiteBottom = true;
  bool engineReady = false;
  bool thinking = false;
  int difficulty = 4;
  String statusMessage = 'Starting Stockfish...';
  String? lastMoveFrom;
  String? lastMoveTo;

  List<String> get moveHistory => List<String>.from(game.getHistory());

  chess.Color get playerColor => _playerColor;

  chess.Color get engineColor =>
      _playerColor == chess.Color.WHITE ? chess.Color.BLACK : chess.Color.WHITE;

  void init() {
    try {
      _stockfish = Stockfish();
      _stdoutSubscription = _stockfish!.stdout.listen(_handleEngineLine);
      _engineStateListener = _handleEngineStateChanged;
      _stockfish!.state.addListener(_engineStateListener!);
      _handleEngineStateChanged();
    } catch (error) {
      statusMessage = 'Engine failed to start: $error';
      notifyListeners();
    }
  }

  bool get canInteract {
    return engineReady &&
        !thinking &&
        !game.game_over &&
        game.turn == _playerColor;
  }

  String get engineBadge {
    if (!engineReady) {
      return 'Engine starting';
    }
    if (thinking) {
      return 'Stockfish thinking';
    }
    return 'Stockfish ready';
  }

  void setDifficulty(int value) {
    difficulty = value;
    _sendUci('setoption name Skill Level value $_skillLevel');
    notifyListeners();
  }

  void setPlayerColor(chess.Color value) {
    if (_playerColor == value) {
      return;
    }

    _playerColor = value;
    whiteBottom = value == chess.Color.WHITE;
    reset();
  }

  void flipBoard() {
    whiteBottom = !whiteBottom;
    notifyListeners();
  }

  void reset() {
    _sendUci('stop');
    thinking = false;
    selectedSquare = null;
    legalTargets = <String>{};
    lastMoveFrom = null;
    lastMoveTo = null;
    game.reset();
    _sendUci('ucinewgame');
    _sendUci('setoption name Skill Level value $_skillLevel');
    _sendUci('isready');
    if (!_syncTurnState()) {
      notifyListeners();
    }
  }

  Future<void> handleSquareTap(BuildContext context, String square) async {
    if (!canInteract) {
      return;
    }

    final piece = game.get(square);
    final isHumanPiece =
        piece != null &&
        piece.color == _playerColor &&
        game.turn == _playerColor;

    if (selectedSquare != null) {
      if (selectedSquare == square) {
        _clearSelection();
        return;
      }

      final options = moveChoicesForSquare(
        game,
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

        _commitMove(
          from: selectedSquare!,
          to: square,
          promotion: promotion,
          requestReply: true,
        );
        return;
      }
    }

    if (isHumanPiece) {
      selectedSquare = square;
      legalTargets = moveChoicesForSquare(
        game,
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
      backgroundColor: Colors.white,
      showDragHandle: true,
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

  void _commitMove({
    required String from,
    required String to,
    String? promotion,
    required bool requestReply,
  }) {
    final move = <String, String>{'from': from, 'to': to};
    if (promotion != null) {
      move['promotion'] = promotion;
    }

    final applied = game.move(move);
    _clearSelection(notify: false);

    if (!applied) {
      statusMessage = 'That move is not legal.';
      notifyListeners();
      return;
    }

    lastMoveFrom = from;
    lastMoveTo = to;
    statusMessage = playerFacingStatus(
      game,
      playerColor: _playerColor,
      opponentName: 'Stockfish',
    );
    notifyListeners();

    if (requestReply && !game.game_over) {
      _requestEngineReply();
    }
  }

  void _requestEngineReply() {
    if (!engineReady || game.game_over) {
      return;
    }

    thinking = true;
    statusMessage = 'Stockfish is thinking...';
    notifyListeners();
    _sendUci('setoption name Skill Level value $_skillLevel');
    _sendUci('position fen ${game.generate_fen()}');
    _sendUci('go movetime $_moveTimeMs');
  }

  int get _skillLevel => difficulty <= 1 ? 1 : (difficulty * 3).clamp(1, 20);

  int get _moveTimeMs => 400 + (difficulty * 250);

  void _handleEngineStateChanged() {
    final ready = _stockfish?.state.value == StockfishState.ready;
    if (ready == engineReady) {
      return;
    }

    engineReady = ready;
    if (engineReady) {
      _configureEngine();
      if (_syncTurnState()) {
        return;
      }
    } else {
      statusMessage = 'Starting Stockfish...';
    }
    notifyListeners();
  }

  void _configureEngine() {
    _sendUci('uci');
    _sendUci('setoption name Threads value 1');
    _sendUci('setoption name Hash value 16');
    _sendUci('setoption name Skill Level value $_skillLevel');
    _sendUci('ucinewgame');
    _sendUci('isready');
  }

  void _handleEngineLine(String line) {
    final payload = bestMovePayloadFromEngineLine(line);
    if (payload == null || !thinking) {
      return;
    }

    thinking = false;
    _commitMove(
      from: payload['from']!,
      to: payload['to']!,
      promotion: payload['promotion'],
      requestReply: false,
    );
  }

  void _sendUci(String command) {
    final engine = _stockfish;
    if (engine == null || engine.state.value != StockfishState.ready) {
      return;
    }

    try {
      engine.stdin = command;
    } catch (_) {
      // If the engine is transitioning state, we can safely ignore the command.
    }
  }

  bool _syncTurnState() {
    if (!engineReady) {
      statusMessage = 'Starting Stockfish...';
      return false;
    }
    if (thinking || game.game_over) {
      statusMessage = playerFacingStatus(
        game,
        playerColor: _playerColor,
        opponentName: 'Stockfish',
      );
      return false;
    }
    if (game.turn == _playerColor) {
      statusMessage = playerFacingStatus(
        game,
        playerColor: _playerColor,
        opponentName: 'Stockfish',
      );
      return false;
    }
    _requestEngineReply();
    return true;
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
    _stdoutSubscription?.cancel();
    if (_stockfish != null && _engineStateListener != null) {
      _stockfish!.state.removeListener(_engineStateListener!);
    }
    try {
      if (_stockfish?.state.value == StockfishState.ready) {
        _stockfish!.dispose();
      }
    } catch (_) {
      // Ignore teardown errors during hot restart or widget disposal.
    }
    super.dispose();
  }
}
