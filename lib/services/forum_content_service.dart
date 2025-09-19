// lib/services/forum_content_service.dart
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../models/forum_post.dart';

class ForumContentService {
  static const String _baseUrl = 'https://www.jeuxvideo.com';
  
  Future<List<ForumPost>> fetchThreadContent(String threadUrl) async {
    try {
      final response = await http.get(
        Uri.parse(threadUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load thread content: ${response.statusCode}');
      }

      return _parseThreadContent(response.body, threadUrl);
    } catch (e) {
      throw Exception('Error fetching thread content: $e');
    }
  }

  List<ForumPost> _parseThreadContent(String htmlContent, String threadUrl) {
    final document = html_parser.parse(htmlContent);
    final posts = <ForumPost>[];

    // Sélecteurs pour les posts du forum JVC
    final postElements = document.querySelectorAll('.bloc-message-forum');
    
    for (int i = 0; i < postElements.length; i++) {
      final postElement = postElements[i];
      final post = _parsePost(postElement, i + 1);
      if (post != null) {
        posts.add(post);
      }
    }

    // Fallback si la structure a changé
    if (posts.isEmpty) {
      final alternativeElements = document.querySelectorAll('.message, .post, [class*="message"]');
      for (int i = 0; i < alternativeElements.length; i++) {
        final post = _parsePost(alternativeElements[i], i + 1);
        if (post != null) {
          posts.add(post);
        }
      }
    }

    return posts;
  }

  ForumPost? _parsePost(Element postElement, int postNumber) {
    try {
      // Extraction de l'auteur
      final authorElement = postElement.querySelector('.bloc-pseudo-msg') ??
                           postElement.querySelector('.pseudo') ??
                           postElement.querySelector('[class*="pseudo"]');
      final author = authorElement?.text.trim() ?? 'Anonyme';

      // Extraction du contenu
      final contentElement = postElement.querySelector('.txt-msg') ??
                            postElement.querySelector('.message-content') ??
                            postElement.querySelector('.contenu-msg');
      
      if (contentElement == null) return null;

      final content = _extractAndCleanContent(contentElement);
      if (content.isEmpty) return null;

      // Extraction de la date
      final dateElement = postElement.querySelector('.bloc-date-msg') ??
                         postElement.querySelector('.date') ??
                         postElement.querySelector('[class*="date"]');
      final dateText = dateElement?.text.trim() ?? '';
      final postDate = _parsePostDate(dateText);

      // Extraction du niveau/rang de l'utilisateur
      final levelElement = postElement.querySelector('.bloc-niveau') ??
                          postElement.querySelector('.level');
      final userLevel = levelElement?.text.trim() ?? '';

      // Extraction de l'avatar
      final avatarElement = postElement.querySelector('.user-avatar img') ??
                           postElement.querySelector('.avatar img');
      final avatarUrl = avatarElement?.attributes['src'] ?? '';

      // ID du post
      final postId = postElement.attributes['id'] ?? 
                    postElement.attributes['data-id'] ?? 
                    'post_$postNumber';

      return ForumPost(
        id: postId,
        author: author,
        content: content,
        postDate: postDate,
        postNumber: postNumber,
        userLevel: userLevel,
        avatarUrl: avatarUrl.isNotEmpty ? _resolveUrl(avatarUrl) : '',
      );
    } catch (e) {
      print('Error parsing post: $e');
      return null;
    }
  }

  String _extractAndCleanContent(Element contentElement) {
    // Supprime les scripts et styles
    contentElement.querySelectorAll('script, style').forEach((el) => el.remove());
    
    // Remplace les BR par des sauts de ligne
    contentElement.querySelectorAll('br').forEach((br) {
      br.replaceWith(Text('\n'));
    });

    // Gère les citations
    final quotes = contentElement.querySelectorAll('.citation, blockquote, .quote');
    for (final quote in quotes) {
      final quoteText = quote.text.trim();
      if (quoteText.isNotEmpty) {
        quote.replaceWith(Text('\n> $quoteText\n'));
      }
    }

    // Gère les liens
    final links = contentElement.querySelectorAll('a');
    for (final link in links) {
      final href = link.attributes['href'] ?? '';
      final linkText = link.text.trim();
      if (href.isNotEmpty && linkText.isNotEmpty) {
        link.replaceWith(Text('$linkText ($href)'));
      }
    }

    // Gère les images
    final images = contentElement.querySelectorAll('img');
    for (final img in images) {
      final src = img.attributes['src'] ?? '';
      final alt = img.attributes['alt'] ?? '';
      if (src.isNotEmpty) {
        img.replaceWith(Text('\n[Image: ${alt.isNotEmpty ? alt : src}]\n'));
      }
    }

    String content = contentElement.text;
    
    // Nettoyage final
    content = content
        .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n') // Multiple sauts de ligne
        .replaceAll(RegExp(r'^\s+|\s+$'), '') // Espaces début/fin
        .replaceAll(RegExp(r' +'), ' '); // Espaces multiples

    return content;
  }

  DateTime _parsePostDate(String dateText) {
    if (dateText.isEmpty) return DateTime.now();

    try {
      // Format JVC typique: "Le 14 septembre 2025 à 13:33:50"
      final regex = RegExp(r'Le (\d{1,2}) (\w+) (\d{4}) à (\d{1,2}):(\d{2}):(\d{2})');
      final match = regex.firstMatch(dateText);

      if (match != null) {
        final monthNames = {
          'janvier': 1, 'février': 2, 'mars': 3, 'avril': 4,
          'mai': 5, 'juin': 6, 'juillet': 7, 'août': 8,
          'septembre': 9, 'octobre': 10, 'novembre': 11, 'décembre': 12
        };

        final day = int.parse(match.group(1)!);
        final monthName = match.group(2)!.toLowerCase();
        final year = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        final second = int.parse(match.group(6)!);

        final month = monthNames[monthName] ?? 1;
        return DateTime(year, month, day, hour, minute, second);
      }

      // Fallback pour d'autres formats
      return DateTime.tryParse(dateText) ?? DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    if (url.startsWith('//')) return 'https:$url';
    if (url.startsWith('/')) return '$_baseUrl$url';
    return url;
  }
}