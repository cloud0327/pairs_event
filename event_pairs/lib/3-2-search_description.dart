import 'package:flutter/material.dart';

import 'package:event_pairs/event_store.dart';

class EventListPage extends StatelessWidget {
  final EventCategory category;

  const EventListPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${category.label} 一覧')),
      body: ValueListenableBuilder<int>(
        valueListenable: EventStore.version,
        builder: (context, _, __) {
          final events = EventStore.eventsByCategory(category);
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = events[index];

              return Card(
                child: ListTile(
                  title: Text(event.title),
                  subtitle: Text('${event.time} / ${event.place}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showApplySheet(context, event),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showApplySheet(BuildContext context, EventInfo event) {
    final applied = EventStore.hasApplied(event.id);

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(event.description),
                const SizedBox(height: 12),
                Text('場所: ${event.place}'),
                Text('時間: ${event.time}'),
                Text('募集人数: ${event.capacity}人まで'),
                Text('作成者: ${event.ownerName}'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: applied
                        ? null
                        : () {
                            EventStore.apply(event);
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('申請しました')),
                            );
                          },
                    child: Text(applied ? '申請済み' : '申請する'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
