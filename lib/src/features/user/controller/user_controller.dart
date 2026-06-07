import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/user.dart';
import '../repository/user_repository.dart';
import '../../auth/repository/auth_repository.dart';
import '../../../utils/dio/dio_client.dart';

part 'user_controller.g.dart';

@riverpod
class UserController extends _$UserController {
  late UserRepository _repository;

  @override
  FutureOr<User?> build() async {
    final Dio dio = ref.watch(dioClientProvider);
    _repository = UserRepository(dio);

    return await fetchUser();
  }

  Future<User?> fetchUser() async {
    try {
      final User? user = await _repository.getUser();

      if (user == null ||
          user.userIdHash == null ||
          user.nickname == null) {
        await ref.watch(authRepositoryProvider).deleteCookies();
        return null;
      }

      return user;
    } catch (e, st) {
      debugPrint('[UserController] fetchUser error: $e\n$st');
      await ref.watch(authRepositoryProvider).deleteCookies();
      return null;
    }
  }

  Future<void> signIn() async {
    final User? user = await fetchUser();

    state = AsyncData(user);
  }

  void signOut() {
    state = const AsyncData(null);
  }
}
