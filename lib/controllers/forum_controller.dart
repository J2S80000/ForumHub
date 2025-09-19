import 'package:flutter/material.dart';
import '../models/forum.dart';

class ForumController extends ChangeNotifier {
  final List<Forum> _forums = [];

  List<Forum> get forums => List.unmodifiable(_forums);

  void addForum(String title, String url) {
    _forums.add(Forum(title: title, url: url));
    notifyListeners();
  }
}
