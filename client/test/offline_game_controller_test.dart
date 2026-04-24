import 'package:chess_controller/chess_controller.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:knightlink/features/offline/offline_game_controller.dart';

void main() {
  test('switching to black resets the offline game and board orientation', () {
    final controller = OfflineGameController();

    controller.game.move({'from': 'e2', 'to': 'e4'});
    controller.setPlayerColor(chess.Color.BLACK);

    expect(controller.playerColor, chess.Color.BLACK);
    expect(controller.whiteBottom, isFalse);
    expect(
      controller.game.generate_fen(),
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    );

    controller.dispose();
  });
}
