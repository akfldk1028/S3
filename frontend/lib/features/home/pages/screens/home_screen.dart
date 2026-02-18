import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../workspace/widgets/top_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(52),
        child: TopBar(),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Home',
              style: ShadTheme.of(context).textTheme.h1,
            ),
            const SizedBox(height: 16),
            ShadButton(
              onPressed: () => context.push('/profile'),
              child: const Text('Go to Profile'),
            ),
            const SizedBox(height: 8),
            ShadButton.outline(
              onPressed: () => context.push('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
