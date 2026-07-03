class Course {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String instructorId;
  final String category;
  final String contentUrl;
  final int durationMinutes;

  Course({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl = 'https://via.placeholder.com/150',
    required this.instructorId,
    required this.category,
    required this.contentUrl,
    required this.durationMinutes,
  });

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? instructorId,
    String? category,
    String? contentUrl,
    int? durationMinutes,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      instructorId: instructorId ?? this.instructorId,
      category: category ?? this.category,
      contentUrl: contentUrl ?? this.contentUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'instructorId': instructorId,
      'category': category,
      'contentUrl': contentUrl,
      'durationMinutes': durationMinutes,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map, String docId) {
    return Course(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? 'https://via.placeholder.com/150',
      instructorId: map['instructor'] ?? '',
      category: map['category'] ?? '',
      contentUrl: map['contentUrl'] ?? '',
      durationMinutes: map['durationMinutes']?.toInt() ?? 0,
    );
  }
}
