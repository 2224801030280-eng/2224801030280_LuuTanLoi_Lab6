class SongModel {
  final String id;
  String title;
  String artist;
  String thumbnail;
  String url;
  List<String> likedByUsers; // Danh sách username đã thích bài hát này

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnail,
    required this.url,
    List<String>? likedByUsers,
  }) : likedByUsers = likedByUsers ?? [];

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'artist': artist,
    'thumbnail': thumbnail,
    'url': url,
    'likedByUsers': likedByUsers,
  };

  factory SongModel.fromMap(Map<dynamic, dynamic> map) => SongModel(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    artist: map['artist'] ?? '',
    thumbnail: map['thumbnail'] ?? '',
    url: map['url'] ?? '',
    likedByUsers: List<String>.from(map['likedByUsers'] ?? []),
  );
}
