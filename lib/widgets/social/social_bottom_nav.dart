import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SocialBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SocialBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: theme.scaffoldBackgroundColor,
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(LucideIcons.home), label: 'Início'),
        BottomNavigationBarItem(
            icon: Icon(LucideIcons.compass), label: 'Explorar'),
        BottomNavigationBarItem(
            icon: Icon(LucideIcons.plusCircle), label: 'Publicar'),
        BottomNavigationBarItem(
            icon: Icon(LucideIcons.messageSquare), label: 'Mensagens'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Perfil'),
      ],
    );
  }
}
