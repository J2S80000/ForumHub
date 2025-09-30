import 'package:flutter/material.dart';
import '../controllers/theme_controller.dart';
import '../controllers/forum_controller.dart';
import '../controllers/rss_service.dart';
import '../models/forum.dart';
import '../views/drawer_menu.dart';
import 'thread_view.dart';

class HomeView extends StatefulWidget {
  final ThemeController themeController;
  const HomeView({super.key, required this.themeController});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ForumController forumController = ForumController();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    await forumController.init();
    setState(() {});
  }

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Regroupement + filtrage
    final forumsByCategory = <String, List<Forum>>{};
    for (var forum in forumController.forums) {
      if (searchQuery.isEmpty ||
          forum.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          forum.url.toLowerCase().contains(searchQuery.toLowerCase())) {
        forumsByCategory.putIfAbsent(forum.category, () => []).add(forum);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("ForumHub"),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        
      ),
      drawer: DrawerMenu(
        themeController: widget.themeController,
        forumController: forumController,
        onForumsChanged: () => setState(() {}),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Rechercher un forum...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: forumsByCategory.isEmpty
                ? const Center(child: Text("Aucun forum trouvé"))
                : ListView(
                    children: forumsByCategory.entries.map((entry) {
                      final category = entry.key;
                      final forums = entry.value;

                      return ExpansionTile(
                        title: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: forums.map((forum) {
                          return Card(
                            child: ListTile(
                              title: Text(forum.title),
                              subtitle: Text(forum.url),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    forumController.removeForum(forum);
                                  });
                                },
                              ),
                              onTap: () async {
                                // Navigation ThreadView
                                try {
                                  // Afficher un indicateur de chargement
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  // Charger les threads depuis le flux RSS
                                  final rssService = RssService();
                                  final threads = await rssService.fetchThreads(
                                      forum.url);

                                  // Fermer l'indicateur de chargement
                                  if (mounted) Navigator.of(context).pop();

                                  // Naviguer vers ThreadView
                                  if (mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ThreadView(
                                          forumTitle: forum.title,
                                          threads: threads,
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // Fermer l'indicateur de chargement en cas d'erreur
                                  if (mounted) Navigator.of(context).pop();

                                  // Afficher l'erreur
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "Erreur de chargement: ${e.toString()}"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddForumDialog(context),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddForumDialog(BuildContext context) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Forum"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: "RSS Feed or Link",
                  hintText: "https://www.jeuxvideo.com/rss/forums/51.xml",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Add"),
              onPressed: () {
                final title = titleController.text.trim();
                final url = urlController.text.trim();
                if (title.isNotEmpty && url.isNotEmpty) {
                  forumController.addForum(title, url);
                  setState(() {}); // met à jour la vue
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'export':
        await _exportForums();
        break;
      case 'import':
        await _importForums();
        break;
      case 'clear':
        await _clearAllForums();
        break;
    }
  }

  Future<void> _exportForums() async {
    try {
      final filePath = await forumController.exportForums();
      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Forums exportés vers: $filePath'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Partager',
              onPressed: () {
                // Ici tu peux ajouter une fonction de partage si nécessaire
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importForums() async {
    try {
      final success = await forumController.importForums();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Forums importés avec succès!'
                : 'Aucun fichier sélectionné ou erreur d\'import'),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
        if (success) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'import: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllForums() async {
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
      await forumController.clearAllForums();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tous les forums ont été supprimés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
