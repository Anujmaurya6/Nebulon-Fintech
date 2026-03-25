import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/utils/action_queue.dart';
import 'package:uuid/uuid.dart';

class BankAccount {
  final String id;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String holderName;
  final bool isPrimary;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.holderName,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'bank_name': bankName,
    'account_number': accountNumber,
    'ifsc_code': ifscCode,
    'holder_name': holderName,
    'is_primary': isPrimary,
  };

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
    id: json['id'],
    bankName: json['bank_name'],
    accountNumber: json['account_number'],
    ifscCode: json['ifsc_code'],
    holderName: json['holder_name'],
    isPrimary: json['is_primary'] ?? false,
  );
}

class BankState {
  final List<BankAccount> accounts;
  final bool isLoading;
  final String? errorMessage;

  BankState({
    this.accounts = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  BankState copyWith({
    List<BankAccount>? accounts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BankState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class BankNotifier extends Notifier<BankState> {
  final _uuid = const Uuid();
  final ApiClient _client = ApiClient();

  @override
  BankState build() {
    Future.microtask(() => fetchAccounts());
    return BankState(isLoading: true);
  }

  Future<void> fetchAccounts() async {
    state = state.copyWith(isLoading: true);
    final isConnected =
        ref.read(connectivityProvider) == ConnectivityStatus.isConnected;

    if (!isConnected) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Offline. Show cached data.',
      );
      return;
    }

    try {
      final response = await _client.get('/rest/v1/bank_accounts?select=*');
      if (response['error'] != null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response['error'].toString(),
        );
        return;
      }
      final List<dynamic> data = (response['data'] as List?) ?? [];
      final accounts = data
          .map((e) => BankAccount.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(accounts: accounts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addAccount(BankAccount account) async {
    state = state.copyWith(accounts: [...state.accounts, account]);

    final isConnected =
        ref.read(connectivityProvider) == ConnectivityStatus.isConnected;
    if (isConnected) {
      try {
        await _client.post('/rest/v1/bank_accounts', data: account.toJson());
      } catch (e) {
        // Fallback to queue if request fails
        _queueAction('POST', account.toJson());
      }
    } else {
      _queueAction('POST', account.toJson());
    }
  }

  Future<void> deleteAccount(String id) async {
    state = state.copyWith(
      accounts: state.accounts.where((a) => a.id != id).toList(),
    );

    final isConnected =
        ref.read(connectivityProvider) == ConnectivityStatus.isConnected;
    if (isConnected) {
      try {
        await _client.delete('/rest/v1/bank_accounts?id=eq.$id');
      } catch (e) {
        _queueAction('DELETE', {'id': id});
      }
    } else {
      _queueAction('DELETE', {'id': id});
    }
  }

  void _queueAction(String method, Map<String, dynamic> data) {
    ActionQueue.enqueue(
      OfflineAction(
        id: _uuid.v4(),
        endpoint: '/rest/v1/bank_accounts',
        method: method,
        data: data,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

final bankProvider = NotifierProvider<BankNotifier, BankState>(
  BankNotifier.new,
);
