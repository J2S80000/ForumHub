// lib/views/forum_view.dart
import 'package:flutter/material.dart';
import '../models/forum.dart';
import '../models/thread.dart';
import '../controllers/rss_service.dart';
import 'thread_detail_view.dart';

class ForumView extends StatefulWidget {
  final Forum forum; // Forum sélectionné

  const ForumView({super.key, required this.forum});

  @override
  State<ForumView> createState() => _ForumViewState();
}

class _ForumViewState extends State<ForumView> {
  final RssService rssService = RssService();
  List<Thread> threads = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final fetchedThreads = await rssService.fetchThreads(widget.forum.url);
      setState(() {
        threads = fetchedThreads;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.forum.title),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadThreads,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadThreads,
                        child: const Text("Réessayer"),
                      ),
                    ],
                  ),
                )
              : threads.isEmpty
                  ? const Center(child: Text("Aucun thread trouvé"))
                  : ListView.builder(
                      itemCount: threads.length,
                      itemBuilder: (context, index) {
                        final thread = threads[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              thread.title,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  thread.description.isNotEmpty
                                      ? thread.description
                                      : "No description",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("👤 ${thread.author}"),
                                    Text(
                                      "${thread.pubDate.day}/${thread.pubDate.month}/${thread.pubDate.year}",
                                      style: TextStyle(
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ThreadDetailView(thread: thread),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
