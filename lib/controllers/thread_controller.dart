// lib/controllers/thread_controller.dart
import 'package:flutter/foundation.dart';
import '../models/thread.dart';
import '../models/forum_post.dart';
import '../services/forum_content_service.dart';

class ThreadController extends ChangeNotifier {
  final ForumContentService _contentService = ForumContentService();
  
  // État du contrôleur
  bool _isLoading = false;
  String? _error;
  List<ForumPost> _posts = [];
  Thread? _currentThread;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ForumPost> get posts => _posts;
  Thread? get currentThread => _currentThread;
  bool get hasError => _error != null;
  bool get hasPosts => _posts.isNotEmpty;

  // Charge le contenu d'un thread
  Future<void> loadThreadContent(Thread thread) async {
    _currentThread = thread;
    _setLoading(true);
    _clearError();

    try {
      final posts = await _contentService.fetchThreadContent(thread.link);
      _posts = posts;
      
      if (_posts.isEmpty) {
        _setError("Aucun message trouvé dans ce topic");
      }
    } catch (e) {
      _setError("Erreur lors du chargement: ${e.toString()}");
      _posts = [];
    } finally {
      _setLoading(false);
    }
  }

  // Recharge le contenu
  Future<void> refresh() async {
    if (_currentThread != null) {
      await loadThreadContent(_currentThread!);
    }
  }

  // Méthodes privées pour gérer l'état
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Nettoie le contrôleur
  void clear() {
    _posts.clear();
    _currentThread = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Méthodes utilitaires
  ForumPost? getOriginalPost() {
    return _posts.isNotEmpty ? _posts.first : null;
  }

  List<ForumPost> getReplies() {
    return _posts.length > 1 ? _posts.skip(1).toList() : [];
  }

  int get totalPosts => _posts.length;

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}