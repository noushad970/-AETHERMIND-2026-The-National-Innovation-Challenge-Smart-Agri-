import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/models/chat_message.dart';

import '../providers/chatbot_provider.dart';

/// Modern chat UI for the agricultural assistant "Krishi Sahayak (Agri AI)".
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  bool _loadingOlder = false;
  int _lastMessageCount = 0;
  bool _lastIsLoading = false;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _focus.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatbotProvider>().loadHistory();
      _scrollToBottom(jump: true, delayMs: 80);
      _scrollToBottom(jump: false, delayMs: 250);
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _focus.removeListener(_onFocusChange);
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focus.hasFocus) {
      _scrollToBottom(jump: false, delayMs: 100);
      _scrollToBottom(jump: false, delayMs: 280);
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final current = _scroll.offset;
    final isAway = (max - current) > 160;
    if (isAway != _showScrollToBottom) {
      setState(() => _showScrollToBottom = isAway);
    }
  }

  void _scrollToBottom({bool jump = false, int delayMs = 0}) {
    void execute() {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(max);
      } else {
        _scroll.animateTo(
          max,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }

    if (delayMs > 0) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) => execute());
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => execute());
    }
  }

  Future<void> _maybeLoadOlder(ChatbotProvider prov) async {
    if (_loadingOlder) return;
    if (!prov.hasMoreOlder) return;
    if (prov.isLoadingOlder) return;
    if (!_scroll.hasClients) return;

    final scrollOffset = _scroll.offset;
    if (scrollOffset > 80) return;

    _loadingOlder = true;
    final maxBefore = _scroll.position.maxScrollExtent;
    try {
      await prov.loadOlder(pageSize: 20);
    } finally {
      _loadingOlder = false;
    }
    if (!_scroll.hasClients) return;
    final maxAfter = _scroll.position.maxScrollExtent;
    final delta = maxAfter - maxBefore;
    if (delta > 0) {
      _scroll.jumpTo(scrollOffset + delta);
    }
  }

  Future<void> _send([String? override]) async {
    final text = (override ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    final prov = context.read<ChatbotProvider>();

    HapticFeedback.selectionClick();
    _scrollToBottom(delayMs: 40);

    try {
      await prov.send(text);
      _scrollToBottom(delayMs: 60);
      _scrollToBottom(delayMs: 200);
      _focus.requestFocus();
    } catch (_) {
      _scrollToBottom(delayMs: 60);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: _ChatHeader(
          onClear: () async {
            final provider = context.read<ChatbotProvider>();
            final messenger = ScaffoldMessenger.of(context);
            final clearedMsg = context.tr("Chat cleared", "চ্যাট মুছে ফেলা হয়েছে");
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(context.tr("Clear chat?", "চ্যাট পরিষ্কার করবেন?")),
                content: Text(
                  context.tr(
                    "All messages in this chat will be removed.",
                    "এই চ্যাটের সমস্ত বার্তা মুছে ফেলা হবে।",
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.tr("Cancel", "বাতিল")),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.tr("Clear", "মুছুন")),
                  ),
                ],
              ),
            );
            if (ok != true) return;
            await provider.clear();
            messenger.showSnackBar(
              SnackBar(
                content: Text(clearedMsg),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Consumer<ChatbotProvider>(
                    builder: (context, prov, _) {
                      final list = prov.messages;

                      // Automatically scroll to bottom when new messages arrive or loading status changes
                      if (list.length != _lastMessageCount || prov.isLoading != _lastIsLoading) {
                        final isFirstLoad = _lastMessageCount == 0 && list.isNotEmpty;
                        _lastMessageCount = list.length;
                        _lastIsLoading = prov.isLoading;
                        _scrollToBottom(jump: isFirstLoad, delayMs: 40);
                        _scrollToBottom(jump: false, delayMs: 160);
                      }

                      if (list.isEmpty && prov.isLoading) {
                        return const Center(child: _TypingDots());
                      }
                      if (list.isEmpty) {
                        return _EmptyState(
                          onPick: (s) {
                            _ctrl.text = s;
                            _ctrl.selection = TextSelection.collapsed(
                              offset: s.length,
                            );
                          },
                        );
                      }
                      final showTyping =
                          prov.isLoading &&
                          (list.isEmpty ||
                              list.last.role != 'assistant' ||
                              !list.last.isUser);
                      final showLoadingOlder =
                          prov.isLoadingOlder || prov.hasMoreOlder;
                      final entries = _buildEntries(context, list, prov);
                      final total =
                          entries.length +
                          (showTyping ? 1 : 0) +
                          (showLoadingOlder ? 1 : 0);
                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollUpdateNotification ||
                              notification is ScrollStartNotification) {
                            _maybeLoadOlder(prov);
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: _scroll,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          itemCount: total,
                          itemBuilder: (context, i) {
                            if (showLoadingOlder && i == 0) {
                              return _OlderMessagesLoader(
                                isLoading: prov.isLoadingOlder,
                                hasMore: prov.hasMoreOlder,
                                totalStored: prov.totalStoredCount,
                                visibleCount: list.length,
                                onTap: prov.hasMoreOlder && !prov.isLoadingOlder
                                    ? () => _maybeLoadOlder(prov)
                                    : null,
                              );
                            }
                            final shift = showLoadingOlder ? 1 : 0;
                            final idx = i - shift;
                            if (showTyping && idx == entries.length) {
                              return const _TypingDots();
                            }
                            return entries[idx];
                          },
                        ),
                      );
                    },
                  ),
                  if (_showScrollToBottom)
                    Positioned(
                      right: 16,
                      bottom: 14,
                      child: AnimatedScale(
                        scale: _showScrollToBottom ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Material(
                          elevation: 6,
                          shape: const CircleBorder(),
                          color: AppTheme.primaryGreen,
                          shadowColor: Colors.black38,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _scrollToBottom(jump: false),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.arrow_downward_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const _QuickReplies(),
            _ErrorBanner(),
            _Composer(
              controller: _ctrl,
              focusNode: _focus,
              onSubmit: () => _send(),
              onChip: (s) => _send(s),
              loading: context.watch<ChatbotProvider>().isLoading,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEntries(BuildContext context, List<ChatMessage> list, ChatbotProvider prov) {
    final out = <Widget>[];
    String? currentDay;
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      final day = _dayLabel(context, m.timestamp);
      if (day != currentDay) {
        out.add(_DayDivider(label: day));
        currentDay = day;
      }
      out.add(_MessageBubble(message: m));
    }
    return out;
  }

  String _dayLabel(BuildContext context, DateTime ts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(ts.year, ts.month, ts.day);
    if (msgDay == today) return context.tr('Today', 'আজ');
    if (msgDay == today.subtract(const Duration(days: 1))) {
      return context.tr('Yesterday', 'গতকাল');
    }
    return '${ts.day.toString().padLeft(2, '0')}-${ts.month.toString().padLeft(2, '0')}-${ts.year}';
  }
}

// ------------------ HEADER ------------------

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      padding: EdgeInsets.only(
        top: media.padding.top + 6,
        left: 14,
        right: 14,
        bottom: 10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreenDark,
            AppTheme.primaryGreen,
            AppTheme.primaryGreenLight,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x2A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar (assistant)
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Image.asset(
                'assets/app_logo.png',
                width: 26,
                height: 26,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.agriculture,
                  color: AppTheme.primaryGreen,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Krishi Sahayak (Agri AI)', 'কৃষি সহায়ক (এগ্রি এআই)'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Consumer<ChatbotProvider>(
                  builder: (context, prov, _) {
                    final isReady = prov.isApiConfigured;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isReady
                                ? Colors.greenAccent
                                : Colors.amberAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isReady
                                ? context.tr('AI Assistant • Online', 'এআই সহকারী • অনলাইন')
                                : context.tr('API key not configured', 'এপিআই কী সংযুক্ত নেই'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const HeaderActionBar(compact: true),
          IconButton(
            tooltip: context.tr('Clear chat', 'চ্যাট মুছুন'),
            icon: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

// ------------------ MESSAGE BUBBLE ------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = !isUser && message.content.contains('ত্রুটি');
    final maxWidth = MediaQuery.of(context).size.width;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth * 0.78),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryGreen, Color(0xFF388E3C)],
              )
            : isError
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF1F8E9)],
              ),
        color: isError ? const Color(0xFFFFEBEE) : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border: isUser || isError
            ? null
            : Border.all(color: AppTheme.divider, width: 0.6),
        boxShadow: [
          if (!isError)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: SelectableText(
        message.content,
        style: TextStyle(
          color: isUser
              ? Colors.white
              : isError
              ? AppTheme.danger
              : AppTheme.textPrimary,
          fontSize: 14.5,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? AppTheme.skyBlue : AppTheme.primaryGreenLight,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: Colors.white,
        size: 16,
      ),
    );

    final time = Text(
      _formatTime(message.timestamp),
      style: TextStyle(
        fontSize: 10,
        color: AppTheme.textSecondary.withValues(alpha: 0.75),
      ),
    );

    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) avatar,
            if (!isUser) const SizedBox(width: 8),
            Flexible(child: bubble),
            if (isUser) const SizedBox(width: 8),
            if (isUser) avatar,
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: EdgeInsets.only(
            left: isUser ? 0 : 40,
            right: isUser ? 40 : 0,
          ),
          child: time,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _formatTime(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

// ------------------ TYPING DOTS ------------------

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _dot(int index) {
    final delay = index * 0.18;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = (_c.value - delay).clamp(0.0, 1.0);
        final scale = 1.0 - (0.6 * (1 - (1 - (2 * t - 1).abs())));
        return Transform.scale(
          scale: 0.6 + 0.4 * scale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(
                alpha: 0.55 + 0.45 * scale,
              ),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryGreenLight,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.divider, width: 0.6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [_dot(0), _dot(1), _dot(2)],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ DATE DIVIDER ------------------

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: AppTheme.divider, thickness: 0.5),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider, width: 0.5),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: AppTheme.divider, thickness: 0.5),
          ),
        ],
      ),
    );
  }
}

