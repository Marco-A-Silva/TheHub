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
  final Widget? trailing;
  final VoidCallback? onClick;

  const GenCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.circle,
    this.trailing,
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
        trailing: trailing,
        onTap: onClick,
      ),
    );
  }
}

class MusicPlayer extends StatefulWidget {
  const MusicPlayer({super.key});

  @override
  State<MusicPlayer> createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  double? _dragValue; // fracción 0..1 mientras arrastras la barra

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(h > 0 ? 2 : 1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _seekToFraction(AudioManager audio, double fraction) async {
    final total = audio.player.state.duration;
    if (total.inMilliseconds <= 0) return;
    await audio.player.seek(total * fraction);
  }

  Future<void> _commitDrag(AudioManager audio) async {
    final v = _dragValue;
    if (v == null) return;
    await _seekToFraction(audio, v);
    if (mounted) setState(() => _dragValue = null);
  }

  Widget _buildSeekBar(AudioManager audio) {
    return StreamBuilder<Duration>(
      stream: audio.player.stream.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = audio.player.state.duration;
        final canSeek = total.inMilliseconds > 0;
        final progress =
            canSeek ? position.inMilliseconds / total.inMilliseconds : 0.0;
        final shown = (_dragValue ?? progress).clamp(0.0, 1.0).toDouble();

        return LayoutBuilder(
          builder: (context, constraints) {
            double fraction(double dx) =>
                (dx / constraints.maxWidth).clamp(0.0, 1.0).toDouble();

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: canSeek
                  ? (d) => _seekToFraction(audio, fraction(d.localPosition.dx))
                  : null,
              onHorizontalDragStart: canSeek
                  ? (d) => setState(() => _dragValue = fraction(d.localPosition.dx))
                  : null,
              onHorizontalDragUpdate: canSeek
                  ? (d) => setState(() => _dragValue = fraction(d.localPosition.dx))
                  : null,
              onHorizontalDragEnd: canSeek ? (_) => _commitDrag(audio) : null,
              onHorizontalDragCancel: () => setState(() => _dragValue = null),
              child: SizedBox(
                height: 10,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(
                    value: shown,
                    minHeight: 3,
                    backgroundColor: Colors.white12,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTime(AudioManager audio) {
    return StreamBuilder<Duration>(
      stream: audio.player.stream.position,
      builder: (context, snapshot) {
        final total = audio.player.state.duration;
        final hasTotal = total.inMilliseconds > 0;
        final position = _dragValue != null && hasTotal
            ? total * _dragValue!
            : (snapshot.data ?? Duration.zero);

        return Text(
          '${_fmt(position)} / ${hasTotal ? _fmt(total) : '--:--'}',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }

  Widget _buildVolumeControl(AudioManager audio) {
    return StreamBuilder<double>(
      stream: audio.player.stream.volume,
      builder: (context, snapshot) {
        final volume = snapshot.data ?? 100.0;
        
        IconData volIcon = Icons.volume_up; 
        if (volume == 0) {
          volIcon = Icons.volume_off;
        } else if (volume < 50) {
          volIcon = Icons.volume_down;
        }

        return PopupMenuButton<double>(
          icon: Icon(volIcon, color: Colors.grey, size: 24),
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          offset: const Offset(0, -120), 
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: SizedBox(
                height: 100,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Slider(
                    value: volume,
                    min: 0.0,
                    max: 100.0,
                    activeColor: Colors.purpleAccent,
                    onChanged: (val) {
                      audio.player.setVolume(val);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = get<AudioManager>();

    return AnimatedBuilder(
      animation: audio,
      builder: (context, child) {
        final song = audio.currentSong;
        final bool canGoBack = audio.index > 0;

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: song == null
              ? const SizedBox(width: double.infinity, height: 0)
              : Material(
                  elevation: 8,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSeekBar(audio),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 7),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.music_note,
                                      color: Colors.purpleAccent, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          song.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          song.artist,
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  constraints: const BoxConstraints(),
                                  icon: Icon(Icons.skip_previous,
                                      size: 26,
                                      color: canGoBack
                                          ? Colors.white
                                          : Colors.white24),
                                  onPressed:
                                      canGoBack ? () => audio.prev() : null,
                                ),
                                StreamBuilder<bool>(
                                  stream: audio.player.stream.playing,
                                  builder: (context, playingSnapshot) {
                                    final isPlaying =
                                        playingSnapshot.data ?? false;
                                    return IconButton(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      constraints: const BoxConstraints(),
                                      icon: Icon(
                                        isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        size: 38,
                                        color: Colors.purpleAccent,
                                      ),
                                      onPressed: () => audio.toggle(),
                                    );
                                  },
                                ),
                                IconButton(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.skip_next,
                                      size: 26, color: Colors.white),
                                  onPressed: () => audio.next(),
                                ),
                              ],
                            ),

                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _buildTime(audio),
                                  const SizedBox(width: 8),
                                  _buildVolumeControl(audio), 
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
