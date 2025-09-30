class Forum {
  final String title;
  final String url;
  final String category; // ex: "JVC", "Reddit", "Autres"
  final bool isFavorite;

  Forum({
    required this.title,
    required this.url,
    this.category = "Autres",
    this.isFavorite = false,
  });

  // Méthode pour créer une copie avec des modifications
  Forum copyWith({
    String? title,
    String? url,
    String? category,
    bool? isFavorite,
  }) {
    return Forum(
      title: title ?? this.title,
      url: url ?? this.url,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'category': category,
      'isFavorite': isFavorite,
    };
  }

  // Création depuis JSON
  factory Forum.fromJson(Map<String, dynamic> json) {
    return Forum(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      category: json['category'] ?? 'Autres',
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}