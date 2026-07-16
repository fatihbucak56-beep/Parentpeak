import 'package:parentpeak/models/kitchen_sos.dart';

class CommunitySnack {
  const CommunitySnack({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.linkedRecipeId,
    required this.authorId,
    required this.viewsCount,
    required this.locationCoordinates,
    this.likesCount = 0,
  });

  final String id;
  final String title;
  final String videoUrl;
  final String linkedRecipeId;
  final String authorId;
  final int viewsCount;
  final GeoCoordinates locationCoordinates;
  final int likesCount;

  CommunitySnack copyWith({
    String? id,
    String? title,
    String? videoUrl,
    String? linkedRecipeId,
    String? authorId,
    int? viewsCount,
    GeoCoordinates? locationCoordinates,
    int? likesCount,
  }) {
    return CommunitySnack(
      id: id ?? this.id,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      linkedRecipeId: linkedRecipeId ?? this.linkedRecipeId,
      authorId: authorId ?? this.authorId,
      viewsCount: viewsCount ?? this.viewsCount,
      locationCoordinates: locationCoordinates ?? this.locationCoordinates,
      likesCount: likesCount ?? this.likesCount,
    );
  }

  factory CommunitySnack.fromMap(Map<String, dynamic> map) {
    return CommunitySnack(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      videoUrl: map['videoUrl']?.toString() ?? '',
      linkedRecipeId: map['linkedRecipeId']?.toString() ?? '',
      authorId: map['authorId']?.toString() ?? '',
      viewsCount: (map['viewsCount'] as num?)?.toInt() ?? 0,
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
      locationCoordinates: GeoCoordinates.fromMap(
        Map<String, dynamic>.from(map['locationCoordinates'] as Map? ?? const {}),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'videoUrl': videoUrl,
      'linkedRecipeId': linkedRecipeId,
      'authorId': authorId,
      'viewsCount': viewsCount,
      'likesCount': likesCount,
      'locationCoordinates': locationCoordinates.toMap(),
    };
  }
}
