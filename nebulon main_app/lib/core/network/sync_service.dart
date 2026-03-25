import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';
import 'api_client.dart';
import '../utils/local_db_manager.dart';
import '../services/notification_service.dart';
import 'package:logger/logger.dart';

class SyncService {
  final ApiClient _apiClient;
  final ConnectivityService _connectivity;
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  bool _isSyncing = false;

  SyncService(this._apiClient, this._connectivity);

  Future<void> syncPendingActions() async {
    if (_isSyncing || !_connectivity.isConnected) return;

    final pending = LocalDBManager.getPendingTransactions();
    if (pending.isEmpty) return;

    _isSyncing = true;
    _logger.i('Starting background sync of ${pending.length} pending transactions...');
    
    NotificationService.showNotification(
      id: 9991, 
      title: 'Syncing Data', 
      body: '🔄 Syncing ${pending.length} offline transactions to the cloud...',
    );

    int successCount = 0;
    for (final tx in pending) {
      try {
        final result = await _apiClient.post(
          '/rest/v1/transactions',
          data: tx.toJson(),
        );

        if (result != null && result['error'] != null) {
          final error = result['error'].toString().toLowerCase();
          if (error.contains('duplicate') ||
              error.contains('unique') ||
              error.contains('already exists')) {
            _logger.w('Duplicate record detected for ${tx.id}, marking as synced.');
            await LocalDBManager.markAsSynced(tx.id!);
            successCount++;
          } else {
            _logger.e('Failed to sync ${tx.id}: $error');
            break; // Stop on first real error to preserve order
          }
        } else {
          await LocalDBManager.markAsSynced(tx.id!);
          successCount++;
          _logger.d('Successfully synced action: ${tx.id}');
        }
      } catch (e) {
        _logger.e('Exception syncing action: ${tx.id}, error: $e');
        break;
      }
    }

    _isSyncing = false;
    _logger.i('Background sync completed. Synced $successCount items.');
    
    if (successCount > 0) {
      NotificationService.showNotification(
        id: 9992, 
        title: 'Sync Complete', 
        body: '✅ $successCount transaction(s) securely synced to the cloud.',
      );
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final apiClient = ApiClient();
  final connectivity = ref.watch(connectivityProvider.notifier);
  final service = SyncService(apiClient, connectivity);

  // Auto-sync when connectivity is restored
  ref.listen<ConnectivityStatus>(connectivityProvider, (previous, next) {
    if (next == ConnectivityStatus.isConnected) {
      service.syncPendingActions();
    }
  });

  return service;
});
