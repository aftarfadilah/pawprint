import 'package:flutter/material.dart';

import '../models/pet.dart';

class PetAvatar extends StatelessWidget {
  final Pet pet;
  final double size;
  const PetAvatar({super.key, required this.pet, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = pet.photoBase64;
    if (photo != null && photo.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photo,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(scheme),
        ),
      );
    }
    return _placeholder(scheme);
  }

  Widget _placeholder(ColorScheme scheme) {
    final emoji = pet.species.toLowerCase().contains('cat')
        ? '🐱'
        : pet.species.toLowerCase().contains('dog')
            ? '🐶'
            : '🐾';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.55)),
    );
  }
}
