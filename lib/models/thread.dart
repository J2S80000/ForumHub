// lib/models/thread.dart
class Thread {
  final String title;
  final String link;
  final String author;
  final String description;
  final DateTime pubDate;
  final int responseCount;
  final String guid;

  Thread({
    required this.title,
    required this.link,
    required this.author,
    required this.description,
    required this.pubDate,
    this.responseCount = 0,
    this.guid = '',
  });

  // Getter pour vérifier si le topic est récent (moins de 24h)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(pubDate);
    return difference.inHours < 24;
  }

  // Getter pour vérifier si le topic est populaire (plus de 50 réponses)
  bool get isPopular {
    return responseCount > 50;
  }

  // Getter pour vérifier si le topic est très populaire (plus de 500 réponses)
  bool get isVeryPopular {
    return responseCount > 500;
  }

  // Getter pour le temps relatif (il y a X heures/jours)
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(pubDate);

    if (difference.inMinutes < 60) {
      return "il y a ${difference.inMinutes}min";
    } else if (difference.inHours < 24) {
      return "il y a ${difference.inHours}h";
    } else if (difference.inDays < 7) {
      return "il y a ${difference.inDays}j";
    } else {
      return "${pubDate.day}/${pubDate.month}/${pubDate.year}";
    }
  }

  @override
  String toString() {
    return 'Thread(title: $title, author: $author, responses: $responseCount)';
  }
}