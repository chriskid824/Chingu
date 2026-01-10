class StickerPackModel {
  final String id;
  final String name;
  final String author;
  final String description;
  final String thumbnailUrl;
  final List<String> stickerUrls;
  final double? price;
  final bool isDownloaded;

  const StickerPackModel({
    required this.id,
    required this.name,
    required this.author,
    required this.description,
    required this.thumbnailUrl,
    required this.stickerUrls,
    this.price,
    this.isDownloaded = false,
  });

  factory StickerPackModel.fromJson(Map<String, dynamic> json) {
    return StickerPackModel(
      id: json['id'] as String,
      name: json['name'] as String,
      author: json['author'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      stickerUrls: List<String>.from(json['stickerUrls'] as List),
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'author': author,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'stickerUrls': stickerUrls,
      'price': price,
      'isDownloaded': isDownloaded,
    };
  }

  StickerPackModel copyWith({
    String? id,
    String? name,
    String? author,
    String? description,
    String? thumbnailUrl,
    List<String>? stickerUrls,
    double? price,
    bool? isDownloaded,
  }) {
    return StickerPackModel(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      stickerUrls: stickerUrls ?? this.stickerUrls,
      price: price ?? this.price,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
