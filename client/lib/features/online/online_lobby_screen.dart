import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/app_theme.dart';
import 'online_game_screen.dart';
import 'online_service.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final OnlineService service = OnlineService();
  final TextEditingController serverController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController roomController = TextEditingController();

  bool busy = false;
  bool showServerSettings = false;
  String? infoMessage;

  @override
  void initState() {
    super.initState();
    nameController.text =
        'Player ${const Uuid().v4().substring(0, 4).toUpperCase()}';
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final serverUrl = await service.loadServerUrl();
    if (!mounted) {
      return;
    }
    setState(() {
      serverController.text = serverUrl;
    });
  }

  @override
  void dispose() {
    serverController.dispose();
    nameController.dispose();
    roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<KnightLinkPalette>()!;
    final textTheme = Theme.of(context).textTheme;
    final infoIsError =
        (infoMessage ?? '').toLowerCase().contains('failed') ||
        (infoMessage ?? '').toLowerCase().contains('unable') ||
        (infoMessage ?? '').toLowerCase().contains('please');

    return Scaffold(
      appBar: AppBar(title: const Text('Play with a friend')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/branding/knightlink_icon.png',
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Private room chess',
                                  style: textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Use a name, make a room, share the code, and start playing.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: palette.ink.withValues(alpha: 0.74),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: palette.paper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2D8CC)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cloud_done_rounded,
                              size: 18,
                              color: palette.sage,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'The app already points to your hosted server by default.',
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your name', style: textTheme.titleLarge),
                      const SizedBox(height: 10),
                      TextField(
                        controller: nameController,
                        maxLength: 24,
                        decoration: const InputDecoration(
                          counterText: '',
                          hintText: 'Enter your name',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create a room', style: textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'You will get White and a room code to share.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.ink.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: busy ? null : _createRoom,
                        icon: const Icon(Icons.add_box_outlined),
                        label: Text(busy ? 'Working...' : 'Create room'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Join a room', style: textTheme.titleLarge),
                      const SizedBox(height: 10),
                      TextField(
                        controller: roomController,
                        maxLength: 12,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          counterText: '',
                          hintText: 'Room code',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: busy ? null : _joinRoom,
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Join room'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: busy
                    ? null
                    : () {
                        setState(() {
                          showServerSettings = !showServerSettings;
                        });
                      },
                icon: Icon(
                  showServerSettings
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.tune_rounded,
                ),
                label: Text(
                  showServerSettings
                      ? 'Hide server settings'
                      : 'Server settings',
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: showServerSettings
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Advanced server settings',
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Only change this if you moved the backend.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: palette.ink.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: serverController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Server URL',
                            hintText: OnlineService.hostedServerUrl,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: busy ? null : _checkServer,
                          icon: const Icon(Icons.cloud_sync_outlined),
                          label: const Text('Check server'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (infoMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: infoIsError
                        ? palette.terracotta.withValues(alpha: 0.12)
                        : palette.sage.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: infoIsError
                          ? palette.terracotta.withValues(alpha: 0.34)
                          : palette.sage.withValues(alpha: 0.34),
                    ),
                  ),
                  child: Text(infoMessage!, style: textTheme.bodyMedium),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkServer() async {
    setState(() {
      busy = true;
      infoMessage = null;
    });

    try {
      await service.checkServer(serverController.text);
      if (!mounted) {
        return;
      }
      setState(() {
        infoMessage = 'Server is reachable and ready for games.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        infoMessage = 'Server check failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> _createRoom() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        infoMessage = 'Please enter your name first.';
      });
      return;
    }

    setState(() {
      busy = true;
      infoMessage = null;
    });

    try {
      final session = await service.createRoom(
        baseUrl: serverController.text,
        displayName: name,
      );
      await service.saveServerUrl(serverController.text);
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OnlineGameScreen(session: session, service: service),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        infoMessage = 'Unable to create room: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> _joinRoom() async {
    final name = nameController.text.trim();
    final code = roomController.text.trim().toUpperCase();
    if (name.isEmpty || code.isEmpty) {
      setState(() {
        infoMessage = 'Enter your name and the room code.';
      });
      return;
    }

    setState(() {
      busy = true;
      infoMessage = null;
    });

    try {
      final session = await service.joinRoom(
        baseUrl: serverController.text,
        roomCode: code,
        displayName: name,
      );
      await service.saveServerUrl(serverController.text);
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OnlineGameScreen(session: session, service: service),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        infoMessage = 'Unable to join room: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }
}
