import 'package:flutter/material.dart';

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({
    required this.onPressed,
    this.semanticLabel = 'Profil oeffnen',
    super.key,
  });

  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: IconButton(
        onPressed: onPressed,
        iconSize: 40,
        icon: const CircleAvatar(radius: 18, child: Icon(Icons.person)),
      ),
    );
  }
}