// ------------------ QUICK REPLIES ------------------

class _QuickReplies extends StatelessWidget {
  const _QuickReplies();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ChatbotProvider>();
    if (p.messages.isNotEmpty || p.isLoading) return const SizedBox.shrink();
    final replies = context.isBn ? _allBn : _allEn;
    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: replies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = replies[i];
          return ActionChip(
            onPressed: () {
              _Composer.requestSuggestion(s);
            },
            backgroundColor: AppTheme.primaryGreenLight.withValues(alpha: 0.15),
            side: BorderSide(
              color: AppTheme.primaryGreenLight.withValues(alpha: 0.3),
            ),
            label: Text(s, style: const TextStyle(fontSize: 12.5)),
            avatar: const Icon(
              Icons.chat_bubble_outline,
              size: 14,
              color: AppTheme.primaryGreen,
            ),
          );
        },
      ),
    );
  }

  static const _allEn = <String>[
    'Best fertilizer for rice?',
    'Tomato leaf curl disease?',
    'Aman rice seedling care',
    'Vegetable pest control tips',
    'How to test soil pH?',
  ];

  static const _allBn = <String>[
    'ধান চাষে কোন সার সেরা?',
    'টমেটোর পাতা কোঁকড়ানো রোগ?',
    'আমন ধানের চারার যত্ন',
    'সবজির পোকা দমন টিপস',
    'মাটির পিএইচ পরীক্ষা কীভাবে?',
  ];
}

