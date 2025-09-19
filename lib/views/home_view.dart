// home_view.dart
import 'package:flutter/material.dart';
import '../controllers/theme_controller.dart';
import '../controllers/forum_controller.dart';
import '../controllers/rss_service.dart';
import '../models/forum.dart';
import '../views/drawer_menu.dart';
import '../views/forum_view.dart';
import 'thread_view.dart';
String searchQuery = "";
class HomeView extends StatefulWidget {
  final ThemeController themeController;
  const HomeView({super.key, required this.themeController});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ForumController forumController = ForumController();

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
    drawer: DrawerMenu(themeController: widget.themeController),
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
  title: Text(category),
  children: forums.map((forum) {
    return Card(
      child: ListTile(
        title: Text(forum.title),
        subtitle: Text("Source: ${forum.source}"),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              forumController.removeForum(forum);
            });
          },
        ),
    onTap: () async {
  try {
    final rssService = RssService();
    final threads = await rssService.fetchThreads(forum.url);

    if (threads.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ThreadView(forumTitle: forum.title, threads: threads),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucun thread trouvé")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur: $e")),
    );
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
} void _showAddForumDialog(BuildContext context) {
  final urlController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Ajouter un flux RSS"),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: "RSS Feed",
            hintText: "https://www.jeuxvideo.com/rss/forums/51.xml",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text("Ajouter"),
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                try {
                  final rssService = RssService();
                  final forums = await rssService.fetchForumsFromRss(url);

                  setState(() {
                    forumController.addForums(forums);
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${forums.length} forums ajoutés depuis ce flux")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur : $e")),
                  );
                }
              }
            },
          ),
        ],
      );
    },
  );
}
}
