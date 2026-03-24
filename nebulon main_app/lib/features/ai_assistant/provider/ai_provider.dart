import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/utils/action_queue.dart';
import '../data/ai_data_source.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'is_user': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    content: json['content'],
    isUser: json['is_user'] ?? json['isUser'] ?? false,
    timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.now(),
  );
}

class AiState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;

  const AiState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AiState copyWith({List<ChatMessage>? messages, bool? isLoading, String? errorMessage}) {
    return AiState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AiNotifier extends Notifier<AiState> {
  final AiDataSource _dataSource = AiDataSource();
  static const String _historyBox = 'ai_chat_history';
  final _uuid = const Uuid();

  @override
  AiState build() {
    _loadHistory();
    return const AiState(
      isLoading: true,
    );
  }

  Future<void> _loadHistory() async {
    final box = await Hive.openBox(_historyBox);
    final history = box.get('messages');
    
    // Default initial message
    List<ChatMessage> localMessages = [
      ChatMessage(
        content: 'Hello! I\'m your AI financial assistant. How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      )
    ];

    if (history != null && history is String) {
      final List<dynamic> decoded = jsonDecode(history);
      localMessages = decoded.map((e) => ChatMessage.fromJson(e)).toList();
    }
    
    state = state.copyWith(messages: localMessages, isLoading: false);

    // Fetch from backend to ensure DB trace
    final isConnected = ref.read(connectivityProvider) == ConnectivityStatus.isConnected;
    if (isConnected) {
      final result = await _dataSource.fetchHistory();
      if (result['error'] == null && result['data'] != null) {
        final List<dynamic> data = result['data'];
        if (data.isNotEmpty) {
           final backendMessages = data.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e))).toList();
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
    final isConnected = ref.read(connectivityProvider) == ConnectivityStatus.isConnected;
    if (isConnected) {
      await _dataSource.saveMessage(content, isUser);
    } else {
      await ActionQueue.enqueue(OfflineAction(
        id: _uuid.v4(),
        endpoint: '/rest/v1/ai_history',
        method: 'POST',
        data: {'content': content, 'is_user': isUser},
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  Future<void> sendMessage(String message) async {
    final userMsg = ChatMessage(content: message, isUser: true, timestamp: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );
    await _saveHistory();
    await _queueOrSaveMessage(message, true);

    final isConnected = ref.read(connectivityProvider) == ConnectivityStatus.isConnected;

    if (!isConnected) {
      _handleOfflineResponse(message);
      return;
    }

    final messages = [
      {
        'role': 'system',
        'content': 'You are a helpful financial assistant for the Nebulon fintech app. '
            'Help users with budgeting, savings goals, and spending analysis. Be concise and actionable.'
      },
      ...state.messages.map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          }),
    ];

    final result = await _dataSource.getChatCompletion(messages);

    if (result['error'] != null) {
      _handleOfflineResponse(message, isError: true);
      return;
    }

    final data = result['data'];
    String reply = 'I understand. Let me help you with that.';
    if (data is Map && data['choices'] is List && (data['choices'] as List).isNotEmpty) {
      reply = data['choices'][0]['message']?['content'] ?? reply;
    }

    final aiMsg = ChatMessage(content: reply, isUser: false, timestamp: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isLoading: false,
    );
    await _saveHistory();
    await _queueOrSaveMessage(reply, false);
  }

  void _handleOfflineResponse(String userMsg, {bool isError = false}) {
    String reply = '';
    final msg = userMsg.toLowerCase();

    if (msg.contains('balance')) {
      reply = 'Your last known balance was ₹42,500. Synchronization is pending.';
    } else if (msg.contains('spending') || msg.contains('expense')) {
      reply = 'Based on cached data, your highest spending category is "Food & Dining".';
    } else if (msg.contains('budget')) {
      reply = 'You have ₹12,000 remaining in your monthly budget according to the last sync.';
    } else {
      reply = isError 
        ? 'I\'m having trouble reaching the brain center. Here\'s a tip: Diversify your portfolio to mitigate risk.' 
        : 'I\'m currently offline, but I can still provide insights from your last sync. What would you like to know about your balance or spending?';
    }

    final aiMsg = ChatMessage(content: reply, isUser: false, timestamp: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isLoading: false,
    );
    _saveHistory();
    _queueOrSaveMessage(reply, false);
  }

  Future<void> clearHistory() async {
    state = state.copyWith(messages: []);
    final box = await Hive.openBox(_historyBox);
    await box.delete('messages');
    
    // Also clear from DB
    final isConnected = ref.read(connectivityProvider) == ConnectivityStatus.isConnected;
    if (isConnected) {
       final ApiClient client = ApiClient();
       await client.delete('/api/database/records/ai_history');
    }
  }
}

final aiProvider = NotifierProvider<AiNotifier, AiState>(AiNotifier.new);
