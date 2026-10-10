import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racing/game/audio/audio_service.dart';

/// Starts the menu music when a menu screen opens. Repeating it is harmless:
/// the audio service ignores a request for the track that is already playing.
class MenuMusic extends ConsumerStatefulWidget {
  const MenuMusic({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<MenuMusic> createState() => _MenuMusicState();
}

class _MenuMusicState extends ConsumerState<MenuMusic> {
  @override
  void initState() {
    super.initState();
    ref.read(audioServiceProvider).playMusic(Music.menu);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
