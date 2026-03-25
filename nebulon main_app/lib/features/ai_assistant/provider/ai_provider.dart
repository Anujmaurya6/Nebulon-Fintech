import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/utils/action_queue.dart';
import '../data/ai_data_source.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../transactions/provider/transaction_provider.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? attachmentUrl;
  final String? attachmentType; // 'image', 'document'

  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.attachmentUrl,
    this.attachmentType,
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'is_user': isUser,
    'timestamp': timestamp.toIso8601String(),
    'attachment_url': attachmentUrl,
    'attachment_type': attachmentType,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    content: json['content'],
    isUser: json['is_user'] ?? json['isUser'] ?? false,
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'])
        : DateTime.now(),
    attachmentUrl: json['attachment_url'] ?? json['attachmentUrl'],
    attachmentType: json['attachment_type'] ?? json['attachmentType'],
  );
}

class AiState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isListening;
  final String? errorMessage;
  final String? pendingAttachmentPath;
  final String? pendingAttachmentName;
  final String? pendingAttachmentType; // 'image', 'document'
  final String language; // 'en' or 'hi'
  final bool isVoiceEnabled;

  const AiState({
    this.messages = const [],
    this.isLoading = false,
    this.isListening = false,
    this.errorMessage,
    this.pendingAttachmentPath,
    this.pendingAttachmentName,
    this.pendingAttachmentType,
    this.language = 'en',
    this.isVoiceEnabled = false,
  });

  AiState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isListening,
    String? errorMessage,
    String? pendingAttachmentPath,
    String? pendingAttachmentName,
    String? pendingAttachmentType,
    String? language,
    bool? isVoiceEnabled,
  }) {
    return AiState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isListening: isListening ?? this.isListening,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingAttachmentPath:
          pendingAttachmentPath ?? this.pendingAttachmentPath,
      pendingAttachmentName:
          pendingAttachmentName ?? this.pendingAttachmentName,
      pendingAttachmentType:
          pendingAttachmentType ?? this.pendingAttachmentType,
      language: language ?? this.language,
      isVoiceEnabled: isVoiceEnabled ?? this.isVoiceEnabled,
    );
  }

  AiState clearAttachment() {
    return copyWith(
      pendingAttachmentPath: null,
      pendingAttachmentName: null,
      pendingAttachmentType: null,
    );
  }
}

class AiNotifier extends Notifier<AiState> {
  final AiDataSource _dataSource = AiDataSource();
  static const String _historyBox = 'ai_chat_history';
  final _uuid = const Uuid();
  final FlutterTts _tts = FlutterTts();

  @override
  AiState build() {
    _initPrefs();
    _loadHistory();
    return const AiState(isLoading: true);
  }

  Future<void> _initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language_preference') ?? 'en';
    final voice = prefs.getBool('voice_enabled') ?? false;

