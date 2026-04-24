import 'package:chess_controller/chess_controller.dart' as chess;
import 'package:flutter_test/flutter_test.dart';

import 'package:knightlink/core/chess_helpers.dart';

void main() {
  test('parses Stockfish UCI move lines', () {
    final payload = bestMovePayloadFromEngineLine('bestmove e2e4 ponder e7e5');

    expect(payload, isNotNull);
    expect(payload!['from'], 'e2');
    expect(payload['to'], 'e4');
    expect(payload['promotion'], isNull);
  });

  test('uses proper unicode chess symbols', () {
    final game = chess.Chess();

    expect(pieceSymbol(game.get('e1')), '\u2654');
    expect(pieceSymbol(game.get('d8')), '\u265B');
  });

  test('builds player-facing status text', () {
    final game = chess.Chess();

    expect(
      playerFacingStatus(
        game,
        playerColor: chess.Color.BLACK,
        opponentName: 'Stockfish',
      ),
      'Stockfish to move.',
    );
  });
}
