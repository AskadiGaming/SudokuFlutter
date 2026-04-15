class ProfileState {
  const ProfileState({required this.effectiveUsername});

  final String effectiveUsername;

  ProfileState copyWith({String? effectiveUsername}) {
    return ProfileState(
      effectiveUsername: effectiveUsername ?? this.effectiveUsername,
    );
  }
}
