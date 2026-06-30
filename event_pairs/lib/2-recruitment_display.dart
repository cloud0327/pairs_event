import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:event_pairs/event_sample.dart';
import 'package:event_pairs/ollama_message_service.dart';

class RecruitmentDisplay extends StatefulWidget {
  const RecruitmentDisplay({super.key});

  @override
  State<RecruitmentDisplay> createState() => _RecruitmentDisplayState();
}

class _RecruitmentDisplayState extends State<RecruitmentDisplay> {
  String purpose = '話したい';
  int memberCount = 2;
  int maxMemberCount = 5;
  EventCategory selectedCategory = EventCategory.circleVisit;
  bool isGeneratingMessage = false;

  final messageController = TextEditingController();
  final titleController = TextEditingController();
  final placeController = TextEditingController();
  final meetingTimeController = TextEditingController(text: '');
  final ollamaMessageService = OllamaMessageService();

  @override
  void dispose() {
    messageController.dispose();
    titleController.dispose();
    placeController.dispose();
    meetingTimeController.dispose();
    ollamaMessageService.dispose();
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

  void postEvent() {
    final title = titleController.text.trim();
    final place = placeController.text.trim();
    final message = messageController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('タイトルを入力してください')));
      return;
    }

    EventStore.addEvent(
      category: selectedCategory,
      title: title,
      description: message.isEmpty ? '一緒に行ける人を募集しています' : message,
      place: place.isEmpty ? '未定' : place,
      time: meetingTimeController.text,
      capacity: memberCount,
    );

    titleController.clear();
    placeController.clear();
    messageController.clear();
    setState(() {
      purpose = '話したい';
      memberCount = 2;
      selectedCategory = EventCategory.circleVisit;
      meetingTimeController.text = '';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('イベントを作成しました')));
    DefaultTabController.maybeOf(context)?.animateTo(0);
  }

  Future<void> generateMessage() async {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('先にタイトルを入力してください')));
      return;
    }

    setState(() {
      isGeneratingMessage = true;
    });

    try {
      final message = await ollamaMessageService.generateRecruitmentMessage(
        title: title,
        categoryLabel: selectedCategory.label,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        messageController.text = message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ollamaからメッセージを作成できませんでした')));
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingMessage = false;
        });
      }
    }
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
            const SizedBox(height: 16),
            const Text('タイトル', style: _titleStyle),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
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
            const Text('カテゴリ', style: _titleStyle),
            const SizedBox(height: 8),
            _card(
              child: DropdownButtonFormField<EventCategory>(
                key: ValueKey(selectedCategory),
                initialValue: selectedCategory,
                decoration: const InputDecoration(border: InputBorder.none),
                items: EventCategory.values.map((category) {
                  return DropdownMenuItem<EventCategory>(
                    value: category,
                    child: Text(category.label),
                  );
                }).toList(),
                onChanged: (category) {
                  if (category == null) {
                    return;
                  }

                  setState(() {
                    selectedCategory = category;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text('場所', style: _titleStyle),
            const SizedBox(height: 8),
            TextField(
              controller: placeController,
              decoration: InputDecoration(
                hintText: '例: 記念会館',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('時間を選択', style: _titleStyle),
            _card(
              child: ListTile(
                title: Text(meetingTimeController.text),
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
                    onPressed: (memberCount < maxMemberCount)
                        ? () => setState(() => memberCount++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Text('コメント（任意）', style: _titleStyle)),
                TextButton.icon(
                  onPressed: isGeneratingMessage ? null : generateMessage,
                  icon: isGeneratingMessage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(isGeneratingMessage ? '生成中' : 'AIで作成'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              maxLines: 5,
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
                onPressed: postEvent,
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
