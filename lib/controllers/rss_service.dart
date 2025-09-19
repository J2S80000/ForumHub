// lib/controllers/rss_service.dart
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/thread.dart';

class RssService {
  Future<List<Thread>> fetchThreads(String url) async {
    // Si l'URL n'a pas de protocole, on ajoute https://
    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      url = "https://$url";
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception("Failed to load RSS feed");
    }

    return _parseRssFeed(response.body);
  }

  List<Thread> _parseRssFeed(String xmlContent) {
    final document = XmlDocument.parse(xmlContent);
    final items = document.findAllElements('item');

    return items.map((item) {
      final title = _getElementText(item, 'title');
      final link = _getElementText(item, 'link');
      final description = _getElementText(item, 'description');
      final pubDate = _getElementText(item, 'pubDate');
      final guid = _getElementText(item, 'guid');

      // Parse le titre pour extraire le nombre de réponses
      final responseCount = _extractResponseCount(title);
      final cleanTitle = _cleanTitle(title);

      // Parse la description pour extraire l'auteur
      final author = _extractAuthor(description);

      // Parse la date
      final parsedDate = _parseDate(pubDate);

      return Thread(
        title: cleanTitle,
        link: link,
        author: author,
        description: description,
        pubDate: parsedDate,
        responseCount: responseCount,
        guid: guid,
      );
    }).toList();
  }

  String _getElementText(XmlElement parent, String tagName) {
    try {
      return parent.findElements(tagName).first.text.trim();
    } catch (e) {
      return '';
    }
  }

  int _extractResponseCount(String title) {
    // Cherche les patterns comme "(126 réponses)" ou "(0 réponses)"
    final regex = RegExp(r'\((\d+) réponses?\)');
    final match = regex.firstMatch(title);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  String _cleanTitle(String title) {
    // Supprime les emojis en début et les infos de réponses
    String cleaned = title;
    
    // Supprime les patterns d'emojis répétitifs en début
    cleaned = cleaned.replaceFirst(RegExp(r'^[🔴🟥🟩🟢⚪⚫🔵🟦🟪🟨🟫◾◽▪▫⬛⬜🟧🟨]+'), '');
    
    // Supprime les infos de réponses à la fin
    cleaned = cleaned.replaceFirst(RegExp(r'\s*\(\d+ réponses?\)$'), '');
    
    // Decode HTML entities
    cleaned = _decodeHtmlEntities(cleaned);
    
    return cleaned.trim();
  }

  String _extractAuthor(String description) {
    // Pattern pour "Auteur du topic: NomAuteur"
    final regex = RegExp(r'Auteur du topic:\s*(.+?)(?:\s*$|$)');
    final match = regex.firstMatch(description);
    return match != null ? match.group(1)!.trim() : "Inconnu";
  }

  DateTime _parseDate(String dateString) {
    if (dateString.isEmpty) return DateTime.now();

    try {
      // Format français: "14 septembre 2025 à 13:33:50"
      if (dateString.contains('à')) {
        return _parseFrenchDate(dateString);
      }
      
      // Fallback pour les formats standards
      return DateTime.tryParse(dateString) ?? DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime _parseFrenchDate(String frenchDate) {
    final monthNames = {
      'janvier': 1, 'février': 2, 'mars': 3, 'avril': 4,
      'mai': 5, 'juin': 6, 'juillet': 7, 'août': 8,
      'septembre': 9, 'octobre': 10, 'novembre': 11, 'décembre': 12
    };

    // Pattern: "14 septembre 2025 à 13:33:50"
    final regex = RegExp(r'(\d{1,2})\s+(\w+)\s+(\d{4})\s+à\s+(\d{1,2}):(\d{2}):(\d{2})');
    final match = regex.firstMatch(frenchDate);

    if (match != null) {
      final day = int.parse(match.group(1)!);
      final monthName = match.group(2)!.toLowerCase();
      final year = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final second = int.parse(match.group(6)!);

      final month = monthNames[monthName] ?? 1;

      return DateTime(year, month, day, hour, minute, second);
    }

    return DateTime.now();
  }

  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#039;', "'");
  }
}