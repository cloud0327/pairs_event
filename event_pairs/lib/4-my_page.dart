import 'package:flutter/material.dart';

import 'package:event_pairs/5-message.dart';
import 'package:event_pairs/event_store.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ValueListenableBuilder<int>(
        valueListenable: EventStore.version,
        builder: (context, _, __) {
          final applications = EventStore.applications;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final application = applications[index];
              final event = application.event;

              return Card(
                child: ListTile(
                  title: Text(event.title),
                  subtitle: Text(
                    '${event.category.label} / ${event.time} / ${event.place}',
                  ),
                  leading: const Icon(Icons.check_circle_outline),
                  trailing: const Icon(Icons.chat_bubble_outline),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) {
                          return Scaffold(
                            appBar: AppBar(title: Text(event.title)),
                            body: const MessagePage(),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
