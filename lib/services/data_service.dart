import 'package:flutter/foundation.dart';
import 'package:paw_stay/models/host.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final _supabase = Supabase.instance.client;

  Future<List<Host>> getHosts() async {
    try {
      final response = await _supabase.from('hosts').select();
      final data = response as List<dynamic>;
      return data.map((json) => Host.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error fetching hosts: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getActiveRequests() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // First find the host record for this user
      final hostResponse = await _supabase
          .from('hosts')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (hostResponse == null) return [];

      final hostId = hostResponse['id'];

      // Fetch bookings for this host (both pending and confirmed)
      final response = await _supabase
          .from('bookings')
          .select('*, pets(*)')
          .eq('host_id', hostId)
          .filter('status', 'in', '("pending","confirmed")')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      return [];
    }
  }
}
