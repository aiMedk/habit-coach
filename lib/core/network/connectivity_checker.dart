import 'package:connectivity_plus/connectivity_plus.dart';

/// T007: Connectivity checker utility.
/// Provides a simple interface for checking network availability.
/// Scoped in the domain-adjacent core — no Flutter framework imports.
abstract interface class ConnectivityChecker {
  /// Returns true if the device currently has network access.
  Future<bool> hasConnection();

  /// Stream of connectivity changes: emits true when online, false when offline.
  Stream<bool> get onConnectivityChanged;
}

final class ConnectivityPlusChecker implements ConnectivityChecker {
  ConnectivityPlusChecker(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_isConnected);

  static bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
