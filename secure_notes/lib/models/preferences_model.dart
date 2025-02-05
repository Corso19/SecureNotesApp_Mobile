import 'package:flutter/material.dart';

class PreferencesModel {
  final int id;
  final String userId;
  final String themeMode;
  final int fontSize;
  final bool notificationsEnabled;
  final int syncInterval;
  final DateTime createdAt;
  final DateTime updatedAt;

  PreferencesModel({
    required this.id,
    required this.userId,
    this.themeMode = 'system',
    this.fontSize = 16,
    this.notificationsEnabled = true,
    this.syncInterval = 5,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PreferencesModel.fromMap(Map<String, dynamic> map) {
    return PreferencesModel(
      id: map['id'],
      userId: map['user_id'],
      themeMode: map['theme_mode'] ?? 'system',
      fontSize: map['font_size'] ?? 16,
      notificationsEnabled: map['notifications_enabled'] == 1,
      syncInterval: map['sync_interval'] ?? 5,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'theme_mode': themeMode,
      'font_size': fontSize,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'sync_interval': syncInterval,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}