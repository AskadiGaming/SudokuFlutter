class ProfileState {
  const ProfileState({required this.username});

  final String username;

  ProfileState copyWith({String? username}) {
    return ProfileState(username: username ?? this.username);
  }
}
