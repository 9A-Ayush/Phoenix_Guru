import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Connectivity Service
// Monitors network connectivity status
// ─────────────────────────────────────────────────────────────────────────────

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  bool _isConnected = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Stream of connectivity status (true = connected, false = disconnected)
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Update connection status based on connectivity result
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Consider connected if any connection type is available
    final wasConnected = _isConnected;
    _isConnected = results.any((result) => 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );

    // Only emit if status changed
    if (wasConnected != _isConnected) {
      _connectionController.add(_isConnected);
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectionController.close();
  }
}
