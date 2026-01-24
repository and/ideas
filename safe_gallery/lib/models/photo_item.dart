class PhotoItem {
  final String id;
  final String path;
  final String? thumbnailPath;
  final DateTime addedAt;
  final int order;

  PhotoItem({
    required this.id,
    required this.path,
    this.thumbnailPath,
    required this.addedAt,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'thumbnailPath': thumbnailPath,
      'addedAt': addedAt.toIso8601String(),
      'order': order,
    };
  }

  factory PhotoItem.fromMap(Map<String, dynamic> map) {
    return PhotoItem(
      id: map['id'] as String,
      path: map['path'] as String,
      thumbnailPath: map['thumbnailPath'] as String?,
      addedAt: DateTime.parse(map['addedAt'] as String),
      order: map['order'] as int,
    );
  }

  PhotoItem copyWith({
    String? id,
    String? path,
    String? thumbnailPath,
    DateTime? addedAt,
    int? order,
  }) {
    return PhotoItem(
      id: id ?? this.id,
      path: path ?? this.path,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      addedAt: addedAt ?? this.addedAt,
      order: order ?? this.order,
    );
  }
}
