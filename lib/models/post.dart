// models/post.dart
class Post {
  final String id;
  final String author;
  final String content;
  final DateTime createdAt;

  Post({required this.id, required this.author, required this.content, required this.createdAt});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      author: json['author'],
      content: json['body'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
