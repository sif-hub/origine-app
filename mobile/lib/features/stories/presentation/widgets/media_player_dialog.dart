// lib/features/stories/presentation/widgets/media_player_dialog.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_theme.dart';

/// Lecteur plein écran (vidéo ou audio) ouvert au toucher d'un média du fil.
class MediaPlayerDialog extends StatefulWidget {
  final String url;
  final bool audioOnly;
  final String? title;

  const MediaPlayerDialog({super.key, required this.url, this.audioOnly = false, this.title});

  static Future<void> show(BuildContext context,
      {required String url, bool audioOnly = false, String? title}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => MediaPlayerDialog(url: url, audioOnly: audioOnly, title: title),
    );
  }

  @override
  State<MediaPlayerDialog> createState() => _MediaPlayerDialogState();
}

class _MediaPlayerDialogState extends State<MediaPlayerDialog> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() => _error = 'Impossible de lire ce média. Réessayez dans un instant.');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 48, 8, 8),
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white)),
                      ),
                    )
                  : !_ready
                      ? const Center(child: CircularProgressIndicator(color: AppColors.or))
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: widget.audioOnly
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 40),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.audiotrack, size: 72, color: AppColors.or),
                                          if (widget.title != null) ...[
                                            const SizedBox(height: 12),
                                            Text(widget.title!, style: const TextStyle(color: Colors.white)),
                                          ],
                                        ],
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: _togglePlay,
                                      child: AspectRatio(
                                        aspectRatio: _controller.value.aspectRatio == 0
                                            ? 16 / 9
                                            : _controller.value.aspectRatio,
                                        child: VideoPlayer(_controller),
                                      ),
                                    ),
                            ),
                            ValueListenableBuilder<VideoPlayerValue>(
                              valueListenable: _controller,
                              builder: (_, v, __) {
                                final total = v.duration.inMilliseconds == 0 ? 1 : v.duration.inMilliseconds;
                                final pos = v.position.inMilliseconds.clamp(0, total).toDouble();
                                return Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(v.isPlaying ? Icons.pause : Icons.play_arrow,
                                          color: Colors.white),
                                      onPressed: _togglePlay,
                                    ),
                                    Text(_fmt(v.position),
                                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    Expanded(
                                      child: Slider(
                                        value: pos,
                                        max: total.toDouble(),
                                        activeColor: AppColors.or,
                                        inactiveColor: Colors.white24,
                                        onChanged: (x) =>
                                            _controller.seekTo(Duration(milliseconds: x.toInt())),
                                      ),
                                    ),
                                    Text(_fmt(v.duration),
                                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePlay() {
    _controller.value.isPlaying ? _controller.pause() : _controller.play();
  }
}
