// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Activity _$ActivityFromJson(Map<String, dynamic> json) => Activity(
      createdAt: DateTime.parse(json['createdAt'] as String),
      title: json['title'] as String,
      content: json['content'] as String,
    );

Map<String, dynamic> _$ActivityToJson(Activity instance) => <String, dynamic>{
      'createdAt': instance.createdAt.toIso8601String(),
      'title': instance.title,
      'content': instance.content,
    };
