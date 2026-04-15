class ApiConstants {
  // For Android Emulator, use 10.0.2.2.
  // For iOS Simulator, use localhost.
  // For physical device, use your machine's IP address.
  static const String baseUrl = 'http://localhost:8000/api/v1';

  static const int receiveTimeout = 15000; // 15s
  static const int connectionTimeout = 15000; // 15s
}
