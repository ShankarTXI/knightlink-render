import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'models.dart';

class OnlineService {
  static const _serverUrlKey = 'server_url';
  static const hostedServerUrl = 'https://knightlink-server.onrender.com';
  static const defaultServerUrl = String.fromEnvironment(
    'KNIGHTLINK_SERVER_URL',
    defaultValue: hostedServerUrl,
  );

  Future<String> loadServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey) ?? defaultServerUrl;
  }

  Future<void> saveServerUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, normalizeBaseUrl(baseUrl));
  }

  String normalizeBaseUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) {
      return defaultServerUrl;
    }
    value = value.replaceFirst(
      RegExp(r'^(?:https?://)+', caseSensitive: false),
      '',
    );
    final scheme = _looksLocalAddress(value) ? 'http' : 'https';
    value = '$scheme://$value';
    return value.replaceFirst(RegExp(r'/$'), '');
  }

  Future<void> checkServer(String baseUrl) async {
    final response = await http.get(
      Uri.parse('${normalizeBaseUrl(baseUrl)}/health'),
    );
    if (response.statusCode != 200) {
      throw Exception('Server responded with ${response.statusCode}.');
    }
  }

  Future<OnlineSession> createRoom({
    required String baseUrl,
    required String displayName,
  }) async {
    final normalized = normalizeBaseUrl(baseUrl);
    final response = await http.post(
      Uri.parse('$normalized/rooms/create'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'displayName': displayName}),
    );

    if (response.statusCode != 200) {
      throw Exception(_readError(response.body));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return OnlineSession(
      baseUrl: normalized,
      roomCode: json['roomCode'] as String,
      playerId: json['playerId'] as String,
      playerToken: json['playerToken'] as String,
      playerName: json['playerName'] as String,
      color: json['color'] as String,
    );
  }

  Future<OnlineSession> joinRoom({
    required String baseUrl,
    required String roomCode,
    required String displayName,
  }) async {
    final normalized = normalizeBaseUrl(baseUrl);
    final response = await http.post(
      Uri.parse('$normalized/rooms/join'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'roomCode': roomCode.trim().toUpperCase(),
        'displayName': displayName,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_readError(response.body));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return OnlineSession(
      baseUrl: normalized,
      roomCode: json['roomCode'] as String,
      playerId: json['playerId'] as String,
      playerToken: json['playerToken'] as String,
      playerName: json['playerName'] as String,
      color: json['color'] as String,
    );
  }

  io.Socket connect(
    OnlineSession session, {
    required ValueChanged<RoomSnapshot> onState,
    required ValueChanged<String> onError,
    VoidCallback? onConnected,
    VoidCallback? onDisconnected,
  }) {
    final socket = io.io(
      session.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setReconnectionAttempts(8)
          .setReconnectionDelay(1200)
          .setAckTimeout(5000)
          .setAuth({
            'roomCode': session.roomCode,
            'playerToken': session.playerToken,
          })
          .build(),
    );

    socket.onConnect((_) => onConnected?.call());
    socket.onDisconnect((_) => onDisconnected?.call());
    socket.on(
      'room:state',
      (data) => onState(
        RoomSnapshot.fromJson(Map<String, dynamic>.from(data as Map)),
      ),
    );
    socket.on(
      'server:error',
      (data) => onError((data is Map ? data['message'] : data).toString()),
    );
    socket.connect();
    return socket;
  }

  Future<void> sendMove(
    io.Socket socket, {
    required String from,
    required String to,
    String? promotion,
  }) async {
    final payload = <String, dynamic>{'from': from, 'to': to};
    if (promotion != null) {
      payload['promotion'] = promotion;
    }
    await _emitWithOptionalAck(
      socket,
      event: 'move:make',
      payload: payload,
      fallbackError: 'Move could not be delivered.',
    );
  }

  Future<void> sendChat(io.Socket socket, String message) async {
    await _emitWithOptionalAck(
      socket,
      event: 'chat:send',
      payload: <String, dynamic>{'message': message},
      fallbackError: 'Message could not be delivered.',
    );
  }

  void disconnect(io.Socket? socket) {
    socket?.disconnect();
    socket?.dispose();
  }

  bool _looksLocalAddress(String value) {
    final normalized = value.toLowerCase();
    return RegExp(
      r'^(localhost|10\.|127\.|192\.168\.|172\.(1[6-9]|2\d|3[0-1])\.)',
    ).hasMatch(normalized);
  }

  Future<void> _emitWithOptionalAck(
    io.Socket socket, {
    required String event,
    required Map<String, dynamic> payload,
    required String fallbackError,
  }) async {
    try {
      final response = await socket
          .timeout(5000)
          .emitWithAckAsync(event, payload);
      final parsed = _parseAckPayload(response);
      if (parsed == null) {
        return;
      }
      if (parsed['ok'] != true) {
        throw Exception(parsed['message'] as String? ?? fallbackError);
      }
    } catch (error) {
      if (_canFallbackWithoutAck(error)) {
        socket.emit(event, payload);
        return;
      }
      rethrow;
    }
  }

  Map<String, dynamic>? _parseAckPayload(dynamic response) {
    return switch (response) {
      Map<String, dynamic> value => value,
      Map value => Map<String, dynamic>.from(value),
      List value when value.isNotEmpty && value.first is Map =>
        Map<String, dynamic>.from(value.first as Map),
      _ => null,
    };
  }

  bool _canFallbackWithoutAck(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('timed out') || text.contains('timeout');
  }

  String _readError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['message'] as String? ?? 'Request failed.';
    } catch (_) {
      return 'Request failed.';
    }
  }
}
