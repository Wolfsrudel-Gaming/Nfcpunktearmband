class AppConstants {
  AppConstants._();

  static const String appName = 'QuestBand';
  static const String apiBaseUrl = 'https://riegel-troisdorf.de/QuestBand';
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration socketReconnectDelay = Duration(seconds: 3);
  static const int maxOfflineQueueSize = 500;
  static const int pinLength = 4;
  static const List<int> quickSelectValues = [1, 2, 5, 10];
}
