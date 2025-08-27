import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

// Abstract interface for connectivity to follow Interface Segregation and Dependency Inversion
abstract class IConnectivityService {
  RxBool get isConnected;
  Future<void> checkConnectivity();
}

// Concrete implementation of connectivity service
class ConnectivityController extends GetxController implements IConnectivityService {
  final _connectivity = Connectivity();
  final _isConnected = false.obs;

  @override
  RxBool get isConnected => _isConnected;

  @override
  void onInit() {
    super.onInit();
    checkConnectivity();
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _isConnected.value = results.any((result) => result != ConnectivityResult.none);
    });
  }

  @override
  Future<void> checkConnectivity() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    _isConnected.value = connectivityResults.any((result) => result != ConnectivityResult.none);
  }
}
