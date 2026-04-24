import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../offline/offline_game_screen.dart';
import '../online/online_lobby_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<KnightLinkPalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              palette.paperStrong,
              palette.paper,
              const Color(0xFFE7DED1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.navy,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: palette.navy.withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              'assets/branding/knightlink_icon.png',
                              width: 58,
                              height: 58,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KnightLink',
                                  style: textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Private chess for two, or a quick game against Stockfish.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _HeroChip(label: 'Private room codes'),
                          _HeroChip(label: 'Built-in chat'),
                          _HeroChip(label: 'Offline engine'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text('Pick a game', style: textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'The app keeps things simple: private rooms for friends, or one clean offline board against the engine.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: palette.ink.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 18),
                _ModeCard(
                  icon: Icons.wifi_tethering_rounded,
                  eyebrow: 'Online',
                  title: 'Play with a friend',
                  body:
                      'Create a room, share the code, and play with live chat.',
                  accent: palette.sage,
                  actionLabel: 'Play online',
                  meta: const ['Private room', 'White / Black assigned'],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OnlineLobbyScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _ModeCard(
                  icon: Icons.smart_toy_outlined,
                  eyebrow: 'Offline',
                  title: 'Play against Stockfish',
                  body:
                      'Choose your side, set the engine level, and start right away.',
                  accent: palette.terracotta,
                  actionLabel: 'Play offline',
                  meta: const ['Play White or Black', 'No internet needed'],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OfflineGameScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: palette.paper,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.verified_user_outlined,
                            color: palette.navy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Online games stay inside a private room. Moves are validated by the server before they land on the board.',
                            style: textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.accent,
    required this.actionLabel,
    required this.meta,
    required this.onTap,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final Color accent;
  final String actionLabel;
  final List<String> meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<KnightLinkPalette>()!;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: textTheme.labelLarge?.copyWith(color: accent),
                      ),
                      const SizedBox(height: 4),
                      Text(title, style: textTheme.titleLarge),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(body, style: textTheme.bodyLarge),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: meta
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: palette.paper,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE1D6C8)),
                      ),
                      child: Text(
                        item,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.ink.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onTap, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}
