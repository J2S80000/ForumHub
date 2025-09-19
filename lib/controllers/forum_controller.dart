import 'package:flutter/material.dart';
import '../models/forum.dart';

class ForumController extends ChangeNotifier {
  final List<Forum> _forums = [];

  List<Forum> get forums => List.unmodifiable(_forums);

  void addForums(List<Forum> newForums) {
    _forums.addAll(newForums); // ← ici
    notifyListeners();
  }

  void addForum(String title, String url, String category, String source) {
    _forums.add(Forum(title: title, url: url, category: category, source: source));
    notifyListeners();
  }

  void removeForum(Forum forum) {
    _forums.remove(forum);
    notifyListeners();
  }
}

