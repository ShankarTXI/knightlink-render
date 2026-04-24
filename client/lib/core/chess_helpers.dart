import 'package:chess_controller/chess_controller.dart' as chess;

class MoveChoice {
  const MoveChoice({required this.from, required this.to, this.promotion});

  final String from;
  final String to;
  final String? promotion;
}

List<MoveChoice> moveChoicesForSquare(chess.Chess game, String square) {
  final moves = game.generate_moves({'square': square});
  return moves
      .map<MoveChoice>(
        (dynamic move) => MoveChoice(
          from: move.fromAlgebraic as String,
          to: move.toAlgebraic as String,
          promotion: move.promotion?.name as String?,
        ),
      )
      .toList(growable: false);
}

String prettySide(chess.Color color) {
  return color == chess.Color.WHITE ? 'White' : 'Black';
}

String statusForGame(chess.Chess game) {
  if (game.in_checkmate) {
    final winner = game.turn == chess.Color.WHITE ? 'Black' : 'White';
    return 'Checkmate. $winner wins.';
  }
  if (game.in_stalemate) {
    return 'Stalemate. Nobody can move.';
  }
  if (game.insufficient_material) {
    return 'Draw by insufficient material.';
  }
  if (game.in_threefold_repetition) {
    return 'Draw by repetition.';
  }
  if (game.in_draw) {
    return 'Draw.';
  }
  if (game.in_check) {
    return '${prettySide(game.turn)} is in check.';
  }
  return '${prettySide(game.turn)} to move.';
}

String playerFacingStatus(
  chess.Chess game, {
  required chess.Color playerColor,
  required String opponentName,
}) {
  if (game.in_checkmate) {
    final playerWon = game.turn != playerColor;
    return playerWon ? 'Checkmate. You win.' : 'Checkmate. $opponentName wins.';
  }
  if (game.in_stalemate) {
    return 'Draw by stalemate.';
  }
  if (game.insufficient_material) {
    return 'Draw by insufficient material.';
  }
  if (game.in_threefold_repetition) {
    return 'Draw by repetition.';
  }
  if (game.in_draw) {
    return 'Draw.';
  }
  if (game.in_check) {
    return game.turn == playerColor
        ? 'You are in check.'
        : '$opponentName is in check.';
  }
  return game.turn == playerColor ? 'Your move.' : '$opponentName to move.';
}

Map<String, String?>? bestMovePayloadFromEngineLine(String line) {
  if (!line.startsWith('bestmove ')) {
    return null;
  }

  final pieces = line.split(' ');
  if (pieces.length < 2 || pieces[1] == '(none)') {
    return null;
  }

  return movePayloadFromUci(pieces[1]);
}

Map<String, String?> movePayloadFromUci(String uciMove) {
  final trimmed = uciMove.trim();
  if (trimmed.length < 4) {
    throw ArgumentError.value(uciMove, 'uciMove', 'Invalid UCI move.');
  }

  return <String, String?>{
    'from': trimmed.substring(0, 2),
    'to': trimmed.substring(2, 4),
    'promotion': trimmed.length > 4 ? trimmed.substring(4, 5) : null,
  };
}

String pieceSymbol(chess.Piece? piece) {
  if (piece == null) {
    return '';
  }

  final isWhite = piece.color == chess.Color.WHITE;
  if (piece.type == chess.PieceType.KING) {
    return isWhite ? '\u2654' : '\u265A';
  }
  if (piece.type == chess.PieceType.QUEEN) {
    return isWhite ? '\u2655' : '\u265B';
  }
  if (piece.type == chess.PieceType.ROOK) {
    return isWhite ? '\u2656' : '\u265C';
  }
  if (piece.type == chess.PieceType.BISHOP) {
    return isWhite ? '\u2657' : '\u265D';
  }
  if (piece.type == chess.PieceType.KNIGHT) {
    return isWhite ? '\u2658' : '\u265E';
  }
  return isWhite ? '\u2659' : '\u265F';
}

String promotionLabel(String promotion) {
  switch (promotion) {
    case 'q':
      return 'Queen';
    case 'r':
      return 'Rook';
    case 'b':
      return 'Bishop';
    case 'n':
      return 'Knight';
    default:
      return promotion.toUpperCase();
  }
}
