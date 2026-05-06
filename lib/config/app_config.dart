import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.devBypassLogin,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool devBypassLogin;

  bool get isSupabaseConfigured {
    return _normalizeValue(supabaseUrl).isNotEmpty &&
        _normalizeValue(supabaseAnonKey).isNotEmpty &&
        supabaseUrl != 'your_supabase_project_url' &&
        supabaseAnonKey != 'your_supabase_anon_key';
  }

  static Future<AppConfig> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      try {
        await dotenv.load(fileName: '.env.example');
      } catch (_) {
        // Keep placeholder configuration when no dotenv asset is available.
      }
    }

    return AppConfig(
      supabaseUrl: _normalizeValue(
        dotenv.env['SUPABASE_URL'] ?? 'your_supabase_project_url',
      ),
      supabaseAnonKey: _normalizeValue(
        dotenv.env['SUPABASE_ANON_KEY'] ?? 'your_supabase_anon_key',
      ),
      devBypassLogin: _parseBool(
        dotenv.env['APP_DEV_BYPASS_LOGIN'] ?? 'false',
      ),
    );
  }

  static String _normalizeValue(String value) {
    return value.trim();
  }

  static bool _parseBool(String value) {
    return value.trim().toLowerCase() == 'true';
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('AppConfig override is required at bootstrap.');
});
