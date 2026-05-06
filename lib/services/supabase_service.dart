import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class FarmSummary {
  const FarmSummary({
    required this.id,
    required this.name,
    required this.streetAddress,
    required this.streetNumber,
    required this.postalCode,
    required this.city,
    required this.province,
    required this.farmCode,
    required this.accessMode,
    required this.canRead,
    required this.canWrite,
  });

  final String id;
  final String name;
  final String streetAddress;
  final String streetNumber;
  final String postalCode;
  final String city;
  final String province;
  final String farmCode;
  final String accessMode;
  final bool canRead;
  final bool canWrite;

  String get formattedAddress {
    final firstLine = [streetAddress, streetNumber].where((part) => part.isNotEmpty).join(' ');
    final secondLine = [postalCode, city, province].where((part) => part.isNotEmpty).join(' ');
    return [firstLine, secondLine].where((part) => part.isNotEmpty).join(', ');
  }
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
    if (_client == null) {
      return const [
        FarmSummary(
          id: 'demo-farm-1',
          name: 'Azienda Test Appiombi',
          streetAddress: 'Via Roma',
          streetNumber: '12',
          postalCode: '42025',
          city: 'Cavriago',
          province: 'RE',
          farmCode: 'APP-DEMO-01',
          accessMode: 'writable',
          canRead: true,
          canWrite: true,
        ),
      ];
    }

    final accessRows = await _client!
        .from('farm_access_modes')
        .select('farm_id, access_mode, can_read, can_write');

    final farmIds = (accessRows as List<dynamic>)
        .map((row) => row['farm_id'] as String?)
        .whereType<String>()
        .toList();

    if (farmIds.isEmpty) {
      return const [];
    }

    final farmRows = await _client!
        .from('farms')
        .select('id, name, street_address, street_number, postal_code, city, province, farm_code')
        .inFilter('id', farmIds)
        .order('name');

    final accessByFarmId = {
      for (final row in accessRows)
        row['farm_id'] as String: {
          'access_mode': row['access_mode'] as String? ?? 'blocked',
          'can_read': row['can_read'] as bool? ?? false,
          'can_write': row['can_write'] as bool? ?? false,
        },
    };

    return (farmRows as List<dynamic>).map((row) {
      final access = accessByFarmId[row['id'] as String] ?? const {
        'access_mode': 'blocked',
        'can_read': false,
        'can_write': false,
      };

      return FarmSummary(
        id: row['id'] as String,
        name: row['name'] as String? ?? 'Farm',
        streetAddress: row['street_address'] as String? ?? '',
        streetNumber: row['street_number'] as String? ?? '',
        postalCode: row['postal_code'] as String? ?? '',
        city: row['city'] as String? ?? '',
        province: row['province'] as String? ?? '',
        farmCode: row['farm_code'] as String? ?? '',
        accessMode: access['access_mode'] as String,
        canRead: access['can_read'] as bool,
        canWrite: access['can_write'] as bool,
      );
    }).toList();
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
