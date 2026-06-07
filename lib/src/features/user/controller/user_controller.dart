import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/user.dart';
import '../repository/user_repository.dart';
import '../../auth/controller/auth_controller.dart';
import '../../../utils/dio/dio_client.dart';

part 'user_controller.g.dart';

@riverpod
class UserController extends _$UserController {
  late UserRepository _repository;

  @override
  FutureOr<User?> build() async {
    final auth = await ref.watch(authControllerProvider.future);
    if (auth == null) return null;

    final Dio dio = ref.watch(dioClientProvider);
    _repository = UserRepository(dio);

    return await fetchUser();
  }

  Future<User?> fetchUser() async {
    final auth = ref.read(authControllerProvider).value;
    if (auth == null) return null;

    try {
      final User? user = await _repository.getUser();

      if (user == null ||
          user.userIdHash == null ||
          user.nickname == null) {
        return null;
      }

      return user;
    } catch (e, st) {
      debugPrint('[UserController] fetchUser error: $e\n$st');
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
