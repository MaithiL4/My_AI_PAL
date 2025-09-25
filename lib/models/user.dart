import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  late String userName;

  @HiveField(1)
  late String passwordHash;

  @HiveField(2)
  late String aiPalName;

  @HiveField(3)
  late bool hasSeenWelcome;
}
