import 'package:equatable/equatable.dart';
import 'user.dart';
import 'project.dart';

/// Модель сообщения в чате
class Message extends Equatable {
  final String id;
  final String chatId;
  final User sender;
  final String content;
  final MessageType type;
  final Project? sharedProject; // Если это сообщение с проектом
  final String? projectId; // ID поста или проекта
  final List<String> attachments; // URLs изображений/файлов
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const Message({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.content,
    this.type = MessageType.text,
    this.sharedProject,
    this.projectId,
    this.attachments = const [],
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  @override
  List<Object?> get props => [
        id,
        chatId,
        sender,
        content,
        type,
        sharedProject,
        projectId,
        attachments,
        isRead,
        createdAt,
        readAt,
      ];

  Message copyWith({
    String? id,
    String? chatId,
    User? sender,
    String? content,
    MessageType? type,
    Project? sharedProject,
    String? projectId,
    List<String>? attachments,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      type: type ?? this.type,
      sharedProject: sharedProject ?? this.sharedProject,
      projectId: projectId ?? this.projectId,
      attachments: attachments ?? this.attachments,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'sender': sender.toJson(),
      'content': content,
      'type': type.value,
      'sharedProject': sharedProject?.toJson(),
      'attachments': attachments,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      sender: User.fromJson(json['sender']),
      content: json['content'] ?? '',
      type: MessageType.fromValue(json['type'] ?? 'text'),
      sharedProject: json['sharedProject'] != null
          ? Project.fromJson(json['sharedProject'])
          : null,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : const [],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }
}

/// Тип сообщения
enum MessageType {
  text('text'),
  image('image'),
  file('file'),
  project('project'),
  post('post'),
  system('system');

  final String value;
  const MessageType(this.value);

  static MessageType fromValue(String value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Модель чата (диалога)
class Chat extends Equatable {
  final String id;
  final User currentUser; // Другой участник чата
  final Message? lastMessage;
  final int unreadCount;
  final bool isOnline;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final String participantIds; // JSON/string список ID участников
  final bool isGroup;
  final String? title;

  const Chat({
    required this.id,
    required this.currentUser,
    this.lastMessage,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastMessageAt,
    required this.createdAt,
    this.participantIds = '',
    this.isGroup = false,
    this.title,
  });

  @override
  List<Object?> get props => [
        id,
        currentUser,
        lastMessage,
        unreadCount,
        isOnline,
        lastMessageAt,
        createdAt,
        participantIds,
        isGroup,
        title,
      ];

  Chat copyWith({
    String? id,
    User? currentUser,
    Message? lastMessage,
    int? unreadCount,
    bool? isOnline,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    String? participantIds,
    bool? isGroup,
    String? title,
  }) {
    return Chat(
      id: id ?? this.id,
      currentUser: currentUser ?? this.currentUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      participantIds: participantIds ?? this.participantIds,
      isGroup: isGroup ?? this.isGroup,
      title: title ?? this.title,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currentUser': currentUser.toJson(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'isOnline': isOnline,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'participantIds': participantIds,
      'isGroup': isGroup,
      'title': title,
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] ?? '',
      currentUser: User.fromJson(json['currentUser']),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      participantIds: json['participantIds'] ?? '',
      isGroup: json['isGroup'] ?? false,
      title: json['title'],
    );
  }

  String get displayTitle =>
      isGroup ? (title ?? 'Командный чат') : currentUser.name;

  int get participantsCount {
    if (participantIds.isEmpty) return isGroup ? 0 : 2;
    try {
      final cleaned = participantIds
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '');
      return cleaned.split(',').where((e) => e.trim().isNotEmpty).length;
    } catch (_) {
      return isGroup ? 0 : 2;
    }
  }

  /// Текст последнего сообщения для превью
  String get lastMessagePreview {
    if (lastMessage == null) {
      return 'Нет сообщений';
    }

    switch (lastMessage!.type) {
      case MessageType.text:
        return lastMessage!.content;
      case MessageType.image:
        return '📷 Изображение';
      case MessageType.file:
        return '📎 Файл';
      case MessageType.project:
        return '📁 ${lastMessage!.sharedProject?.title ?? "Проект"}';
      case MessageType.post:
        return '📝 Пост';
      case MessageType.system:
        return lastMessage!.content;
    }
  }

  /// Время последнего сообщения
  String get lastMessageTime {
    if (lastMessageAt == null) {
      return '';
    }

    final now = DateTime.now();
    final diff = now.difference(lastMessageAt!);

    if (diff.inMinutes < 1) {
      return 'Только что';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} мин';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} ч';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} дн';
    } else {
      return '${lastMessageAt!.day}.${lastMessageAt!.month}.${lastMessageAt!.year.toString().substring(2)}';
    }
  }
}
