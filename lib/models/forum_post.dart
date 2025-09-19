// lib/models/forum_post.dart
class ForumPost {
  final String id;
  final String author;
  final String content;
  final DateTime postDate;
  final int postNumber;
  final String userLevel;
  final String avatarUrl;

  ForumPost({
    required this.id,
    required this.author,
    required this.content,
    required this.postDate,
    required this.postNumber,
    this.userLevel = '',
    this.avatarUrl = '',
  });

  // Getter pour vérifier si c'est l'auteur du topic (premier post)
  bool get isOriginalPoster => postNumber == 1;

  // Getter pour le temps relatif
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(postDate);

    if (difference.inMinutes < 60) {
      return "il y a ${difference.inMinutes}min";
    } else if (difference.inHours < 24) {
      return "il y a ${difference.inHours}h";
    } else if (difference.inDays < 7) {
      return "il y a ${difference.inDays}j";
    } else {
      return "${postDate.day}/${postDate.month}/${postDate.year}";
    }
  }

  // Getter pour la date formatée
  String get formattedDate {
    return "${postDate.day.toString().padLeft(2, '0')}/"
           "${postDate.month.toString().padLeft(2, '0')}/"
           "${postDate.year} "
           "${postDate.hour.toString().padLeft(2, '0')}:"
           "${postDate.minute.toString().padLeft(2, '0')}";
  }

  // Vérifie si le contenu contient une citation
  bool get hasQuote => content.contains('>');

  // Extrait les citations du contenu
  List<String> get quotes {
    final lines = content.split('\n');
    return lines.where((line) => line.trim().startsWith('>')).toList();
  }

  // Contenu sans les citations pour l'affichage
  String get contentWithoutQuotes {
    final lines = content.split('\n');
    return lines.where((line) => !line.trim().startsWith('>')).join('\n').trim();
  }

  @override
  String toString() {
    return 'ForumPost(#$postNumber by $author: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }
}