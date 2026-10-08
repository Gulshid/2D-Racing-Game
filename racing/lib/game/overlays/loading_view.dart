import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({required this.progress, super.key});

  final ValueNotifier<double> progress;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0B1F3A),
      child: Center(
        child: SizedBox(
          width: 260,
          child: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, value, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('LOADING', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
