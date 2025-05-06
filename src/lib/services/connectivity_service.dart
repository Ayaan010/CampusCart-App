import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService {
  final _connectivity = Connectivity();
  final _internetChecker = InternetConnectionChecker();
  final _connectivityController = StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;

  ConnectivityService() {
    _initConnectivity();
  }

  void _initConnectivity() {
    _connectivity.onConnectivityChanged.listen((result) async {
      final hasInternet = await checkConnection();
      _connectivityController.add(hasInternet);
    });
  }

  Future<bool> checkConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    return await _internetChecker.hasConnection;
  }

  void dispose() {
    _connectivityController.close();
  }
}
