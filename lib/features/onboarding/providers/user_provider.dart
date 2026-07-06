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
    return await _databaseHelper.queryUser();
  }

  Future<void> saveUser(User user) async {
    await _databaseHelper.insert('user', user);
  }
}
