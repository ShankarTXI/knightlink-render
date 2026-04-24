class OnlineSession {
  const OnlineSession({
    required this.baseUrl,
    required this.roomCode,
    required this.playerId,
    required this.playerToken,
    required this.playerName,
    required this.color,
  });

  final String baseUrl;
  final String roomCode;
  final String playerId;
  final String playerToken;
  final String playerName;
  final String color;

  String get turnKey => color == 'white' ? 'w' : 'b';
}

class RoomPlayer {
  const RoomPlayer({
    required this.id,
    required this.name,
    required this.color,
    required this.connected,
  });

  final String id;
  final String name;
  final String color;
  final bool connected;

  factory RoomPlayer.fromJson(Map<String, dynamic> json) {
    return RoomPlayer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Player',
      color: json['color'] as String? ?? 'white',
      connected: json['connected'] as bool? ?? false,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
    required this.system,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;
  final bool system;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'System',
      message: json['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      system: json['system'] as bool? ?? false,
    );
  }
}

class RoomSnapshot {
  const RoomSnapshot({
    required this.roomCode,
    required this.status,
    required this.fen,
    required this.turn,
    required this.moveHistory,
    required this.chat,
    required this.result,
    required this.whitePlayer,
    required this.blackPlayer,
    required this.lastMoveFrom,
    required this.lastMoveTo,
  });

  final String roomCode;
  final String status;
  final String fen;
  final String turn;
  final List<String> moveHistory;
  final List<ChatMessage> chat;
  final String? result;
  final RoomPlayer? whitePlayer;
  final RoomPlayer? blackPlayer;
  final String? lastMoveFrom;
  final String? lastMoveTo;

  factory RoomSnapshot.fromJson(Map<String, dynamic> json) {
    final players = (json['players'] as Map<String, dynamic>? ?? const {});
    final lastMove = json['lastMove'] as Map<String, dynamic>? ?? const {};

    return RoomSnapshot(
      roomCode: json['roomCode'] as String? ?? '',
      status: json['status'] as String? ?? 'waiting',
      fen:
          json['fen'] as String? ??
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      turn: json['turn'] as String? ?? 'w',
      moveHistory: (json['moveHistory'] as List<dynamic>? ?? const [])
          .map((move) => move.toString())
          .toList(growable: false),
      chat: (json['chat'] as List<dynamic>? ?? const [])
          .map(
            (message) =>
                ChatMessage.fromJson(Map<String, dynamic>.from(message as Map)),
          )
          .toList(growable: false),
      result: json['result'] as String?,
      whitePlayer: players['white'] == null
          ? null
          : RoomPlayer.fromJson(
              Map<String, dynamic>.from(players['white'] as Map),
            ),
      blackPlayer: players['black'] == null
          ? null
          : RoomPlayer.fromJson(
              Map<String, dynamic>.from(players['black'] as Map),
            ),
      lastMoveFrom: lastMove['from'] as String?,
      lastMoveTo: lastMove['to'] as String?,
    );
  }
}
