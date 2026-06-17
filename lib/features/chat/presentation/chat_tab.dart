import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'chat_bloc.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab>
    with AutomaticKeepAliveClientMixin {
  final _controller = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(ChatMessageSent(text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<ChatBloc, ChatState>(
      listenWhen: (prev, curr) =>
          curr.error != null && prev.error != curr.error,
      listener: (context, state) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.error!))),
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _ExamModeBar(state: state),
            Expanded(child: _MessagesList(state: state)),
            _InputBar(
              controller: _controller,
              enabled: !state.isStreaming,
              examMode: state.examMode,
              onSend: _send,
            ),
          ],
        );
      },
    );
  }
}

class _ExamModeBar extends StatelessWidget {
  const _ExamModeBar({required this.state});

  final ChatState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: SwitchListTile(
              dense: true,
              secondary: const Icon(Icons.school_outlined),
              title: const Text('Tryb odpytywania'),
              subtitle: const Text('AI zadaje pytania i ocenia odpowiedzi'),
              value: state.examMode,
              onChanged: state.isStreaming
                  ? null
                  : (value) => context
                      .read<ChatBloc>()
                      .add(ChatExamModeToggled(value)),
            ),
          ),
          IconButton(
            tooltip: 'Wyczyść historię czatu',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: state.isStreaming || state.messages.isEmpty
                ? null
                : () => _confirmClear(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final bloc = context.read<ChatBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wyczyścić historię czatu?'),
        content: const Text('Wszystkie wiadomości tego przedmiotu znikną.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Wyczyść'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(const ChatHistoryCleared());
    }
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList({required this.state});

  final ChatState state;

  @override
  Widget build(BuildContext context) {
    final bubbles = <Widget>[
      for (final message in state.messages)
        _MessageBubble(isUser: message.isUser, text: message.text),
      if (state.isStreaming)
        _MessageBubble(
          isUser: false,
          text: state.streamingText.isEmpty
              ? 'AI pisze…'
              : '${state.streamingText} ▌',
        ),
    ];

    if (bubbles.isEmpty) {
      final scheme = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 44, color: scheme.outline),
              const SizedBox(height: 12),
              Text(
                'Zadaj pytanie dotyczące materiałów\n'
                'albo włącz tryb odpytywania.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.outline),
              ),
            ],
          ),
        ),
      );
    }

    // reverse: true — lista jest „przyklejona” do dołu, więc strumieniowa
    // odpowiedź sama przewija się w polu widzenia.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      itemCount: bubbles.length,
      itemBuilder: (context, index) => bubbles[bubbles.length - 1 - index],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.isUser, required this.text});

  final bool isUser;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: SelectableText(
          text,
          style: TextStyle(
            color: isUser ? scheme.onPrimary : scheme.onSurface,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.examMode,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool examMode;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      examMode ? 'Twoja odpowiedź…' : 'Zapytaj o materiał…',
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Wyślij',
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }
}
