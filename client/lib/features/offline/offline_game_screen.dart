import 'dart:math' as math;

import 'package:chess_controller/chess_controller.dart' as chess;
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/chess_helpers.dart';
import '../../widgets/chess_board_widget.dart';
import 'offline_game_controller.dart';

class OfflineGameScreen extends StatefulWidget {
  const OfflineGameScreen({super.key});

  @override
  State<OfflineGameScreen> createState() => _OfflineGameScreenState();
}

class _OfflineGameScreenState extends State<OfflineGameScreen> {
  late final OfflineGameController controller;

  @override
  void initState() {
    super.initState();
    controller = OfflineGameController()..init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<KnightLinkPalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Offline vs Stockfish')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final boardSize = math.min(constraints.maxWidth - 32, 520.0);
              final recentMoves = controller.moveHistory.reversed
                  .take(12)
                  .toList();

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          controller.statusMessage,
                                          style: textTheme.headlineSmall,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'You have ${prettySide(controller.playerColor)}. Stockfish has ${prettySide(controller.engineColor)}.',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: palette.ink.withValues(
                                              alpha: 0.74,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _StatusPill(
                                    label: controller.engineBadge,
                                    color: controller.engineReady
                                        ? palette.sage
                                        : palette.terracotta,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _InfoPill(
                                    label: 'Side',
                                    value: prettySide(controller.playerColor),
                                  ),
                                  _InfoPill(
                                    label: 'Level',
                                    value: controller.difficulty.toString(),
                                  ),
                                  _InfoPill(
                                    label: 'Board',
                                    value: controller.whiteBottom
                                        ? 'White bottom'
                                        : 'Black bottom',
                                  ),
                                ],
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
                            game: controller.game,
                            whiteBottom: controller.whiteBottom,
                            selectedSquare: controller.selectedSquare,
                            legalTargets: controller.legalTargets,
                            lastMoveFrom: controller.lastMoveFrom,
                            lastMoveTo: controller.lastMoveTo,
                            interactive: controller.canInteract,
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
                              Text('Game setup', style: textTheme.titleLarge),
                              const SizedBox(height: 14),
                              SegmentedButton<chess.Color>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment<chess.Color>(
                                    value: chess.Color.WHITE,
                                    label: Text('Play White'),
                                  ),
                                  ButtonSegment<chess.Color>(
                                    value: chess.Color.BLACK,
                                    label: Text('Play Black'),
                                  ),
                                ],
                                selected: <chess.Color>{controller.playerColor},
                                onSelectionChanged: (selection) {
                                  controller.setPlayerColor(selection.first);
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Changing side starts a fresh game.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: palette.ink.withValues(alpha: 0.66),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                initialValue: controller.difficulty,
                                items: List.generate(
                                  8,
                                  (index) => DropdownMenuItem<int>(
                                    value: index + 1,
                                    child: Text('Level ${index + 1}'),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.setDifficulty(value);
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Stockfish strength',
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  FilledButton(
                                    onPressed: controller.reset,
                                    child: const Text('New game'),
                                  ),
                                  OutlinedButton(
                                    onPressed: controller.flipBoard,
                                    child: const Text('Flip board'),
                                  ),
                                ],
                              ),
                            ],
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
                              Text('Moves', style: textTheme.titleLarge),
                              const SizedBox(height: 12),
                              if (recentMoves.isEmpty)
                                Text(
                                  'No moves yet.',
                                  style: textTheme.bodyMedium,
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
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE0D5C7),
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
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<KnightLinkPalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4D8C9)),
      ),
      child: RichText(
        text: TextSpan(
          style: textTheme.bodySmall?.copyWith(color: palette.ink),
          children: [
            TextSpan(
              text: '$label ',
              style: textTheme.labelLarge?.copyWith(color: palette.navy),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
