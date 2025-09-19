import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RssStorageService {
  static const _key = "saved_rss_feeds";

  /// Sauvegarde une liste d'URLs
  Future<void> saveFeeds(List<String> feeds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(feeds));
  }

  /// Récupère la liste sauvegardée
  Future<List<String>> loadFeeds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    return List<String>.from(jsonDecode(jsonString));
  }

  /// Ajoute un flux à la liste
  Future<void> addFeed(String feedUrl) async {
    final feeds = await loadFeeds();
    if (!feeds.contains(feedUrl)) {
      feeds.add(feedUrl);
      await saveFeeds(feeds);
    }
  }

  /// Supprime un flux
  Future<void> removeFeed(String feedUrl) async {
    final feeds = await loadFeeds();
    feeds.remove(feedUrl);
    await saveFeeds(feeds);
  }
}