    state = state.copyWith(language: lang, isVoiceEnabled: voice);
  }

  Future<void> toggleLanguage(String newLang) async {
    state = state.copyWith(language: newLang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_preference', newLang);
  }

  Future<void> toggleVoice(bool enabled) async {
    state = state.copyWith(isVoiceEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_enabled', enabled);
  }

  Future<void> speakMessage(String text) async {
    await _tts.setLanguage(state.language == 'hi' ? 'hi-IN' : 'en-US');
    await _tts.speak(text);
  }

  Future<void> _loadHistory() async {
    final box = await Hive.openBox(_historyBox);
    final history = box.get('messages');

    // Default initial message
    List<ChatMessage> localMessages = [
      ChatMessage(
        content:
            'Hello! I\'m your AI financial assistant. How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];

    if (history != null && history is String) {
      final List<dynamic> decoded = jsonDecode(history);
      localMessages = decoded.map((e) => ChatMessage.fromJson(e)).toList();
    }

    state = state.copyWith(messages: localMessages, isLoading: false);

    // Fetch from backend to ensure DB trace
    final isConnected =
        ref.read(connectivityProvider) == ConnectivityStatus.isConnected;
    if (isConnected) {
      final result = await _dataSource.fetchHistory();
      if (result['error'] == null && result['data'] != null) {
        final List<dynamic> data = result['data'];
        if (data.isNotEmpty) {
          final backendMessages = data
              .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          state = state.copyWith(messages: backendMessages);
          await _saveHistory();
        } else if (localMessages.length == 1 && !localMessages[0].isUser) {
          // Provide welcome message to DB if it's completely empty
          await _dataSource.saveMessage(localMessages[0].content, false);
        }
      }
    }
  }

  Future<void> _saveHistory() async {
    final box = await Hive.openBox(_historyBox);
    final encoded = jsonEncode(state.messages.map((m) => m.toJson()).toList());
    await box.put('messages', encoded);
  }

  Future<void> _queueOrSaveMessage(String content, bool isUser) async {
    final isConnected =
        ref.read(connectivityProvider) == ConnectivityStatus.isConnected;
    if (isConnected) {
      await _dataSource.saveMessage(content, isUser);
    } else {
      await ActionQueue.enqueue(
        OfflineAction(
          id: _uuid.v4(),
          endpoint: '/rest/v1/ai_history',
          method: 'POST',
          data: {'content': content, 'is_user': isUser},
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }

  Future<void> sendMessage(String message) async {
    final attPath = state.pendingAttachmentPath;
    final attType = state.pendingAttachmentType;

    final userMsg = ChatMessage(
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
      attachmentUrl: attPath,
      attachmentType: attType,
    );

    state = state.clearAttachment().copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );
    await _saveHistory();
    await _queueOrSaveMessage(message, true);

    final isConnected =
        ref.read(connectivityProvider) == ConnectivityStatus.isConnected;

    if (!isConnected) {
      _handleOfflineResponse(message);
      return;
    }

    final txState = ref.read(transactionProvider);
    final income = txState.totalIncome;
    final expense = txState.totalExpenses;
    final topCategory = txState.topCategory;
    final trend = txState.spendingTrend;

    String systemInstruction =
        'You are a helpful financial assistant for the Smart Vault fintech app. '
        'CONTEXT: User income: ₹$income, expense: ₹$expense, top spending category: $topCategory, '
        'spending trend vs last month: $trend. '
        'Give financial advice in simple language based on this context. ';

    if (state.language == 'hi') {
      systemInstruction +=
          'IMPORTANT: You MUST respond entirely in conversational Hindi using Devanagari script (हिंदी).';
    } else {
      systemInstruction += 'Respond in conversational English.';
    }

    final messages = [
      {'role': 'system', 'content': systemInstruction},
      ...state.messages.map(
        (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.content},
      ),
    ];

    final result = await _dataSource.getChatCompletion(messages);

    if (result['error'] != null) {
      _handleOfflineResponse(message, isError: true);
      return;
    }

    final data = result['data'];
    String reply = 'I understand. Let me help you with that.';
    if (data is Map &&
        data['choices'] is List &&
        (data['choices'] as List).isNotEmpty) {
      reply = data['choices'][0]['message']?['content'] ?? reply;
    }

    final aiMsg = ChatMessage(
      content: reply,
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isLoading: false,
    );
    await _saveHistory();
    await _queueOrSaveMessage(reply, false);

    if (state.isVoiceEnabled) {
      speakMessage(reply);
    }
  }

  void _handleOfflineResponse(String userMsg, {bool isError = false}) {
    String reply = '';
    final msg = userMsg.toLowerCase();
    
    final txState = ref.read(transactionProvider);
    final balance = txState.balance.toInt();
    final topCategory = txState.topCategory;

    if (msg.contains('balance')) {
      reply =
          'Your current offline balance is ₹$balance. Transactions are queued for sync.';
    } else if (msg.contains('spending') || msg.contains('expense')) {
      reply =
          'Based on your local data, your highest spending category is "$topCategory".';
    } else if (msg.contains('budget') || msg.contains('income')) {
      reply =
          'Your total recorded income is ₹${txState.totalIncome.toInt()}. Offline constraints prevent detailed budget forecasting right now.';
    } else {
      reply = isError
          ? 'I\'m having trouble reaching the brain center. Your data is perfectly safe locally.'
          : 'I\'m currently offline, but I can still provide insights from your local database. What would you like to know about your balance or spending?';
    }

    final aiMsg = ChatMessage(
      content: reply,
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isLoading: false,
    );
    _saveHistory();
    _queueOrSaveMessage(reply, false);
  }

  Future<void> startListening() async {
    state = state.copyWith(isListening: true);
    HapticFeedback.lightImpact();
    // In production, integrate speech_to_text package here
    await Future.delayed(const Duration(seconds: 3));
    state = state.copyWith(isListening: false);
    HapticFeedback.mediumImpact();
    // Simulate speech detection
    sendMessage('Analyze my recent spending patterns');
  }

  Future<void> pickFile(String source) async {
    try {
      if (source == 'camera') {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          state = state.copyWith(
            pendingAttachmentPath: image.path,
            pendingAttachmentName: image.name,
            pendingAttachmentType: 'image',
          );
        }
      } else if (source == 'gallery') {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
        );
        if (image != null) {
          state = state.copyWith(
            pendingAttachmentPath: image.path,
            pendingAttachmentName: image.name,
            pendingAttachmentType: 'image',
          );
        }
      } else if (source == 'document') {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result != null && result.files.single.path != null) {
          state = state.copyWith(
            pendingAttachmentPath: result.files.single.path,
            pendingAttachmentName: result.files.single.name,
            pendingAttachmentType: 'document',
          );
        }
      }
    } catch (e) {
      // Handle error (e.g., permissions)
    }
  }

  void removeAttachment() {
    state = state.clearAttachment();
  }

  Future<void> clearHistory() async {
    state = state.copyWith(messages: []);
    final box = await Hive.openBox(_historyBox);
    await box.delete('messages');

    // Also clear from DB
    final isConnected =
        ref.read(connectivityProvider) == ConnectivityStatus.isConnected;
    if (isConnected) {
      final ApiClient client = ApiClient();
      await client.delete('/api/database/records/ai_history');
    }
  }
}

final aiProvider = NotifierProvider<AiNotifier, AiState>(AiNotifier.new);
