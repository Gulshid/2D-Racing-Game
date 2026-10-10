import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racing/app/design/app_widgets.dart';
import 'package:racing/features/providers/progress_provider.dart';

/// The player's coin balance, shown in the top area of progress screens.
class CoinsBadge extends ConsumerWidget {
  const CoinsBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(progressProvider.select((s) => s.save.coins));
    return HudPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, size: 18, color: Color(0xFFFFC107)),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
