import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:chingu/core/theme/app_theme.dart';

class VoiceMessageRecorder extends StatefulWidget {
  final Function(String path, int duration) onRecordComplete;
  final VoidCallback onCancel;

  const VoiceMessageRecorder({
    super.key,
    required this.onRecordComplete,
    required this.onCancel,
  });

  @override
  State<VoiceMessageRecorder> createState() => _VoiceMessageRecorderState();
}

class _VoiceMessageRecorderState extends State<VoiceMessageRecorder> with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  late AnimationController _animationController;
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _path;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // Check and request permission
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final fileName = 'voice_message_${const Uuid().v4()}.m4a';
        _path = '${directory.path}/$fileName';

        await _audioRecorder.start(
          const RecordConfig(),
          path: _path!,
        );

        if (mounted) {
          setState(() {
            _isRecording = true;
            _recordDuration = 0;
          });
          _startTimer();
        }
      } else {
        debugPrint('Permission denied');
        if (mounted) widget.onCancel();
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
      if (mounted) widget.onCancel();
    }
  }

  Future<void> _stopAndSend() async {
    try {
      final path = await _audioRecorder.stop();
      _stopTimer();

      if (path != null && mounted) {
        widget.onRecordComplete(path, _recordDuration);
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder.stop();
      _stopTimer();

      if (_path != null) {
        final file = File(_path!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      if (mounted) widget.onCancel();
    } catch (e) {
      debugPrint('Error canceling record: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordDuration++;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Blink red dot
            if (_isRecording)
              FadeTransition(
                opacity: _animationController,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Text(
              _formatDuration(_recordDuration),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            Text(
              '錄音中...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: _cancelRecording,
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: chinguTheme?.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _stopAndSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
