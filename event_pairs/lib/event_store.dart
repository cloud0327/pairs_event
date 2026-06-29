import 'package:flutter/foundation.dart';

enum EventCategory {
  circleVisit('サークル見学'),
  openSeminar('履修登録相談'),
  foodRecruitment('飲食店募集');

  const EventCategory(this.label);
  final String label;
}

class EventInfo {
  final String id;
  final EventCategory category;
  final String title;
  final String description;
  final String place;
  final String time;
  final int capacity;
  final String ownerName;

  const EventInfo({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.place,
    required this.time,
    required this.capacity,
    required this.ownerName,
  });
}

class EventApplication {
  final String id;
  final EventInfo event;
  final DateTime appliedAt;

  const EventApplication({
    required this.id,
    required this.event,
    required this.appliedAt,
  });
}

class EventStore {
  static final version = ValueNotifier<int>(0);

  static final List<EventInfo> _events = [
    EventInfo(
      id: 'event_1',
      category: EventCategory.circleVisit,
      title: '軽音サークル見学',
      description: '初心者歓迎。昼休みに部室を見に行きます。',
      place: '学生会館 2F',
      time: '12:40',
      capacity: 4,
      ownerName: '田中',
    ),
    EventInfo(
      id: 'event_2',
      category: EventCategory.openSeminar,
      title: '履修登録を一緒に考える会',
      description: 'おすすめ授業や時間割の組み方を相談できます。',
      place: '図書館前',
      time: '14:00',
      capacity: 6,
      ownerName: '佐藤',
    ),
    EventInfo(
      id: 'event_3',
      category: EventCategory.foodRecruitment,
      title: '学食で昼ごはん',
      description: '空きコマに一緒にごはん行ける人募集。',
      place: '第一食堂',
      time: '12:15',
      capacity: 3,
      ownerName: '山田',
    ),
  ];

  static final List<EventApplication> _applications = [];

  static List<EventInfo> eventsByCategory(EventCategory category) {
    return _events.where((event) => event.category == category).toList();
  }

  static List<EventApplication> get applications {
    return List.unmodifiable(_applications);
  }

  static bool hasApplied(String eventId) {
    return _applications.any((application) => application.event.id == eventId);
  }

  static void addEvent({
    required EventCategory category,
    required String title,
    required String description,
    required String place,
    required String time,
    required int capacity,
  }) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    _events.insert(
      0,
      EventInfo(
        id: id,
        category: category,
        title: title,
        description: description,
        place: place,
        time: time,
        capacity: capacity,
        ownerName: 'あなた',
      ),
    );

    version.value++;
  }

  static void apply(EventInfo event) {
    if (hasApplied(event.id)) {
      return;
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();

    _applications.insert(
      0,
      EventApplication(id: id, event: event, appliedAt: DateTime.now()),
    );

    version.value++;
  }
}
