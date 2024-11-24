import 'package:logging/logging.dart';

class AppLogger {
  static final Logger _logger = Logger('AdbTools');
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.time}: ${record.level.name}: ${record.message}');
      if (record.error != null) {
        // ignore: avoid_print
        print('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        // ignore: avoid_print
        print('Stack trace:\n${record.stackTrace}');
      }
    });
    
    _initialized = true;
  }

  static void finest(String message) => _logger.finest(message);
  static void finer(String message) => _logger.finer(message);
  static void fine(String message) => _logger.fine(message);
  static void info(String message) => _logger.info(message);
  static void warning(String message) => _logger.warning(message);
  static void severe(String message) => _logger.severe(message);
  static void shout(String message) => _logger.shout(message);
} 