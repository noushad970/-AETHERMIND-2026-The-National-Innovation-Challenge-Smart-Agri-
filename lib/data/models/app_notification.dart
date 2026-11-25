import 'dart:convert';

enum NotificationType {
  cropReminder,
  livestockReminder,
  weatherAlert,
  marketUpdate,
  systemAdvisory,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.bodyEn,
    required this.bodyBn,
    required this.type,
    required this.scheduledTime,
    this.isRead = false,
    this.route,
    this.routeArgument,
    this.metadata,
  });

  final String id;
  final String titleEn;
  final String titleBn;
  final String bodyEn;
  final String bodyBn;
  final NotificationType type;
  final DateTime scheduledTime;
  final bool isRead;
  final String? route;
  final String? routeArgument;
  final Map<String, dynamic>? metadata;

  AppNotification copyWith({
    String? id,
    String? titleEn,
    String? titleBn,
    String? bodyEn,
    String? bodyBn,
    NotificationType? type,
    DateTime? scheduledTime,
    bool? isRead,
    String? route,
    String? routeArgument,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      titleEn: titleEn ?? this.titleEn,
      titleBn: titleBn ?? this.titleBn,
      bodyEn: bodyEn ?? this.bodyEn,
      bodyBn: bodyBn ?? this.bodyBn,
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isRead: isRead ?? this.isRead,
      route: route ?? this.route,
      routeArgument: routeArgument ?? this.routeArgument,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titleEn': titleEn,
      'titleBn': titleBn,
      'bodyEn': bodyEn,
      'bodyBn': bodyBn,
      'type': type.name,
      'scheduledTime': scheduledTime.toIso8601String(),
      'isRead': isRead,
      'route': route,
      'routeArgument': routeArgument,
      'metadata': metadata,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      titleEn: map['titleEn'] as String? ?? '',
      titleBn: map['titleBn'] as String? ?? '',
      bodyEn: map['bodyEn'] as String? ?? '',
      bodyBn: map['bodyBn'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.systemAdvisory,
      ),
      scheduledTime: DateTime.tryParse(map['scheduledTime'] as String? ?? '') ??
          DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
      route: map['route'] as String?,
      routeArgument: map['routeArgument'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppNotification.fromJson(String source) =>
      AppNotification.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
