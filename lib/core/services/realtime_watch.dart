import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the existing repository-based GetX ViewModels in sync with changes
/// made on other devices. Realtime replication must be enabled in Supabase.
class RealtimeWatch {
  RealtimeWatch(this._client);

  final SupabaseClient _client;
  final List<RealtimeChannel> _channels = [];
  static int _nextChannel = 0;

  void watch({required String table, required void Function() onChange}) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final channel = _client
        .channel('digikhata:$table:${_nextChannel++}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'shop_id',
            value: userId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
    _channels.add(channel);
  }

  void dispose() {
    for (final channel in _channels) {
      unawaited(_client.removeChannel(channel));
    }
    _channels.clear();
  }
}
