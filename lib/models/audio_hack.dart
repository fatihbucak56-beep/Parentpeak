class AudioHack {
  const AudioHack({
    required this.id,
    required this.recipeId,
    required this.userId,
    required this.audioUrl,
    required this.durationSeconds,
    required this.upvotes,
    this.transcript,
  });

  final String id;
  final String recipeId;
  final String userId;
  final String audioUrl;
  final int durationSeconds;
  final int upvotes;
  final String? transcript;

  AudioHack copyWith({
    String? id,
    String? recipeId,
    String? userId,
    String? audioUrl,
    int? durationSeconds,
    int? upvotes,
    String? transcript,
  }) {
    return AudioHack(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      userId: userId ?? this.userId,
      audioUrl: audioUrl ?? this.audioUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      upvotes: upvotes ?? this.upvotes,
      transcript: transcript ?? this.transcript,
    );
  }

  factory AudioHack.fromMap(Map<String, dynamic> map) {
    return AudioHack(
      id: map['id']?.toString() ?? '',
      recipeId: map['recipeId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      audioUrl: map['audioUrl']?.toString() ?? '',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      upvotes: (map['upvotes'] as num?)?.toInt() ?? 0,
      transcript: map['transcript']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'userId': userId,
      'audioUrl': audioUrl,
      'durationSeconds': durationSeconds,
      'upvotes': upvotes,
      'transcript': transcript,
    };
  }
}
