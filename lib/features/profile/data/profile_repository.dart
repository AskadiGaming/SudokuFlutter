abstract interface class ProfileRepository {
  Future<String?> loadUsername();

  Future<void> saveUsername(String username);
}
