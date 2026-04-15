import 'package:flutter/material.dart';

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({
    required this.onPressed,
    this.photoUrl,
    this.semanticLabel = 'Profil oeffnen',
    super.key,
  });

  final VoidCallback onPressed;
  final String? photoUrl;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final String? resolvedPhotoUrl = photoUrl?.trim();
    final bool hasPhoto =
        resolvedPhotoUrl != null && resolvedPhotoUrl.isNotEmpty;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: IconButton(
        onPressed: onPressed,
        iconSize: 40,
        icon: CircleAvatar(
          radius: 18,
          backgroundImage: hasPhoto ? NetworkImage(resolvedPhotoUrl) : null,
          child: hasPhoto ? null : const Icon(Icons.person),
        ),
      ),
    );
  }
}
