import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

// AsyncNotifier untuk mengelola state user
class UserNotifier extends FamilyAsyncNotifier<AppUser?, String> {
  @override
  Future<AppUser?> build(String userId) async {
    // Load initial user data
    final userStream = firestoreService.getUser(userId);
    return userStream.first;
  }

  Future<void> updateUser(AppUser user) async {
    final previousState = state;
    state = const AsyncLoading();

    try {
      await firestoreService.updateUser(user);
      // Update local state
      state = AsyncData(user);
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
      // Kembalikan ke state sebelumnya jika gagal
      state = previousState;
    }
  }

  Future<void> createUser(AppUser user) async {
    final previousState = state;
    state = const AsyncLoading();

    try {
      await firestoreService.createUser(user);
      // Update local state
      state = AsyncData(user);
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
      // Kembalikan ke state sebelumnya jika gagal
      state = previousState;
    }
  }
}

// Provider untuk user berdasarkan ID
final userProvider = 
    AsyncNotifierProvider.family<UserNotifier, AppUser?, String>((ref, userId) {
  return UserNotifier()..ref = ref;
});

// Provider untuk mengupdate user
final updateUserNotifierProvider = 
    NotifierProvider<UpdateUserNotifier, void>(UpdateUserNotifier);

class UpdateUserNotifier extends Notifier<void> {
  @override
  void build() {}
  
  Future<void> updateUser(AppUser user) async {
    final userId = user.id;
    final userProviderForId = userProvider(userId);
    
    final previousState = ref.read(userProviderForId);
    ref.read(userProviderForId.notifier).state = const AsyncLoading();

    try {
      await firestoreService.updateUser(user);
      // Update local state
      ref.read(userProviderForId.notifier).state = AsyncData(user);
    } catch (error) {
      // Kembalikan ke state sebelumnya jika gagal
      ref.read(userProviderForId.notifier).state = previousState;
      rethrow;
    }
  }
}