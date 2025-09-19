class Forum {
  final String title;
  final String url;
  final String category; // ex: jvc, reddit, autre
  final String source;   // le flux RSS qui l’a ajouté

  Forum({
    required this.title,
    required this.url,
    required this.category,
    required this.source,
  });
}
