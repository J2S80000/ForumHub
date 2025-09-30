import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/theme_controller.dart';
import '../controllers/forum_controller.dart';

class DrawerMenu extends StatelessWidget {
  final ThemeController themeController;
  final ForumController? forumController;
  final VoidCallback? onForumsChanged;

  const DrawerMenu({
    super.key,
    required this.themeController,
    this.forumController,
    this.onForumsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.forum,
                  size: 48,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  "FocusForum",
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Gestionnaire de forums",
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Section Gestion des données
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              "Gestion des données",
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.file_upload_outlined, color: colorScheme.primary),
            title: const Text("Exporter les forums"),
            subtitle: const Text("Sauvegarder vos forums"),
            onTap: () => _exportForums(context),
          ),
          ListTile(
            leading: Icon(Icons.file_download_outlined, color: colorScheme.primary),
            title: const Text("Importer des forums"),
            subtitle: const Text("Restaurer des forums"),
            onTap: () => _importForums(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text("Supprimer tous les forums"),
            subtitle: const Text("Action irréversible"),
            onTap: () => _clearAllForums(context),
          ),
          
          const Divider(height: 32),
          
          // Section Application
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              "Application",
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: colorScheme.primary),
            title: const Text("Paramètres"),
            subtitle: const Text("Thème et préférences"),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsPage(themeController: themeController),
                ),
              );
            },
          ),
          
          const Divider(height: 32),
          
          // Section À propos
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              "À propos",
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.favorite_outline, color: Colors.pink),
            title: const Text("Soutenir le projet"),
            subtitle: const Text("Faire un don"),
            onTap: () {
              Navigator.of(context).pop();
              // Ajouter logique de donation
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.primary),
            title: const Text("À propos"),
            subtitle: const Text("En savoir plus"),
            onTap: () {
              Navigator.of(context).pop();
              // Ajouter page à propos
            },
          ),
          
          const Spacer(),
          
          // Version en bas
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Version 1.0.0",
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportForums(BuildContext context) async {
    if (forumController == null) return;

    Navigator.of(context).pop(); // Fermer le drawer

    try {
      final filePath = await forumController!.exportForums();
      if (filePath != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Forums exportés vers: $filePath'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importForums(BuildContext context) async {
    if (forumController == null) return;

    Navigator.of(context).pop(); // Fermer le drawer

    try {
      final success = await forumController!.importForums();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Forums importés avec succès!'
                : 'Aucun fichier sélectionné ou erreur d\'import'),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
        if (success && onForumsChanged != null) {
          onForumsChanged!(); // Mettre à jour la vue
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'import: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllForums(BuildContext context) async {
    if (forumController == null) return;

    Navigator.of(context).pop(); // Fermer le drawer

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer tous les forums ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await forumController!.clearAllForums();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tous les forums ont été supprimés'),
            backgroundColor: Colors.green,
          ),
        );
        if (onForumsChanged != null) {
          onForumsChanged!(); // Mettre à jour la vue
        }
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
      appBar: AppBar(title: const Text("Paramètres")),
      body: ListView(
        children: [
          // Section Apparence
          ListTile(
            title: Text(
              "Apparence",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text("Mode sombre"),
            subtitle: Text(isDark ? "Activé" : "Désactivé"),
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
          