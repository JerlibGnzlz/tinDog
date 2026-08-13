import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _hasNetwork(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  return results.any((r) => r != ConnectivityResult.none);
}

/// `true` si hay interfaz de red (wifi/datos). No garantiza internet real.
final networkOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _hasNetwork(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_hasNetwork);
});
