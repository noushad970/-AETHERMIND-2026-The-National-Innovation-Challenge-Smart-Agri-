import 'package:flutter/material.dart';

import '../../data/services/bangla_tts_service.dart';
import '../theme/app_theme.dart';

class TtsReadoutButton extends StatefulWidget {
  const TtsReadoutButton({
    super.key,
    required this.text,
    this.label,
    this.compact = false,
    this.color,
    this.tooltip,
  });

  final String text;
  final String? label;
  final bool compact;
  final Color? color;
  final String? tooltip;

  @override
  State<TtsReadoutButton> createState() => _TtsReadoutButtonState();
}

class _TtsReadoutButtonState extends State<TtsReadoutButton>
    with SingleTickerProviderStateMixin {
  final BanglaTtsService _ttsService = BanglaTtsService();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleSpeak() {
    _ttsService.speak(widget.text);
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? AppTheme.primaryGreen;

    return ValueListenableBuilder<TtsState>(
      valueListenable: _ttsService.stateNotifier,
      builder: (context, state, child) {
        final isSpeaking = _ttsService.isSpeakingText(widget.text);

        if (widget.compact) {
          return IconButton(
            onPressed: widget.text.isEmpty ? null : _toggleSpeak,
            icon: FadeTransition(
              opacity: isSpeaking
                  ? Tween<double>(begin: 0.4, end: 1.0).animate(_animController)
                  : const AlwaysStoppedAnimation(1.0),
              child: Icon(
                isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                color: isSpeaking ? Colors.redAccent : activeColor,
                size: 22,
              ),
            ),
            tooltip: isSpeaking
                ? 'ভয়েস বন্ধ করুন'
                : (widget.tooltip ?? 'ভয়েস শুনুন (Bangla Readout)'),
          );
        }

        return OutlinedButton.icon(
          onPressed: widget.text.isEmpty ? null : _toggleSpeak,
          style: OutlinedButton.styleFrom(
            foregroundColor: isSpeaking ? Colors.redAccent : activeColor,
            side: BorderSide(
              color: isSpeaking ? Colors.redAccent : activeColor,
              width: isSpeaking ? 1.8 : 1.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          icon: FadeTransition(
            opacity: isSpeaking
                ? Tween<double>(begin: 0.3, end: 1.0).animate(_animController)
                : const AlwaysStoppedAnimation(1.0),
            child: Icon(
              isSpeaking ? Icons.stop_circle : Icons.volume_up,
              size: 18,
            ),
          ),
          label: Text(
            isSpeaking
                ? 'ভয়েস বন্ধ করুন'
                : (widget.label ?? 'ভয়েস শুনুন (Read Aloud)'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        );
      },
    );
  }
}
