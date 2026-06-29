import 'package:flutter/material.dart';

import 'package:event_pairs/4-my_page.dart';
import 'package:event_pairs/2-recruitment_display.dart';
import 'package:event_pairs/3-1-search_display.dart';

class TabPage extends StatelessWidget {
  const TabPage({super.key});

  static const _tabs = <Tab>[
    Tab(text: '見つける'),
    Tab(text: '募集する'),
    Tab(text: 'マイページ'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Event Pairs'),
          bottom: const TabBar(tabs: _tabs),
        ),
        body: const TabBarView(
          children: <Widget>[SearchDisplay(), RecruitmentDisplay(), MyPage()],
        ),
      ),
    );
  }
}
