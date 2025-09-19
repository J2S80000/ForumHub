// views/thread_view.dart
import 'package:flutter/material.dart';
import '../models/thread.dart';
import 'thread_detail_view.dart';

class ThreadView extends StatelessWidget {
  final String forumTitle;
  final List<Thread> threads;

  const ThreadView({
    super.key,
    required this.forumTitle,
    required this.threads,
  });
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(title: Text(forumTitle)),
  body: ListView.builder(
    itemCount: threads.length,
    itemBuilder: (context, index) {
      final thread = threads[index];
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            thread.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("👤 ${thread.author}"),
                  Text(
                    "${thread.pubDate.day}/${thread.pubDate.month}/${thread.pubDate.year}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ThreadDetailView(thread: thread),
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
