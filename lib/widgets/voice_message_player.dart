import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final Duration? totalDuration;
  final Color? color;
  final bool isMe;

  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    this.totalDuration,
    this.color,
    this.isMe = false,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  late AudioPlayer _player;
  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _totalDuration = widget.totalDuration ?? Duration.zero;

    _initPlayerListeners();
  }

  void _initPlayerListeners() {
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
          _isLoading = false;
        });
      }
    });

    _player.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _player.onDurationChanged.listen((duration) {
      if (mounted && duration > Duration.zero) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_playerState == PlayerState.playing) {
        await _player.pause();
      } else {
        setState(() {
          _isLoading = true;
        });
        if (_playerState == PlayerState.completed ||
            _playerState == PlayerState.stopped) {
          await _player.play(UrlSource(widget.audioUrl));
        } else {
          await _player.resume();
        }
      }
    } catch (e) {
      debugPrint('Error playing voice message: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Determine content color based on the provided color or background (isMe)
    // If color is provided, use it.
    // Otherwise, if isMe is true, background is usually primary gradient/color, so text/icon should be onPrimary
    // If isMe is false, background is surfaceVariant, so text/icon should be onSurface
    final contentColor = widget.color ??
        (widget.isMe
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 260),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPlayButton(contentColor, theme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 32,
                  child: WaveformVisualizer(
                    audioUrl: widget.audioUrl,
                    progress: _totalDuration.inMilliseconds > 0
                        ? _currentPosition.inMilliseconds /
                            _totalDuration.inMilliseconds
                        : 0.0,
                    activeColor: contentColor,
                    inactiveColor: contentColor.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _playerState == PlayerState.playing
                      ? _formatDuration(_currentPosition)
                      : _formatDuration(_totalDuration),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: contentColor.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(Color color, ThemeData theme) {
    return InkWell(
      onTap: _togglePlay,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: _isLoading
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(
                _playerState == PlayerState.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: color,
                size: 24,
              ),
      ),
    );
  }
}

class WaveformVisualizer extends StatelessWidget {
  final String audioUrl;
  final double progress; // 0.0 to 1.0
  final Color activeColor;
  final Color inactiveColor;

  const WaveformVisualizer({
    super.key,
    required this.audioUrl,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    // Generate deterministic random heights based on the audioUrl
    // This ensures the waveform looks the same for the same message
    final random = Random(audioUrl.hashCode);
    final barCount = 30; // Number of bars to display

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final barWidth = (width - (barCount - 1) * 2) / barCount;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (index) {
            // Generate height between 30% and 100% of available height
            final heightFactor = 0.3 + (random.nextDouble() * 0.7);

            // Determine if this bar is "active" (played)
            final barProgress = index / barCount;
            final isActive = barProgress < progress;

            return Container(
              width: barWidth > 2 ? barWidth : 2,
              height: constraints.maxHeight * heightFactor,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
