import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/ai_assistant/provider/ai_provider.dart';
import '../theme/app_theme.dart';
import '../core/widgets/premium_pressable.dart';
import 'profile_screen.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<String> _suggestions = [
    'How can I save more?',
    'Analyze my expenses',
    'Show wealth optimization',
    'Recent high spendings',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? textOverride]) {
    final text = textOverride ?? _messageController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    _messageController.clear();
    ref.read(aiProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.messages.length && state.isLoading) {
                      return _buildTypingIndicator(context);
                    }
                    final msg = state.messages[index];
                    return _buildChatBubble(context, msg);
                  },
                ),
                if (state.messages.isEmpty && !state.isLoading)
                  _buildEmptyState(context),
              ],
            ),
          ),
          _buildInputArea(context, state),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final aiState = ref.watch(aiProvider);
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.primaryColor.withOpacity(0.05)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, anim, sec) =>
                          const ProfileScreen(),
                      transitionsBuilder: (context, anim, sec, child) =>
                          FadeTransition(opacity: anim, child: child),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.indigo.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vault Intelligence',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.emerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Secure & Learning',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.emerald,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.history_rounded, color: AppTheme.slate400),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.indigo.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      size: 16,
                      color: AppTheme.indigo,
                    ),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: aiState.language,
                        isDense: true,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.indigo,
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: AppTheme.indigo,
                          size: 16,
                        ),
                        onChanged: (val) {
                          if (val != null)
                            ref.read(aiProvider.notifier).toggleLanguage(val);
                        },
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(
                    aiState.isVoiceEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    size: 16,
                    color: aiState.isVoiceEnabled
                        ? AppTheme.indigo
                        : AppTheme.slate400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Voice',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: aiState.isVoiceEnabled
                          ? AppTheme.indigo
                          : AppTheme.slate400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: aiState.isVoiceEnabled,
                    activeColor: AppTheme.indigo,
                    trackColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? AppTheme.indigo.withOpacity(0.3)
                          : AppTheme.slate200,
                    ),
                    thumbColor: WidgetStateProperty.all(Colors.white),
                    onChanged: (val) =>
                        ref.read(aiProvider.notifier).toggleVoice(val),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context, ChatMessage msg) {
    final theme = Theme.of(context);
    final isAI = !msg.isUser;
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isAI ? theme.cardTheme.color : AppTheme.indigo,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAI ? 4 : 16),
            bottomRight: Radius.circular(isAI ? 16 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (msg.attachmentUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isAI
                      ? theme.primaryColor.withOpacity(0.05)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      msg.attachmentType == 'image'
                          ? Icons.image
                          : Icons.insert_drive_file,
                      size: 16,
                      color: isAI ? theme.primaryColor : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      msg.attachmentType == 'image'
                          ? 'Image Attached'
                          : 'Document Attached',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isAI ? theme.primaryColor : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Text(
              msg.content,
              style: TextStyle(
                color: isAI ? theme.textTheme.bodyLarge?.color : Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (isAI) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () =>
                        ref.read(aiProvider.notifier).speakMessage(msg.content),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 16,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAttachModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.slate400),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(aiProvider.notifier).pickFile('camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: AppTheme.slate400),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(aiProvider.notifier).pickFile('gallery');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file,
                color: AppTheme.slate400,
              ),
              title: const Text("Document"),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(aiProvider.notifier).pickFile('document');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: CircleAvatar(
                radius: 2,
                backgroundColor: AppTheme.indigo.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_graph_rounded,
            size: 48,
            color: AppTheme.indigo.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Ask me anything about your wealth.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.slate400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, AiState state) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.primaryColor.withOpacity(0.05)),
        ),
      ),
      child: Column(
        children: [
          if (state.messages.isEmpty) _buildSuggestions(context),
          const SizedBox(height: 12),
          if (state.pendingAttachmentName != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.pendingAttachmentType == 'image'
                          ? Icons.image
                          : Icons.insert_drive_file,
                      size: 16,
                      color: AppTheme.indigo,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        state.pendingAttachmentName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          ref.read(aiProvider.notifier).removeAttachment(),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.indigo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: () => _showAttachModal(context),
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppTheme.slate400,
                ),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.slate100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.slate200),
                  ),
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Message Vault...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_messageController.text.isEmpty)
                IconButton(
                  onPressed: () =>
                      ref.read(aiProvider.notifier).startListening(),
                  icon: Icon(
                    state.isListening
                        ? Icons.graphic_eq_rounded
                        : Icons.mic_none_rounded,
                    color: state.isListening
                        ? AppTheme.indigo
                        : AppTheme.slate400,
                  ),
                )
              else
                PremiumPressable(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => PremiumPressable(
          onTap: () => _sendMessage(_suggestions[index]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.indigo.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.indigo.withOpacity(0.1)),
            ),
            child: Text(
              _suggestions[index],
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
