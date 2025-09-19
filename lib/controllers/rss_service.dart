import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/thread.dart';
import '../models/forum.dart';

class RssService {

  Future<List<Thread>> fetchThreads(String url) async {
    url = _sanitizeUrl(url);

    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'Mozilla/5.0 (compatible; RssReader/1.0)'},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load RSS feed: ${response.statusCode}");
    }

    // Vérifie que c’est bien du XML
    if (!response.body.trim().startsWith('<')) {
      throw Exception("Le contenu n’est pas un flux RSS valide");
    }

    return _parseRssFeed(response.body);
  }

  Future<List<Forum>> fetchForumsFromRss(String rssUrl) async {
    rssUrl = _sanitizeUrl(rssUrl);

    final response = await http.get(
      Uri.parse(rssUrl),
      headers: {'User-Agent': 'Mozilla/5.0 (compatible; RssReader/1.0)'},
    );

    if (response.statusCode != 200) {
      throw Exception("Impossible de charger le flux RSS: ${response.statusCode}");
    }

    if (!response.body.trim().startsWith('<rss')) {
      throw Exception("L’URL fournie ne renvoie pas un flux RSS");
    }

    final document = XmlDocument.parse(response.body);
    final items = document.findAllElements('item');
    final category = _detectCategory(rssUrl);

    return items.map((item) {
      final title = item.findElements('title').isNotEmpty
          ? item.findElements('title').first.text
          : "Sans titre";
      final link = item.findElements('link').isNotEmpty
          ? item.findElements('link').first.text
          : "";

      return Forum(
        title: title,
        url: link,
        category: category,
        source: rssUrl,
      );
    }).toList();
  }

  String _sanitizeUrl(String url) {
    url = url.trim().replaceAll(RegExp(r'\s+'), '');
    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      url = "https://$url";
    }
    return url;
  }

  String _detectCategory(String url) {
    if (url.contains("jeuxvideo.com")) return "JVC";
    if (url.contains("reddit.com")) return "Reddit";
    return "Autres";
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

      final responseCount = _extractResponseCount(title);
      final cleanTitle = _cleanTitle(title);
      final author = _extractAuthor(description);
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
    } catch (_) {
      return '';
    }
  }

  int _extractResponseCount(String title) {
    final regex = RegExp(r'\((\d+) réponses?\)');
    final match = regex.firstMatch(title);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  String _cleanTitle(String title) {
    String cleaned = title;
    cleaned = cleaned.replaceFirst(RegExp(r'^[🔴🟥🟩🟢⚪⚫🔵🟦🟪🟨🟫◾◽▪▫⬛⬜🟧🟨]+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'\s*\(\d+ réponses?\)$'), '');
    return _decodeHtmlEntities(cleaned).trim();
  }

  String _extractAuthor(String description) {
    final regex = RegExp(r'Auteur du topic:\s*(.+?)(?:\s*$|$)');
    final match = regex.firstMatch(description);
    return match != null ? match.group(1)!.trim() : "Inconnu";
  }

  DateTime _parseDate(String dateString) {
    if (dateString.isEmpty) return DateTime.now();
    try {
      if (dateString.contains('à')) return _parseFrenchDate(dateString);
      return DateTime.tryParse(dateString) ?? DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  DateTime _parseFrenchDate(String frenchDate) {
    final monthNames = {
      'janvier': 1, 'février': 2, 'mars': 3, 'avril': 4,
      'mai': 5, 'juin': 6, 'juillet': 7, 'août': 8,
      'septembre': 9, 'octobre': 10, 'novembre': 11, 'décembre': 12
    };
    final regex = RegExp(r'(\d{1,2})\s+(\w+)\s+(\d{4})\s+à\s+(\d{1,2}):(\d{2}):(\d{2})');
    final match = regex.firstMatch(frenchDate);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = monthNames[match.group(2)!.toLowerCase()] ?? 1;
      final year = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final second = int.parse(match.group(6)!);
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
