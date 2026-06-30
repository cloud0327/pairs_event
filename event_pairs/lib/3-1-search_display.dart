import 'package:flutter/material.dart';
import 'package:event_pairs/3-2-search_description.dart';
import 'package:event_pairs/event_sample.dart';

class SearchDisplay extends StatelessWidget {
  const SearchDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'イベント検索',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          _eventCard(
            context,
            color: Color(0xFF2F93DD),
            title: 'サークル見学\nまとめ',
            subtitle: 'いろんなサークルを\n見に行こう!',
            imagePath: 'assets/images/circle_visit.png',
            category: EventCategory.circleVisit,
          ),
          _eventCard(
            context,
            color: Color(0xFFF47B22),
            title: '履修登録相談\nまとめ',
            subtitle: '戦費や同級生に\n悩みを打ち明けよう!',
            imagePath: 'assets/images/open_seminar.png',
            category: EventCategory.openSeminar,
          ),
          _eventCard(
            context,
            color: Color(0xFF48B98E),
            title: '飲食店募集\nまとめ',
            subtitle: '気になった飲食店に\n行こう!',
            imagePath: 'assets/images/festival_staff.png',
            category: EventCategory.foodRecruitment,
          ),
        ],
      ),
    );
  }
}

Widget _eventCard(
  BuildContext context, {
  required Color color,
  required String title,
  required String subtitle,
  required String imagePath,
  required EventCategory category,
}) {
  return Card(
    clipBehavior: Clip.antiAlias,
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => EventListPage(category: category),
          ),
        );
      },
      child: SummaryCardContent(
        color: color,
        title: title,
        subtitle: subtitle,
        imagePath: imagePath,
      ),
    ),
  );
}

class SummaryCardContent extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;
  final String imagePath;

  const SummaryCardContent({
    super.key,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Image.asset(imagePath, width: 60, height: 80, fit: BoxFit.cover),
        ],
      ),
    );
  }
}
