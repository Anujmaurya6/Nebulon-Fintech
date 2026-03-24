import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';
import 'api_client.dart';
import '../utils/action_queue.dart';
import 'package:logger/logger.dart';

class SyncService {
  final ApiClient _apiClient;
  final ConnectivityService _connectivity;
  final Logger _logger = Logger();
  bool _isSyncing = false;

  SyncService(this._apiClient, this._connectivity, WidgetRef? ref) {
    // Standard approach to listen to a stream or notifier
    if (ref != null) {
      ref.listen<ConnectivityStatus>(connectivityProvider, (previous, next) {
        if (next == ConnectivityStatus.isConnected) {
          syncPendingActions();
        }
      });
    }
  }

  Future<void> syncPendingActions() async {
    if (_isSyncing || !_connectivity.isConnected || ActionQueue.isEmpty) return;

    _isSyncing = true;
    _logger.i('Starting background sync of pending actions...');

    final actions = ActionQueue.getAll();
    for (final action in actions) {
      try {
        await _processAction(action);
        await ActionQueue.remove(action.id);
        _logger.d('Successfully synced action: ${action.id}');
      } catch (e) {
        _logger.e('Failed to sync action: ${action.id}, error: $e');
        // Stop syncing on first error to preserve order
        break;
      }
    }

    _isSyncing = false;
    _logger.i('Background sync completed.');
  }

  Future<void> _processAction(OfflineAction action) async {
    Map<String, dynamic>? result;
    if (action.method == 'POST') {
      result = await _apiClient.post(action.endpoint, data: action.data);
    } else if (action.method == 'PATCH') {
      result = await _apiClient.patch(action.endpoint, data: action.data);
    } else if (action.method == 'DELETE') {
      result = await _apiClient.delete(action.endpoint);
    }

    if (result != null && result['error'] != null) {
      final error = result['error'].toString().toLowerCase();
      // If the record already exists (Unique violation), we can consider it success and remove from queue
      if (error.contains('duplicate') || error.contains('unique') || error.contains('already exists')) {
        _logger.w('Duplicate record detected for action ${action.id}, marking as synced.');
        return;
      }
      throw Exception(result['error']);
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final apiClient = ApiClient();
  final connectivity = ref.watch(connectivityProvider.notifier);
  final service = SyncService(apiClient, connectivity, null);
  
  // Attach listener within the provider scope
  ref.listen<ConnectivityStatus>(connectivityProvider, (previous, next) {
    if (next == ConnectivityStatus.isConnected) {
      service.syncPendingActions();
    }
  });
  
  return service;
});
