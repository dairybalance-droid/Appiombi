import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../features/sessions/session_mock_data.dart';

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

class TrimmingSessionSummary {
  const TrimmingSessionSummary({
    required this.id,
    required this.farmId,
    required this.sessionTypeCode,
    required this.status,
    required this.startedAt,
    required this.closedAt,
    required this.reopenedAt,
  });

  final String id;
  final String farmId;
  final String sessionTypeCode;
  final String status;
  final DateTime startedAt;
  final DateTime? closedAt;
  final DateTime? reopenedAt;

  String get sessionTypeLabel => sessionTypeCodeToLabel(sessionTypeCode);
  String get statusLabel => sessionStatusCodeToLabel(status);
}

class SessionVisitRow {
  const SessionVisitRow({
    required this.id,
    required this.cowNumber,
    required this.worstLesion,
    required this.medicationsLabel,
    required this.solesCount,
    required this.bandagesCount,
  });

  final String id;
  final int cowNumber;
  final String worstLesion;
  final String medicationsLabel;
  final int solesCount;
  final int bandagesCount;
}

class SessionHistoryRow {
  const SessionHistoryRow({
    required this.id,
    required this.sessionTypeCode,
    required this.status,
    required this.startedAt,
    required this.cowsVisited,
    required this.soleCount,
    required this.bandageCount,
  });

  final String id;
  final String sessionTypeCode;
  final String status;
  final DateTime startedAt;
  final int cowsVisited;
  final int soleCount;
  final int bandageCount;

  String get sessionTypeLabel => sessionTypeCodeToLabel(sessionTypeCode);
}

class CowVisitDetail {
  const CowVisitDetail({
    required this.id,
    required this.farmId,
    required this.sessionId,
    required this.cowNumber,
    required this.visitDate,
    required this.solesCount,
    required this.bandagesCount,
    required this.antibioticCode,
    required this.antiInflammatoryCode,
    required this.notes,
    required this.status,
  });

  final String id;
  final String farmId;
  final String sessionId;
  final int cowNumber;
  final DateTime visitDate;
  final int solesCount;
  final int bandagesCount;
  final String antibioticCode;
  final String antiInflammatoryCode;
  final String notes;
  final String status;
}

class DuplicateCowNumberException implements Exception {
  const DuplicateCowNumberException(this.cowNumber);

  final int cowNumber;

  @override
  String toString() => 'Capo già presente.';
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
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('[Appiombi][Farms] Query profiles for current auth user.');
      final profileStopwatch = Stopwatch()..start();
      final profileRows = await _withTimeout<List<dynamic>>(
        label: 'profiles.select_self',
        future: _client!
            .from('profiles')
            .select('id, auth_user_id, email, account_status, is_active, email_verified_at')
            .limit(1),
      );
      profileStopwatch.stop();
      debugPrint(
        '[Appiombi][Farms] profiles.select_self completed in ${profileStopwatch.elapsedMilliseconds} ms',
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
      final membershipStopwatch = Stopwatch()..start();
      final membershipRows = await _withTimeout<List<dynamic>>(
        label: 'active_farm_users.select_self',
        future: _client!
            .from('active_farm_users')
            .select('farm_id, role, profile_id')
            .eq('profile_id', profileId),
      );
      membershipStopwatch.stop();
      debugPrint(
        '[Appiombi][Farms] active_farm_users.select_self completed in ${membershipStopwatch.elapsedMilliseconds} ms',
      );

      debugPrint(
        '[Appiombi][Farms] Active memberships received: ${membershipRows.length}',
      );

      final farmIds = membershipRows
          .map((row) => row['farm_id'] as String?)
          .whereType<String>()
          .toList();
      debugPrint('[Appiombi][Farms] Farm ids from memberships: $farmIds');

      if (farmIds.isEmpty) {
        debugPrint(
          '[Appiombi][Farms] Nessuna membership attiva trovata per profile_id=$profileId.',
        );
        return const [];
      }

      debugPrint(
        '[Appiombi][Farms] Query farms by explicit membership ids to avoid full-table RLS scan.',
      );
      final farmsStopwatch = Stopwatch()..start();
      final farmRows = await _withTimeout<List<dynamic>>(
        label: 'farms.select_by_membership_ids',
        future: _client!
            .from('farms')
            .select('id, name, farm_code')
            .inFilter('id', farmIds)
            .order('name'),
      );
      farmsStopwatch.stop();
      debugPrint(
        '[Appiombi][Farms] farms.select_by_membership_ids completed in ${farmsStopwatch.elapsedMilliseconds} ms',
      );

      debugPrint('[Appiombi][Farms] Farm records received: ${farmRows.length}');

      if (farmRows.isEmpty) {
        debugPrint(
          '[Appiombi][Farms] Nessun record farms restituito per ids membership $farmIds. Possible farms RLS recursion/performance issue.',
        );
        return const [];
      }

      debugPrint(
        '[Appiombi][Farms] Query farm_access_modes for ${farmIds.length} farm(s).',
      );
      final accessStopwatch = Stopwatch()..start();
      final accessRows = await _withTimeout<List<dynamic>>(
        label: 'farm_access_modes.select',
        future: _client!
            .from('farm_access_modes')
            .select('farm_id, access_mode, reason, can_read, can_write')
            .inFilter('farm_id', farmIds),
      );
      accessStopwatch.stop();
      debugPrint(
        '[Appiombi][Farms] farm_access_modes.select completed in ${accessStopwatch.elapsedMilliseconds} ms',
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

      stopwatch.stop();
      debugPrint(
        '[Appiombi][Farms] Final farms mapped: ${farms.length} in ${stopwatch.elapsedMilliseconds} ms',
      );
      return farms;
    } on TimeoutException catch (error) {
      stopwatch.stop();
      debugPrint('[Appiombi][Farms] Timeout: $error');
      throw Exception('Timeout caricamento aziende');
    } on PostgrestException catch (error) {
      stopwatch.stop();
      debugPrint(
        '[Appiombi][Farms] Supabase error: code=${error.code}, message=${error.message}, details=${error.details}',
      );
      throw Exception('Errore Supabase nel caricamento aziende: ${error.message}');
    } catch (error) {
      stopwatch.stop();
      debugPrint('[Appiombi][Farms] Unexpected error: $error');
      throw Exception('Errore inatteso nel caricamento aziende: $error');
    }
  }

