import 'package:carbon_tracker/database/database_helper.dart';
import 'package:carbon_tracker/database/models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userProvider = NotifierProvider<UserNotifier, User?>(UserNotifier.new);

class UserNotifier extends Notifier<User?> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  User? build() => null;

  void setUser(User? user) {
    state = user;
  }

  Future<User?> loadUser() async {
    state = await _databaseHelper.queryUser();
    return state;
  }

  Future<void> saveUser(User userObj) async {
    await _databaseHelper.insert('user', userObj);
    state = await loadUser();
  }

  Future<void> updateUser(User user) async {
    await _databaseHelper.updateData('user', user);
    state = user;
  }

  Future<void> deleteUser() async {
    await _databaseHelper.deleteData('user', 1);
    state = null;
  }
}
