import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        supabaseUrl != 'your_supabase_project_url' &&
        supabaseAnonKey != 'your_supabase_anon_key';
  }

  static Future<AppConfig> load() async {
    try {
      await dotenv.load(fileName: '.env.example');
    } catch (_) {
      // Keep placeholder configuration when the asset is not yet bundled.
    }

    return AppConfig(
      supabaseUrl: dotenv.env['SUPABASE_URL'] ?? 'your_supabase_project_url',
      supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'your_supabase_anon_key',
    );
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('AppConfig override is required at bootstrap.');
});