// ------------------ ERROR BANNER ------------------

class _ErrorBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final err = context.watch<ChatbotProvider>().error;
    if (err == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        border: Border(
          top: BorderSide(color: AppTheme.danger.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppTheme.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              err,
              style: const TextStyle(
                color: AppTheme.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.danger,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () async {
              final prov = context.read<ChatbotProvider>();
              final last = prov.messages.lastWhere(
                (m) => m.role == 'user',
                orElse: () => ChatMessage(
                  id: '',
                  threadId: '',
                  content: '',
                  role: '',
                  timestamp: DateTime.now(),
                ),
              );
              if (last.role == 'user') {
                await prov.send(last.content);
              }
            },
            child: Text(
              context.tr('Retry', 'পুনরায় চেষ্টা'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ COMPOSER ------------------

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onChip,
    required this.loading,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final ValueChanged<String> onChip;
  final bool loading;

  static final ValueNotifier<String?> _chipRequest = ValueNotifier<String?>(
    null,
  );

  static void requestSuggestion(String s) => _chipRequest.value = s;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  late final ValueNotifier<String?> _chipListenable;

  @override
  void initState() {
    super.initState();
    _chipListenable = _Composer._chipRequest;
    _chipListenable.addListener(_handleChip);
  }

  @override
  void dispose() {
    _chipListenable.removeListener(_handleChip);
    super.dispose();
  }

  void _handleChip() {
    final s = _chipListenable.value;
    if (s != null) {
      _chipListenable.value = null;
      widget.controller.text = s;
      widget.controller.selection = TextSelection.collapsed(offset: s.length);
      widget.onChip(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  enabled: !widget.loading,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => widget.onSubmit(),
                  onTap: () {},
                  decoration: InputDecoration(
                    hintText: context.tr(
                      AppStrings.typeMessage,
                      AppStrings.typeMessageBn,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: widget.loading
                      ? AppTheme.primaryGreenLight
                      : AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: context.tr(AppStrings.send, AppStrings.sendBn),
                  onPressed: widget.loading ? null : widget.onSubmit,
                  icon: widget.loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ EMPTY STATE ------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final suggestions = context.isBn
        ? [
            const _Suggestion(
              Icons.water_drop,
              'ধান চাষে উপযুক্ত সার কোনটি?',
              'আমন বা বোরো ধানের জন্য এনপিকে সার ব্যবহারের নিয়ম জানুন।',
            ),
            const _Suggestion(
              Icons.bug_report,
              'সবজির পোকা ও রোগ দমন',
              'টমেটো, বেগুন ও শাকসবজির পোকা দমনের সেরা জৈব কৌশল।',
            ),
            const _Suggestion(
              Icons.science,
              'মাটির স্বাস্থ্য ও পিএইচ পরীক্ষা',
              'সহজ উপায়ে মাটির অম্লতা ও ক্ষারত্ব মাপার নির্দেশিকা।',
            ),
            const _Suggestion(
              Icons.eco,
              'জৈব বা কম্পোস্ট সার তৈরি',
              'ভার্মিকম্পোস্ট ও জৈব সার তৈরির ঘরোয়া পদ্ধতি।',
            ),
          ]
        : [
            const _Suggestion(
              Icons.water_drop,
              'Best fertilizer for rice?',
              'Get NPK recommendations for Aman or Boro paddies.',
            ),
            const _Suggestion(
              Icons.bug_report,
              'Pest control for vegetables',
              'Identify and treat common vegetable pests.',
            ),
            const _Suggestion(
              Icons.science,
              'How to test soil pH?',
              'Step-by-step instructions for at-home soil testing.',
            ),
            const _Suggestion(
              Icons.eco,
              'Organic fertilizer recipes',
              'Compost, vermicompost, and biofertilizer options.',
            ),
          ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGreenLight.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.support_agent,
              size: 56,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreenLight.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              context.tr(
                '👋 Assalamu Alaikum / Hello!',
                '👋 আসসালামু আলাইকুম / শুভ দিন!',
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            context.tr('Ask Krishi Sahayak AI', 'কৃষি সহায়ককে প্রশ্ন করুন'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            context.tr(
              'How can I help with your crops, livestock, soil, or weather today?',
              'আজ আপনার ফসল, গবাদিপশু, সার বা রোগবালাই সংক্রান্ত কীভাবে সাহায্য করতে পারি?',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
          ),
        ),
        const SizedBox(height: 24),
        ...suggestions.map(
          (s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: AppTheme.divider.withValues(alpha: 0.6),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onPick(s.title),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreenLight.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(s.icon, color: AppTheme.primaryGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.subtitle,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Suggestion {
  const _Suggestion(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
}

class _OlderMessagesLoader extends StatelessWidget {
  const _OlderMessagesLoader({
    required this.isLoading,
    required this.hasMore,
    required this.totalStored,
    required this.visibleCount,
    required this.onTap,
  });

  final bool isLoading;
  final bool hasMore;
  final int totalStored;
  final int visibleCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hidden = totalStored - visibleCount;
    final Color bg;
    final Color fg;
    final Widget child;
    if (isLoading) {
      bg = const Color(0xFFE3F2FD);
      fg = const Color(0xFF1565C0);
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(context.tr('Loading older messages...', 'পূর্ববর্তী বার্তা লোড হচ্ছে...')),
        ],
      );
    } else if (hasMore) {
      bg = const Color(0xFFFFF7E0);
      fg = const Color(0xFFB26500);
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, size: 16, color: Color(0xFFB26500)),
          const SizedBox(width: 8),
          Text(
            hidden > 0
                ? context.tr(
                    '$hidden older messages above — scroll up to load',
                    'উপরে আরও $hiddenটি বার্তা রয়েছে — স্ক্রল করুন',
                  )
                : context.tr(
                    'Scroll up to load older messages',
                    'পূর্বের বার্তা লোড করতে স্ক্রল করুন',
                  ),
          ),
        ],
      );
    } else {
      bg = const Color(0xFFEEEEEE);
      fg = const Color(0xFF616161);
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF616161)),
          const SizedBox(width: 8),
          Text(context.tr('Start of conversation history', 'কথোপকথনের শুরুর অংশ')),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: fg.withValues(alpha: 0.35)),
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                color: fg,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
