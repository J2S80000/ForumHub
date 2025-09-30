// lib/views/thread_detail_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../models/forum_post.dart';
import '../controllers/thread_controller.dart';

class ThreadDetailView extends StatefulWidget {
  final Thread thread;

  const ThreadDetailView({super.key, required this.thread});

  @override
  State<ThreadDetailView> createState() => _ThreadDetailViewState();
}

class _ThreadDetailViewState extends State<ThreadDetailView> {
  final ThreadController _controller = ThreadController();

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    await _controller.loadThreadContent(widget.thread);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.thread.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Ouvrir dans le navigateur',
            onPressed: () => _openInBrowser(widget.thread.link),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.refresh,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(_controller.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _controller.refresh,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (!_controller.hasPosts) {
            return const Center(
              child: Text('Aucun message trouvé dans ce topic'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _controller.posts.length,
            itemBuilder: (context, index) {
              return _PostCard(
                post: _controller.posts[index],
                isOriginalPost: index == 0,
                posts: _controller.posts,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir le lien: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _PostCard extends StatelessWidget {
  final ForumPost post;
  final bool isOriginalPost;
  final List<ForumPost> posts;

  const _PostCard({
    required this.post,
    required this.isOriginalPost,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: isOriginalPost ? 4 : 2,
      color: isOriginalPost 
          ? colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du message
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    post.author.isNotEmpty 
                        ? post.author[0].toUpperCase() 
                        : '?',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(post.pubDate),
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOriginalPost)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'OP',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Contenu du message avec gestion des URLs et citations
            _buildMessageContent(context, post.content),
          ],
        ),
      ),
    );
  }

  bool _isQuotePattern(String line) {
    // Détecter plusieurs patterns de citation
    final patterns = [
      r'^Le \d{2}/\d{2}/\d{4} à \d{2}:\d{2}:\d{2}, .+ a écrit :?$',
      r'^Le \d{1,2}/\d{1,2}/\d{4} à \d{1,2}:\d{2}:\d{2}, .+ a écrit :?$',
      r'^\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2} .+ :?$',
      r'^@\w+\s*:?$',
      r'^>\s*.+$',
    ];
    
    final trimmedLine = line.trim();
    
    for (final pattern in patterns) {
      if (RegExp(pattern).hasMatch(trimmedLine)) {
        return true;
      }
    }
    
    return false;
  }

  String _findQuotedMessage(String quoteLine) {
    // Debug: afficher ce qu'on cherche
    debugPrint('Recherche de citation dans: $quoteLine');
    
    // Améliorer l'extraction d'informations de citation
    String? author;
    String? dateStr;
    String? timeStr;
    
    // Pattern principal JVC - plus flexible
    var quoteRegex = RegExp(r'Le (\d{1,2}/\d{1,2}/\d{4}) à (\d{1,2}:\d{2}:\d{2}), (.+?) a écrit', caseSensitive: false);
    var match = quoteRegex.firstMatch(quoteLine);
    
    if (match != null) {
      dateStr = match.group(1)!;
      timeStr = match.group(2)!;
      author = match.group(3)!.trim();
      debugPrint('Pattern trouvé - Auteur: $author, Date: $dateStr, Heure: $timeStr');
    } else {
      // Pattern alternatif simplifié
      quoteRegex = RegExp(r'(\d{1,2}/\d{1,2}/\d{4}).+?(\d{1,2}:\d{2}:\d{2}).+?([^:]+)\s*:?\s*$');
      match = quoteRegex.firstMatch(quoteLine);
      
      if (match != null) {
        dateStr = match.group(1)!;
        timeStr = match.group(2)!;
        author = match.group(3)!.trim();
        debugPrint('Pattern alternatif trouvé - Auteur: $author');
      } else {
        // Essayer de juste extraire un nom d'utilisateur
        final nameRegex = RegExp(r'([A-Za-z0-9_-]+)\s*a écrit|@([A-Za-z0-9_-]+)', caseSensitive: false);
        final nameMatch = nameRegex.firstMatch(quoteLine);
        if (nameMatch != null) {
          author = (nameMatch.group(1) ?? nameMatch.group(2))!.trim();
          debugPrint('Nom d\'utilisateur extrait: $author');
        }
      }
    }
    
    if (author != null && author.isNotEmpty) {
      debugPrint('Recherche de messages de: $author parmi ${posts.length} posts');
      
      // Chercher le message avec une approche plus flexible
      ForumPost? foundPost;
      
      // 1. Recherche exacte avec date/heure si disponible
      if (dateStr != null && timeStr != null) {
        for (final post in posts) {
          if (_authorMatches(post.author, author) && _matchesDateTime(post.pubDate, dateStr, timeStr)) {
            foundPost = post;
            debugPrint('Message trouvé avec date exacte: ${post.author}');
            break;
          }
        }
      }
      
      // 2. Recherche par auteur sans date (le plus récent)
      if (foundPost == null) {
        for (int i = posts.length - 1; i >= 0; i--) {
          final post = posts[i];
          if (_authorMatches(post.author, author)) {
            foundPost = post;
            debugPrint('Message trouvé par auteur: ${post.author}');
            break;
          }
        }
      }
      
      if (foundPost != null) {
        String content = foundPost.content.trim();
        
        // Nettoyer le contenu
        content = _cleanQuotedContent(content);
        
        if (content.isEmpty) {
          return 'Message vide ou contenant uniquement des citations';
        }
        
        // Limiter la longueur
        const maxLength = 150;
        if (content.length > maxLength) {
          content = '${content.substring(0, maxLength).trim()}...';
        }
        
        // Ajouter des informations contextuelles
        String contextInfo = '';
        if (foundPost.postNumber > 0) {
          contextInfo = ' (Message #${foundPost.postNumber})';
        }
        
        return '$content$contextInfo';
      } else {
        debugPrint('Aucun message trouvé pour l\'auteur: $author');
        
        // Lister tous les auteurs disponibles pour debug
        final availableAuthors = posts.map((p) => p.author).toSet().toList();
        debugPrint('Auteurs disponibles: $availableAuthors');
      }
    }
    
    return '';
  }

  bool _authorMatches(String postAuthor, String searchAuthor) {
    final normalizedPostAuthor = postAuthor.trim().toLowerCase();
    final normalizedSearchAuthor = searchAuthor.trim().toLowerCase();
    
    // Correspondance exacte
    if (normalizedPostAuthor == normalizedSearchAuthor) {
      return true;
    }
    
    // Correspondance partielle (contient)
    if (normalizedPostAuthor.contains(normalizedSearchAuthor) || 
        normalizedSearchAuthor.contains(normalizedPostAuthor)) {
      return true;
    }
    
    // Supprimer les caractères spéciaux et réessayer
    final cleanPostAuthor = normalizedPostAuthor.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanSearchAuthor = normalizedSearchAuthor.replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    return cleanPostAuthor == cleanSearchAuthor;
  }

  String _cleanQuotedContent(String content) {
    // Supprimer les citations imbriquées
    final lines = content.split('\n');
    final cleanLines = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      // Ignorer les lignes qui sont elles-mêmes des citations
      if (!trimmed.startsWith('>') && 
          !_isQuotePattern(trimmed) &&
          trimmed.isNotEmpty) {
        cleanLines.add(line);
      }
    }
    
    String cleanContent = cleanLines.join('\n').trim();
    
    // Supprimer les balises HTML
    cleanContent = cleanContent.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Normaliser les espaces
    cleanContent = cleanContent.replaceAll(RegExp(r'\s+'), ' ');
    
    // Supprimer les caractères spéciaux en début/fin
    cleanContent = cleanContent.replaceAll(RegExp(r'^[^\w\s]+|[^\w\s]+$'), '');
    
    return cleanContent.trim();
  }

  bool _matchesDateTime(DateTime postDate, String dateStr, String timeStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return false;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      final timeParts = timeStr.split(':');
      if (timeParts.length < 2) return false;
      
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      // Vérification avec tolérance élargie
      final dateMatch = postDate.day == day &&
                       postDate.month == month &&
                       (postDate.year == year || postDate.year == 2000 + year);
      
      final timeMatch = postDate.hour == hour &&
                       (postDate.minute - minute).abs() <= 5; // Tolérance de 5 minutes
      
      return dateMatch && timeMatch;
    } catch (e) {
      return false;
    }
  }

  TextSpan _buildQuoteSpan(BuildContext context, String quoteLine) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Déterminer le type de citation et agir en conséquence
    if (_isQuotePattern(quoteLine)) {
      final quotedContent = _findQuotedMessage(quoteLine);
      
      String displayText;
      if (quotedContent.isNotEmpty) {
        // Formater l'affichage avec des icônes et une meilleure présentation
        displayText = '$quoteLine\n\n📝 Citation :\n"$quotedContent"';
      } else {
        // Ne plus afficher "Message original non trouvé", juste la citation brute
        displayText = quoteLine;
      }
      
      return TextSpan(
        text: displayText,
        style: TextStyle(
          color: colorScheme.primary.withOpacity(0.8),
          fontStyle: FontStyle.italic,
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          fontSize: 14,
        ),
      );
    }
    
    // Citation simple avec ">"
    return TextSpan(
      text: quoteLine,
      style: TextStyle(
        color: colorScheme.primary.withOpacity(0.8),
        fontStyle: FontStyle.italic,
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        fontSize: 14,
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, String content) {
    final spans = <TextSpan>[];
    final lines = content.split('\n');
    
    bool inQuoteBlock = false;
    final quoteLines = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Détecter le début d'un bloc de citation
      if (_isQuotePattern(line) && !inQuoteBlock) {
        // Si on a des lignes normales accumulées, les traiter d'abord
        if (quoteLines.isNotEmpty) {
          for (final quoteLine in quoteLines) {
            spans.addAll(_parseLineForUrls(context, quoteLine));
            spans.add(const TextSpan(text: '\n'));
          }
          quoteLines.clear();
        }
        
        inQuoteBlock = true;
        quoteLines.add(line);
      }
      // Si on est dans un bloc de citation
      else if (inQuoteBlock) {
        // Continuer à accumuler les lignes de citation
        if (line.trim().isEmpty || line.trim().startsWith('>') || _isQuotePattern(line)) {
          quoteLines.add(line);
        } else {
          // Fin du bloc de citation, traiter le bloc complet
          final fullQuote = quoteLines.join('\n');
          spans.add(_buildQuoteSpan(context, fullQuote));
          spans.add(const TextSpan(text: '\n'));
          
          // Traiter la ligne courante comme du texte normal
          spans.addAll(_parseLineForUrls(context, line));
          if (i < lines.length - 1) {
            spans.add(const TextSpan(text: '\n'));
          }
          
          inQuoteBlock = false;
          quoteLines.clear();
        }
      }
      // Ligne normale
      else {
        spans.addAll(_parseLineForUrls(context, line));
        if (i < lines.length - 1) {
          spans.add(const TextSpan(text: '\n'));
        }
      }
    }
    
    // Traiter le dernier bloc de citation s'il existe
    if (inQuoteBlock && quoteLines.isNotEmpty) {
      final fullQuote = quoteLines.join('\n');
      spans.add(_buildQuoteSpan(context, fullQuote));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: DefaultTextStyle.of(context).style,
      ),
    );
  }

  List<TextSpan> _parseLineForUrls(BuildContext context, String line) {
    final colorScheme = Theme.of(context).colorScheme;
    final spans = <TextSpan>[];
    
    // Regex pour détecter les URLs
    final urlRegex = RegExp(
      r'https?://[^\s<>"]+|www\.[^\s<>"]+',
      caseSensitive: false,
    );
    
    int lastMatchEnd = 0;
    
    for (final match in urlRegex.allMatches(line)) {
      // Ajouter le texte avant l'URL
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: line.substring(lastMatchEnd, match.start),
        ));
      }
      
      // Ajouter l'URL cliquable
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: TextStyle(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w500,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _launchUrl(url),
      ));
      
      lastMatchEnd = match.end;
    }
    
    // Ajouter le reste du texte après la dernière URL
    if (lastMatchEnd < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastMatchEnd),
      ));
    }
    
    // Si aucune URL trouvée, retourner le texte simple
    if (spans.isEmpty) {
      spans.add(TextSpan(text: line));
    }
    
    return spans;
  }

  Future<void> _launchUrl(String url) async {
    try {
      // Ajouter http:// si nécessaire
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'http://$url';
      }
      
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture de l\'URL: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year} à '
           '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }
}