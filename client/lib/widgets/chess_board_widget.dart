import 'package:chess_controller/chess_controller.dart' as chess;
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../core/chess_helpers.dart';

class ChessBoardWidget extends StatelessWidget {
  const ChessBoardWidget({
    super.key,
    required this.game,
    required this.whiteBottom,
    required this.onSquareTap,
    this.selectedSquare,
    this.legalTargets = const <String>{},
    this.lastMoveFrom,
    this.lastMoveTo,
    this.interactive = true,
  });

  final chess.Chess game;
  final bool whiteBottom;
  final void Function(String square) onSquareTap;
  final String? selectedSquare;
  final Set<String> legalTargets;
  final String? lastMoveFrom;
  final String? lastMoveTo;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<KnightLinkPalette>()!;
    final files = whiteBottom
        ? const ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']
        : const ['h', 'g', 'f', 'e', 'd', 'c', 'b', 'a'];
    final ranks = whiteBottom
        ? const ['8', '7', '6', '5', '4', '3', '2', '1']
        : const ['1', '2', '3', '4', '5', '6', '7', '8'];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.paperStrong, Colors.white.withValues(alpha: 0.76)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GridView.builder(
              itemCount: 64,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (context, index) {
                final row = index ~/ 8;
                final col = index % 8;
                final square = '${files[col]}${ranks[row]}';
                final squareFile = square.codeUnitAt(0) - 97;
                final squareRank = int.parse(square.substring(1, 2)) - 1;
                final isDark = (squareFile + squareRank).isEven;
                final isSelected = selectedSquare == square;
                final isLastMove =
                    square == lastMoveFrom || square == lastMoveTo;
                final isLegalTarget = legalTargets.contains(square);
                final piece = game.get(square);
                final showMoveRing = isLegalTarget && piece != null;

                Color background = isDark
                    ? const Color(0xFF9D7652)
                    : const Color(0xFFEAD9B4);
                if (isLastMove) {
                  background = Color.alphaBlend(
                    palette.sage.withValues(alpha: 0.55),
                    background,
                  );
                }
                if (isSelected) {
                  background = Color.alphaBlend(
                    palette.terracotta.withValues(alpha: 0.72),
                    background,
                  );
                }

                return Material(
                  color: background,
                  child: InkWell(
                    onTap: interactive ? () => onSquareTap(square) : null,
                    child: Stack(
                      children: [
                        if (col == 0)
                          Positioned(
                            top: 5,
                            left: 6,
                            child: Text(
                              ranks[row],
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.78)
                                    : palette.navy.withValues(alpha: 0.76),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (row == 7)
                          Positioned(
                            right: 7,
                            bottom: 5,
                            child: Text(
                              files[col],
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.78)
                                    : palette.navy.withValues(alpha: 0.76),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (isLegalTarget && piece == null)
                          Center(
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: palette.navy.withValues(alpha: 0.28),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        if (showMoveRing)
                          Center(
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: palette.navy.withValues(alpha: 0.42),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        Center(
                          child: Text(
                            pieceSymbol(piece),
                            style: const TextStyle(
                              fontSize: 34,
                              height: 1,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Color(0x15000000),
                                  offset: Offset(0, 2),
                                ),
                              ],
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
        ),
      ),
    );
  }
}
