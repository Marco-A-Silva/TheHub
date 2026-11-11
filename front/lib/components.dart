import 'package:flutter/material.dart';
import 'package:front/manager.dart';

class HubTab {
  final String title;
  final IconData icon;
  final Widget view;

  HubTab({required this.title, required this.icon, required this.view});
}

class GenCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onClick;

  const GenCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.circle,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return Card( 
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onClick,
      ),
    );
  }
}

class MusicPlayer extends StatelessWidget {
  const MusicPlayer({super.key});
  
  @override
  Widget build(BuildContext context) {
    final audio = get<AudioManager>();

    return AnimatedBuilder(
      animation: audio,
      builder: (context, child) {
        final song = audio.currentSong;
        final bool canGoBack = audio.index > 0;
        final hasAudio = song != null;

        return AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          offset: hasAudio ? Offset.zero : const Offset(0, 1),
          child: Material(
            elevation: 8,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Container(
              height: 75,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.purpleAccent, size: 32),
                  const SizedBox(width: 16),
                
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          song?.title ?? "Loading...", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song?.artist ?? "", 
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                          overflow:  TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                
                  IconButton(
                    icon: Icon(Icons.skip_previous, size: 30, color: canGoBack ? Colors.white : Colors.white24),
                    onPressed: canGoBack ? () => audio.prev() : null, 
                  ),
                
                  StreamBuilder<bool>(
                    stream: audio.player.stream.playing,
                    builder: (context, playingSnapshot) {
                      final isPlaying = playingSnapshot.data ?? false;
                      return IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, 
                          size: 45, 
                          color: Colors.purpleAccent
                        ),
                        onPressed: () => audio.toggle(), 
                      );
                    },
                  ),
                
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 30, color: Colors.white),
                    onPressed: () => audio.next(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
