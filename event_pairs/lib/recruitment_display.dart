import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RecruitmentDisplay extends StatefulWidget {
  const RecruitmentDisplay({super.key});

  @override
  State<RecruitmentDisplay> createState() => _RecruitmentDisplayState();
}

class _RecruitmentDisplayState extends State<RecruitmentDisplay> {
  String purpose = '話したい';
  int memberCount = 2;

  final messageController = TextEditingController();
  final meetingTimeController = TextEditingController(text: '12:45');

  @override
  void dispose() {
    messageController.dispose();
    meetingTimeController.dispose();
    super.dispose();
  }

  void selectTime() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return Container(
          height: 250,
          color: Colors.white,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: true,
            onDateTimeChanged: (time) {
              setState(() {
                meetingTimeController.text =
                    '${time.hour.toString().padLeft(2, '0')}:'
                    '${time.minute.toString().padLeft(2, '0')}';
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('どんな人と行きたい？', style: _titleStyle),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _purposeButton('話したい', Icons.chat_bubble_outline),
                _purposeButton('仲間募集', Icons.groups_outlined),
                _purposeButton('一緒に見学', Icons.location_on_outlined),
                _purposeButton('その他', Icons.card_giftcard),
              ],
            ),
            const SizedBox(height: 24),
            const Text('あなたの希望', style: _titleStyle),
            const SizedBox(height: 8),
            const Text('タイトル', style: _titleStyle),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            _card(
              child: ListTile(
                title: const Text('集合時間（目安）'),
                trailing: const Icon(Icons.chevron_right),
                onTap: selectTime,
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Row(
                children: [
                  const Icon(Icons.people_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('募集人数')),
                  IconButton(
                    onPressed: memberCount > 1
                        ? () => setState(() => memberCount--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$memberCount人まで'),
                  IconButton(
                    onPressed: () => setState(() => memberCount++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('メッセージ（任意）', style: _titleStyle),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('募集を投稿する'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _purposeButton(String label, IconData icon) {
    final selected = purpose == label;

    return GestureDetector(
      onTap: () => setState(() => purpose = label),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: selected ? Colors.deepOrange : Colors.white,
            child: Icon(
              icon,
              color: selected ? Colors.white : Colors.deepOrange,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xffe5e5e5)),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

const _titleStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