  Future<TrimmingSessionSummary> openOrCreateWorkingSession({
    required String farmId,
    required String requestedSessionTypeCode,
  }) async {
    if (_client == null) {
      return TrimmingSessionSummary(
        id: 'demo-session',
        farmId: farmId,
        sessionTypeCode: requestedSessionTypeCode,
        status: 'open',
        startedAt: DateTime.now(),
        closedAt: null,
        reopenedAt: null,
      );
    }

    final profileId = await _fetchCurrentProfileId();
    debugPrint(
      '[Appiombi][Sessions] openOrCreateWorkingSession farmId=$farmId requestedType=$requestedSessionTypeCode profileId=$profileId',
    );

    final existingRows = await _withTimeout<List<dynamic>>(
      label: 'active_trimming_sessions.select_open_or_reopened',
      future: _client!
          .from('active_trimming_sessions')
          .select('id, farm_id, session_type, status, started_at, closed_at, reopened_at')
          .eq('farm_id', farmId)
          .inFilter('status', const ['open', 'reopened'])
          .order('started_at', ascending: false)
          .limit(1),
    );

    if (existingRows.isNotEmpty) {
      debugPrint('[Appiombi][Sessions] Existing modifiable session found.');
      return _mapSessionSummary(existingRows.first as Map<String, dynamic>);
    }

    debugPrint('[Appiombi][Sessions] Creating new session on Supabase.');
    try {
      final insertedRows = await _withTimeout<List<dynamic>>(
        label: 'trimming_sessions.insert',
        future: _client!
            .from('trimming_sessions')
            .insert({
              'farm_id': farmId,
              'created_by_profile_id': profileId,
              'updated_by_profile_id': profileId,
              'session_type': requestedSessionTypeCode,
              'status': 'open',
            })
            .select('id, farm_id, session_type, status, started_at, closed_at, reopened_at')
            .limit(1),
      );

      return _mapSessionSummary(insertedRows.first as Map<String, dynamic>);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        debugPrint(
          '[Appiombi][Sessions] Unique modifiable session constraint hit, re-querying existing session.',
        );
        final fallbackRows = await _withTimeout<List<dynamic>>(
          label: 'active_trimming_sessions.select_after_conflict',
          future: _client!
              .from('active_trimming_sessions')
              .select('id, farm_id, session_type, status, started_at, closed_at, reopened_at')
              .eq('farm_id', farmId)
              .inFilter('status', const ['open', 'reopened'])
              .order('started_at', ascending: false)
              .limit(1),
        );

        if (fallbackRows.isNotEmpty) {
          return _mapSessionSummary(fallbackRows.first as Map<String, dynamic>);
        }
      }
      rethrow;
    }
  }

  Future<TrimmingSessionSummary?> fetchLatestSessionForFarm(String farmId) async {
    if (_client == null) {
      return null;
    }

    final rows = await _withTimeout<List<dynamic>>(
      label: 'active_trimming_sessions.select_latest_for_farm',
      future: _client!
          .from('active_trimming_sessions')
          .select('id, farm_id, session_type, status, started_at, closed_at, reopened_at')
          .eq('farm_id', farmId)
          .order('started_at', ascending: false)
          .limit(1),
    );

    if (rows.isEmpty) {
      return null;
    }

    return _mapSessionSummary(rows.first as Map<String, dynamic>);
  }

  Future<TrimmingSessionSummary?> reopenLatestSessionForFarm(String farmId) async {
    if (_client == null) {
      return null;
    }

    final latest = await fetchLatestSessionForFarm(farmId);
    if (latest == null) {
      return null;
    }

    if (latest.status == 'closed') {
      final profileId = await _fetchCurrentProfileId();
      debugPrint('[Appiombi][Sessions] Reopening last closed session ${latest.id}.');
      final rows = await _withTimeout<List<dynamic>>(
        label: 'trimming_sessions.reopen_latest',
        future: _client!
            .from('trimming_sessions')
            .update({
              'status': 'reopened',
              'updated_by_profile_id': profileId,
              'reopened_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', latest.id)
            .select('id, farm_id, session_type, status, started_at, closed_at, reopened_at')
            .limit(1),
      );
      return _mapSessionSummary(rows.first as Map<String, dynamic>);
    }

    return latest;
  }

  Future<List<SessionHistoryRow>> fetchSessionsForFarm(String farmId) async {
    if (_client == null) {
      return const [];
    }

    debugPrint('[Appiombi][Sessions] Fetch sessions history for farmId=$farmId');
    final sessionRows = await _withTimeout<List<dynamic>>(
      label: 'active_trimming_sessions.select_history',
      future: _client!
          .from('active_trimming_sessions')
          .select('id, farm_id, session_type, status, started_at, closed_at, reopened_at')
          .eq('farm_id', farmId)
          .order('started_at', ascending: false),
    );

    if (sessionRows.isEmpty) {
      return const [];
    }

    final sessionIds = sessionRows
        .map((row) => row['id'] as String?)
        .whereType<String>()
        .toList();

    final visitRows = await _withTimeout<List<dynamic>>(
      label: 'active_cow_visits.select_for_history',
      future: _client!
          .from('active_cow_visits')
          .select('session_id, soles_count, bandages_count')
          .inFilter('session_id', sessionIds),
    );

    final countsBySession = <String, Map<String, int>>{};
    for (final rawRow in visitRows) {
      final row = rawRow as Map<String, dynamic>;
      final sessionId = row['session_id'] as String;
      final bucket = countsBySession.putIfAbsent(
        sessionId,
        () => {'cows': 0, 'soles': 0, 'bandages': 0},
      );
      bucket['cows'] = (bucket['cows'] ?? 0) + 1;
      bucket['soles'] = (bucket['soles'] ?? 0) + _toInt(row['soles_count']);
      bucket['bandages'] =
          (bucket['bandages'] ?? 0) + _toInt(row['bandages_count']);
    }

    return sessionRows.map((rawRow) {
      final row = rawRow as Map<String, dynamic>;
      final sessionId = row['id'] as String;
      final counts = countsBySession[sessionId] ??
          const {'cows': 0, 'soles': 0, 'bandages': 0};

      return SessionHistoryRow(
        id: sessionId,
        sessionTypeCode: row['session_type'] as String? ?? 'herd_trim',
        status: row['status'] as String? ?? 'open',
        startedAt: DateTime.parse(row['started_at'] as String).toLocal(),
        cowsVisited: counts['cows'] ?? 0,
        soleCount: counts['soles'] ?? 0,
        bandageCount: counts['bandages'] ?? 0,
      );
    }).toList();
  }

  Future<TrimmingSessionSummary> fetchSession(String sessionId) async {
    if (_client == null) {
      throw Exception('Supabase non configurato per questa sessione.');
    }

    debugPrint('[Appiombi][Sessions] Fetch session detail sessionId=$sessionId');
    final rows = await _withTimeout<List<dynamic>>(
      label: 'active_trimming_sessions.select_by_id',
      future: _client!
          .from('active_trimming_sessions')
          .select('id, farm_id, session_type, status, started_at, closed_at, reopened_at')
          .eq('id', sessionId)
          .limit(1),
    );

    if (rows.isEmpty) {
      throw Exception('Sessione non trovata.');
    }

    return _mapSessionSummary(rows.first as Map<String, dynamic>);
  }

  Future<List<SessionVisitRow>> fetchSessionVisits(String sessionId) async {
    if (_client == null) {
      return const [];
    }

    debugPrint('[Appiombi][Sessions] Fetch session visits sessionId=$sessionId');
    final rows = await _withTimeout<List<dynamic>>(
      label: 'active_cow_visits.select_by_session',
      future: _client!
          .from('active_cow_visits')
          .select(
            'id, cow_number, soles_count, bandages_count, antibiotic_code, anti_inflammatory_code',
          )
          .eq('session_id', sessionId)
          .order('insertion_index'),
    );

    debugPrint('[Appiombi][Sessions] Session visits received: ${rows.length}');

    return rows.map((rawRow) {
      final row = rawRow as Map<String, dynamic>;
      final antibioticCode = (row['antibiotic_code'] as String? ?? '').trim();
      final antiInflammatoryCode =
          (row['anti_inflammatory_code'] as String? ?? '').trim();

      return SessionVisitRow(
        id: row['id'] as String,
        cowNumber: _toInt(row['cow_number']),
        worstLesion: '',
        medicationsLabel: _buildMedicationLabel(
          antibioticCode: antibioticCode,
          antiInflammatoryCode: antiInflammatoryCode,
        ),
        solesCount: _toInt(row['soles_count']),
        bandagesCount: _toInt(row['bandages_count']),
      );
    }).toList();
  }

  Future<CowVisitDetail> createDraftVisit({
    required String farmId,
    required String sessionId,
    required int cowNumber,
  }) async {
    if (_client == null) {
      return CowVisitDetail(
        id: 'demo-cow-visit-$cowNumber',
        farmId: farmId,
        sessionId: sessionId,
        cowNumber: cowNumber,
        visitDate: DateTime.now(),
        solesCount: 0,
        bandagesCount: 0,
        antibioticCode: '',
        antiInflammatoryCode: '',
        notes: '',
        status: 'draft',
      );
    }

    final profileId = await _fetchCurrentProfileId();
    debugPrint(
      '[Appiombi][Visits] Create draft visit farmId=$farmId sessionId=$sessionId cowNumber=$cowNumber profileId=$profileId',
    );

    final duplicateRows = await _withTimeout<List<dynamic>>(
      label: 'active_cow_visits.duplicate_check',
      future: _client!
          .from('active_cow_visits')
          .select('id, cow_number')
          .eq('session_id', sessionId)
          .eq('cow_number', cowNumber)
          .limit(1),
    );

    if (duplicateRows.isNotEmpty) {
      debugPrint('[Appiombi][Visits] Duplicate cow number detected: $cowNumber');
      throw DuplicateCowNumberException(cowNumber);
    }

    final insertionRows = await _withTimeout<List<dynamic>>(
      label: 'cow_visits.select_last_insertion_index',
      future: _client!
          .from('cow_visits')
          .select('insertion_index')
          .eq('session_id', sessionId)
          .order('insertion_index', ascending: false)
          .limit(1),
    );
    final nextInsertionIndex = insertionRows.isEmpty
        ? 1
        : _toInt((insertionRows.first as Map<String, dynamic>)['insertion_index']) + 1;

    try {
      final insertedRows = await _withTimeout<List<dynamic>>(
        label: 'cow_visits.insert_draft',
        future: _client!
            .from('cow_visits')
            .insert({
              'session_id': sessionId,
              'farm_id': farmId,
              'cow_number': cowNumber,
              'visit_date': DateTime.now().toUtc().toIso8601String().split('T').first,
              'insertion_index': nextInsertionIndex,
              'created_by_profile_id': profileId,
              'updated_by_profile_id': profileId,
              'status': 'draft',
            })
            .select(
              'id, farm_id, session_id, cow_number, visit_date, soles_count, bandages_count, antibiotic_code, anti_inflammatory_code, notes, status',
            )
            .limit(1),
      );

      return _mapCowVisitDetail(insertedRows.first as Map<String, dynamic>);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw DuplicateCowNumberException(cowNumber);
      }
      rethrow;
    }
  }

  Future<CowVisitDetail> fetchCowVisit(String cowVisitId) async {
    if (_client == null) {
      throw Exception('Supabase non configurato per questa visita.');
    }

    final rows = await _withTimeout<List<dynamic>>(
      label: 'active_cow_visits.select_by_id',
      future: _client!
          .from('active_cow_visits')
          .select(
            'id, farm_id, session_id, cow_number, visit_date, soles_count, bandages_count, antibiotic_code, anti_inflammatory_code, notes, status',
          )
          .eq('id', cowVisitId)
          .limit(1),
    );

    if (rows.isEmpty) {
      throw Exception('Visita vacca non trovata.');
    }

    return _mapCowVisitDetail(rows.first as Map<String, dynamic>);
  }

  Future<void> saveCowVisitBasic({
    required String cowVisitId,
    required int solesCount,
    required int bandagesCount,
    required bool antibiotic,
    required bool antiInflammatory,
    required String notes,
  }) async {
    if (_client == null) {
      return;
    }

    final profileId = await _fetchCurrentProfileId();
    await _withTimeout(
      label: 'cow_visits.update_basic',
      future: _client!
          .from('cow_visits')
          .update({
            'soles_count': solesCount,
            'bandages_count': bandagesCount,
            'antibiotic_code': antibiotic ? 'yes' : '',
            'anti_inflammatory_code': antiInflammatory ? 'yes' : '',
            'notes': notes.trim().isEmpty ? null : notes.trim(),
            'status': 'saved',
            'updated_by_profile_id': profileId,
          })
          .eq('id', cowVisitId),
    );
  }

  Future<void> closeSession({
    required String sessionId,
  }) async {
    if (_client == null) {
      return;
    }

    final profileId = await _fetchCurrentProfileId();
    await _withTimeout(
      label: 'trimming_sessions.close',
      future: _client!
          .from('trimming_sessions')
          .update({
            'status': 'closed',
            'updated_by_profile_id': profileId,
            'closed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', sessionId),
    );
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

  Future<String> _fetchCurrentProfileId() async {
    final user = currentUser;
    if (_client == null || user == null) {
      throw Exception('Utente autenticato non disponibile.');
    }

    final rows = await _withTimeout<List<dynamic>>(
      label: 'profiles.select_current_profile_id',
      future: _client!
          .from('profiles')
          .select('id')
          .eq('auth_user_id', user.id)
          .limit(1),
    );

    if (rows.isEmpty) {
      throw Exception('Profilo utente non trovato.');
    }

    return (rows.first as Map<String, dynamic>)['id'] as String;
  }

  TrimmingSessionSummary _mapSessionSummary(Map<String, dynamic> row) {
    return TrimmingSessionSummary(
      id: row['id'] as String,
      farmId: row['farm_id'] as String,
      sessionTypeCode: row['session_type'] as String? ?? 'herd_trim',
      status: row['status'] as String? ?? 'open',
      startedAt: DateTime.parse(row['started_at'] as String).toLocal(),
      closedAt: _toDateTime(row['closed_at']),
      reopenedAt: _toDateTime(row['reopened_at']),
    );
  }

  CowVisitDetail _mapCowVisitDetail(Map<String, dynamic> row) {
    return CowVisitDetail(
      id: row['id'] as String,
      farmId: row['farm_id'] as String,
      sessionId: row['session_id'] as String,
      cowNumber: _toInt(row['cow_number']),
      visitDate: DateTime.parse(row['visit_date'] as String).toLocal(),
      solesCount: _toInt(row['soles_count']),
      bandagesCount: _toInt(row['bandages_count']),
      antibioticCode: (row['antibiotic_code'] as String? ?? '').trim(),
      antiInflammatoryCode:
          (row['anti_inflammatory_code'] as String? ?? '').trim(),
      notes: row['notes'] as String? ?? '',
      status: row['status'] as String? ?? 'draft',
    );
  }
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.parse(value as String).toLocal();
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String && value.isNotEmpty) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

String _buildMedicationLabel({
  required String antibioticCode,
  required String antiInflammatoryCode,
}) {
  final hasAntibiotic = antibioticCode.trim().isNotEmpty;
  final hasAntiInflammatory = antiInflammatoryCode.trim().isNotEmpty;

  if (hasAntibiotic && hasAntiInflammatory) {
    return 'AB + AI';
  }
  if (hasAntibiotic) {
    return 'AB';
  }
  if (hasAntiInflammatory) {
    return 'AI';
  }
  return '';
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
