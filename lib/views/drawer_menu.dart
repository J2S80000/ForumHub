import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/theme_controller.dart';
import '../controllers/rss_storage_service.dart';

class DrawerMenu extends StatelessWidget {
  final ThemeController themeController;
  final RssStorageService storageService = RssStorageService();

  DrawerMenu({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primaryContainer),
            child: Text(
              "Menu",
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsPage(themeController: themeController),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: const Text("Import / Export"),
            onTap: () => _showImportExportDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.volunteer_activism),
            title: const Text("Donate"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About Us"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.verified),
            title: const Text("Version 1.0.0"),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showImportExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Import / Export RSS"),
        content: const Text("Voulez-vous importer ou exporter vos flux RSS ?"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _exportFeeds(context);
            },
            child: const Text("Exporter"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _importFeeds(context);
            },
            child: const Text("Importer"),
          ),
        ],
      ),
    );
  }

  Future<void> _exportFeeds(BuildContext context) async {
  try {
    final feeds = await storageService.loadFeeds();
    final jsonString = jsonEncode(feeds);

    final prefs = await SharedPreferences.getInstance();
    String? path = prefs.getString('rss_export_path');

    if (path == null) {
      path = await FilePicker.platform.saveFile(
        dialogTitle: 'Choisir où sauvegarder vos flux RSS',
        fileName: 'rss_feeds_export.json',
      );
      if (path != null) await prefs.setString('rss_export_path', path);
    }

    if (path != null) {
      final file = File(path);
      await file.writeAsString(jsonString);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Export réussi : $path")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur export : $e")),
    );
  }
}

Future<void> _importFeeds(BuildContext context) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true, // Important pour récupérer bytes si path est null
    );

    if (result != null) {
      String? path = result.files.single.path;
      List<int> bytes = result.files.single.bytes ?? [];

      String content;
      if (path != null) {
        content = await File(path).readAsString();
      } else if (bytes.isNotEmpty) {
        content = utf8.decode(bytes);
      } else {
        throw Exception("Fichier introuvable ou vide");
      }

      final List<dynamic> decoded = jsonDecode(content);
      final List<String> feeds = List<String>.from(decoded);
      await storageService.saveFeeds(feeds);

      // Sauvegarder le chemin pour import automatique
      if (path != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('rss_import_path', path);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Import réussi !")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur import : $e")),
    );
  }
}

  /// Charger automatiquement le dernier fichier importé
  Future<void> importLastFeedsAutomatically() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('rss_import_path');
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> decoded = jsonDecode(content);
        final List<String> feeds = List<String>.from(decoded);
        await storageService.saveFeeds(feeds);
      }
    }
  }
}

class SettingsPage extends StatelessWidget {
  final ThemeController themeController;

  const SettingsPage({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Appearance"),
            subtitle: Text(isDark ? "Dark Mode" : "Light Mode"),
            secondary: const Icon(Icons.dark_mode),
            value: isDark,
            onChanged: (val) {
              themeController.toggleTheme();
            },
          ),
        ],
      ),
    );
  }
}
