import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistService extends ChangeNotifier {
  static final WishlistService _instance = WishlistService._internal();
  factory WishlistService() => _instance;
  WishlistService._internal();

  List<String> _wishlistIds = [];
  SharedPreferences? _prefs;
  final _supabase = Supabase.instance.client;

  List<String> get wishlistIds => List.unmodifiable(_wishlistIds);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // 1. Load local cache instantly for fast UI
    _wishlistIds = _prefs?.getStringList('wishlist') ?? [];
    notifyListeners();

    // 2. Sync with database in background if user is logged in
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await _supabase
            .from('wishlists')
            .select('host_id')
            .eq('user_id', user.id);

        final dbWishlist = (response as List<dynamic>)
            .map((e) => e['host_id'].toString())
            .toList();

        _wishlistIds = dbWishlist;
        await _prefs?.setStringList('wishlist', _wishlistIds);
        notifyListeners();
      } catch (e) {
        debugPrint('Error syncing wishlist from database: $e');
      }
    }
  }

  bool isWishlisted(String id) {
    return _wishlistIds.contains(id);
  }

  Future<void> toggleWishlist(String id) async {
    final isCurrentlyWishlisted = _wishlistIds.contains(id);

    // 1. Optimistic UI update
    if (isCurrentlyWishlisted) {
      _wishlistIds.remove(id);
    } else {
      _wishlistIds.add(id);
    }
    await _prefs?.setStringList('wishlist', _wishlistIds);
    notifyListeners();

    // 2. Sync to Supabase in background
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        if (isCurrentlyWishlisted) {
          // It was wishlisted, we are removing it
          await _supabase
              .from('wishlists')
              .delete()
              .eq('user_id', user.id)
              .eq('host_id', id);
        } else {
          // It wasn't wishlisted, we are adding it
          await _supabase.from('wishlists').insert({
            'user_id': user.id,
            'host_id': id,
          });
        }
      } catch (e) {
        debugPrint('Error syncing wishlist to database: $e');
        // Revert optimistic update if database fails (optional but good practice)
        if (isCurrentlyWishlisted) {
          _wishlistIds.add(id);
        } else {
          _wishlistIds.remove(id);
        }
        await _prefs?.setStringList('wishlist', _wishlistIds);
        notifyListeners();
      }
    }
  }
}
