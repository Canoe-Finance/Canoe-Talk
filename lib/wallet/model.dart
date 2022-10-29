import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class Activity {
  final DateTime createdAt;
  final String title;
  final String content;

  Activity({
    required this.createdAt,
    required this.title,
    required this.content,
  });

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityToJson(this);
}
