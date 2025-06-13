import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity?> findByEmail(String email);
  Future<UserEntity?> findById(String id);
  Future<UserEntity> create(UserEntity user);
  Future<UserEntity> update(UserEntity user);
  Future<void> delete(String id);
  Future<List<UserEntity>> findAll();
  Future<bool> exists(String email);
}