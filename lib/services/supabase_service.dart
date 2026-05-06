import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class FarmSummary {
  const FarmSummary({
    required this.id,
    required this.name,
    required this.farmCode,
    required this.accessMode,
    required this.canRead,
    required this.canWrite,
  });

  final String id;
  final String name;
  final String farmCode;
  final String accessMode;
  final bool canRead;
  final bool canWrite;
}

class CowPreview {
  const CowPreview({
    required this.id,
    required this.identifier,
    required this.displayIdentifier,
  });

  final String id;
  final String identifier;
  final String displayIdentifier;
}

class SupabaseService {
  SupabaseService(this._config);

  final AppConfig _config;
  static const Duration _requestTimeout = Duration(seconds: 10);
  bool _initialized = false;

  bool get isConfigured => _config.isSupabaseConfigured;

  SupabaseClient? get _client {
    if (!_initialized || !_config.isSupabaseConfigured) {
      return null;
    }
    return Supabase.instance.client;
  }

  Future<void> initialize() async {
    if (_initialized || !_config.isSupabaseConfigured) {
      return;
    }

    await Supabase.initialize(
      url: _config.supabaseUrl,
      anonKey: _config.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );

    _initialized = true;
  }

  Stream<User?> authStateChanges() {
    if (_client == null) {
      return Stream<User?>.value(null);
    }

    return _client!.auth.onAuthStateChange.map((data) => data.session?.user);
  }

