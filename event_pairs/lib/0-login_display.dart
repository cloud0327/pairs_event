import 'package:flutter/material.dart';

import 'package:event_pairs/1-tab_page.dart';

class LoginDisplay extends StatelessWidget {
  const LoginDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (context) => const TabPage()),
            );
          },
          child: const Text('登録する'),
        ),
      ),
    );
  }
}
