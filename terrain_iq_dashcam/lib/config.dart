/// Server configuration
class AppConfig {
  // Toggle between local and remote
  static const bool useNgrok = false;
  
  static const String localUrl = 'http://192.168.8.105:3000';
  static const String ngrokUrl = 'https://YOUR-NGROK-URL.ngrok-free.app';
  
  static String get serverUrl => useNgrok ? ngrokUrl : localUrl;
}
