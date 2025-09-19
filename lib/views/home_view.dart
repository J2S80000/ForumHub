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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ForumHub"),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      drawer: DrawerMenu(themeController: widget.themeController),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: forumController.forums.isEmpty
            ? const Center(child: Text("Add your favorites forum"))
            : ListView.builder(
                itemCount: forumController.forums.length,
                itemBuilder: (context, index) {
                  final forum = forumController.forums[index];
                  return Card(
                    child: ListTile(
                      title: Text(forum.title),
                      subtitle: Text(forum.url),
                      onTap: () async {
                        try {
                          final rssService = RssService();
                          final threads =
                              await rssService.fetchThreads(forum.url);

                          if (threads.isNotEmpty) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ThreadView(
                                  forumTitle: forum.title,
                                  threads: threads,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("No threads found")),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
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
}