  User? get currentUser => _client?.auth.currentUser;

  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      return false;
    }

    await _client!.auth.signInWithPassword(email: email, password: password);
    return _client!.auth.currentUser != null;
  }

  Future<void> signOut() async {
    if (_client == null) {
      return;
    }
    await _client!.auth.signOut();
  }

  Future<List<FarmSummary>> fetchAccessibleFarms() async {
    if (_client == null ||
        (_config.devBypassLogin && currentUser == null)) {
      debugPrint(
        '[Appiombi][Farms] Dati demo locali attivi. configured=${_config.isSupabaseConfigured} bypass=${_config.devBypassLogin} user=${currentUser?.id ?? 'none'}',
      );
      return const [
        FarmSummary(
          id: 'demo-farm-1',
          name: 'Azienda Test Appiombi',
          farmCode: 'APP-DEMO-01',
          accessMode: 'writable',
          canRead: true,
          canWrite: true,
        ),
      ];
    }

    final userId = currentUser?.id ?? 'unknown';
    debugPrint('[Appiombi][Farms] Load start for user: $userId');

    try {
      debugPrint('[Appiombi][Farms] Query profiles for current auth user.');
      final profileRows = await _withTimeout<List<dynamic>>(
        label: 'profiles.select_self',
        future: _client!
            .from('profiles')
            .select('id, auth_user_id, email, account_status, is_active, email_verified_at')
            .limit(1),
      );

      if (profileRows.isEmpty) {
        debugPrint('[Appiombi][Farms] Nessun profilo trovato per auth user: $userId');
        throw Exception(
          'Profilo utente non trovato. Verifica il collegamento tra auth.users e profiles.',
        );
      }

      final profile = profileRows.first as Map<String, dynamic>;
      final profileId = profile['id'] as String? ?? 'unknown';
      debugPrint(
        '[Appiombi][Farms] Profile found: id=$profileId auth_user_id=${profile['auth_user_id']} email=${profile['email']} status=${profile['account_status']} active=${profile['is_active']} verified=${profile['email_verified_at'] != null}',
      );

      debugPrint('[Appiombi][Farms] Query active_farm_users for current profile.');
      final membershipRows = await _withTimeout<List<dynamic>>(
        label: 'active_farm_users.select_self',
        future: _client!
            .from('active_farm_users')
            .select('farm_id, role, profile_id')
            .eq('profile_id', profileId),
      );

      debugPrint(
        '[Appiombi][Farms] Active memberships received: ${membershipRows.length}',
      );

      debugPrint('[Appiombi][Farms] Query farms with RLS filtering.');
      final farmRows = await _withTimeout<List<dynamic>>(
        label: 'farms.select_accessible',
        future: _client!
            .from('farms')
            .select('id, name, farm_code')
            .order('name'),
      );

      final farmIds = farmRows
          .map((row) => row['id'] as String?)
          .whereType<String>()
          .toList();

      debugPrint('[Appiombi][Farms] Farms received: ${farmIds.length}');

      if (farmIds.isEmpty) {
        debugPrint(
          '[Appiombi][Farms] Nessuna farm accessibile per profile_id=$profileId. owner/membership link might be missing.',
        );
        return const [];
      }

      debugPrint('[Appiombi][Farms] Query farm_access_modes for ${farmIds.length} farm(s).');
      final accessRows = await _withTimeout<List<dynamic>>(
        label: 'farm_access_modes.select',
        future: _client!
            .from('farm_access_modes')
            .select('farm_id, access_mode, reason, can_read, can_write')
            .inFilter('farm_id', farmIds),
      );

      debugPrint('[Appiombi][Farms] Access rows received: ${accessRows.length}');

      final accessByFarmId = {
        for (final row in accessRows)
          row['farm_id'] as String: {
            'access_mode': row['access_mode'] as String? ?? 'blocked',
            'can_read': row['can_read'] as bool? ?? false,
            'can_write': row['can_write'] as bool? ?? false,
          },
      };

      final farms = farmRows.map((row) {
        final access = accessByFarmId[row['id'] as String] ??
            const {
              'access_mode': 'read_only',
              'can_read': true,
              'can_write': false,
            };

        return FarmSummary(
          id: row['id'] as String,
          name: row['name'] as String? ?? 'Farm',
          farmCode: row['farm_code'] as String? ?? '',
          accessMode: access['access_mode'] as String,
          canRead: access['can_read'] as bool,
          canWrite: access['can_write'] as bool,
        );
      }).toList();

      debugPrint('[Appiombi][Farms] Final farms mapped: ${farms.length}');
      return farms;
    } on TimeoutException catch (error) {
      debugPrint('[Appiombi][Farms] Timeout: $error');
      throw Exception('Timeout caricamento aziende');
    } on PostgrestException catch (error) {
      debugPrint(
        '[Appiombi][Farms] Supabase error: code=${error.code}, message=${error.message}, details=${error.details}',
      );
      throw Exception('Errore Supabase nel caricamento aziende: ${error.message}');
    } catch (error) {
      debugPrint('[Appiombi][Farms] Unexpected error: $error');
      throw Exception('Errore inatteso nel caricamento aziende: $error');
    }
  }

  Future<List<CowPreview>> fetchCows(String farmId) async {
    if (_client == null) {
      return const [
        CowPreview(id: 'cow-101', identifier: '101', displayIdentifier: '101'),
        CowPreview(id: 'cow-234', identifier: '234', displayIdentifier: '234'),
        CowPreview(id: 'cow-789', identifier: '789', displayIdentifier: '789'),
      ];
    }

    final rows = await _client!
        .from('active_animals')
        .select('id, cow_identifier, display_identifier')
        .eq('farm_id', farmId)
        .order('cow_identifier');

    return (rows as List<dynamic>).map((row) {
      return CowPreview(
        id: row['id'] as String,
        identifier: row['cow_identifier'] as String? ?? '',
        displayIdentifier: row['display_identifier'] as String? ?? '',
      );
    }).toList();
  }
}

Future<T> _withTimeout<T>({
  required String label,
  required Future<T> future,
}) {
  return future.timeout(
    SupabaseService._requestTimeout,
    onTimeout: () {
      throw TimeoutException(
        'Request timeout for $label after ${SupabaseService._requestTimeout.inSeconds} seconds',
      );
    },
  );
}

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  throw UnimplementedError('SupabaseService override is required at bootstrap.');
});

final authUserProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.authStateChanges();
});

final accessibleFarmsProvider = FutureProvider<List<FarmSummary>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.fetchAccessibleFarms();
});

final cowsByFarmProvider = FutureProvider.family<List<CowPreview>, String>((ref, farmId) {
  final service = ref.watch(supabaseServiceProvider);
  return service.fetchCows(farmId);
});
