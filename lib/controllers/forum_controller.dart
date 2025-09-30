import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../models/forum.dart';

class ForumController extends ChangeNotifier {
  final List<Forum> _forums = [];
  static const String _storageKey = 'saved_forums';

  List<Forum> get forums => List.unmodifiable(_forums);
  List<Forum> get favoriteForums => _forums.where((f) => f.isFavorite).toList();

  // Initialiser et charger les forums sauvegardés
  Future<void> init() async {
    await _loadForums();
  }

  void addForum(String title, String url) {
    String category = "Autres";
    if (url.contains("jeuxvideo.com")) {
      category = "JVC";
    } else if (url.contains("reddit.com")) {
      category = "Reddit";
    }
    
    _forums.add(Forum(title: title, url: url, category: category));
    _saveForums();
    notifyListeners();
  }

  void removeForum(Forum forum) {
    _forums.remove(forum);
    _saveForums();
    notifyListeners();
  }

  // Basculer le statut favoris d'un forum
  void toggleFavorite(Forum forum) {
    final index = _forums.indexWhere((f) => f.url == forum.url);
    if (index != -1) {
      _forums[index] = forum.copyWith(isFavorite: !forum.isFavorite);
      _saveForums();
      notifyListeners();
    }
  }

  // Charger les forums depuis SharedPreferences
  Future<void> _loadForums() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final forumsJson = prefs.getString(_storageKey);
      
      if (forumsJson != null) {
        final List<dynamic> decoded = json.decode(forumsJson);
        _forums.clear();
        _forums.addAll(decoded.map((json) => Forum.fromJson(json)).toList());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des forums: $e');
    }
  }

  // Sauvegarder les forums dans SharedPreferences
  Future<void> _saveForums() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final forumsJson = json.encode(_forums.map((forum) => forum.toJson()).toList());
      await prefs.setString(_storageKey, forumsJson);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des forums: $e');
    }
  }

  // Exporter les forums vers un fichier JSON
  Future<String?> exportForums() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/forumhub_forums_export.json');
      
      final exportData = {
        'version': '1.0',
        'export_date': DateTime.now().toIso8601String(),
        'forums': _forums.map((forum) => forum.toJson()).toList(),
      };
      
      await file.writeAsString(json.encode(exportData));
      return file.path;
    } catch (e) {
      debugPrint('Erreur lors de l\'export: $e');
      return null;
    }
  }

  // Importer les forums depuis un fichier JSON
  Future<bool> importForums() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final data = json.decode(content);

        if (data['forums'] != null) {
          final List<dynamic> forumsData = data['forums'];
          final importedForums = forumsData.map((json) => Forum.fromJson(json)).toList();
          
          // Ajouter les forums importés (éviter les doublons)
          for (final forum in importedForums) {
            if (!_forums.any((existing) => existing.url == forum.url)) {
              _forums.add(forum);
            }
          }
          
          _saveForums();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de l\'import: $e');
      return false;
    }
  }

  // Réinitialiser tous les forums
  Future<void> clearAllForums() async {
    _forums.clear();
    _saveForums();
    notifyListeners();
  }
}
