import 'package:flutter/material.dart';

class ListIconOption {
  const ListIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

const List<ListIconOption> listIconOptions = [
  ListIconOption(key: 'list', label: 'Lista', icon: Icons.list_alt_rounded),
  ListIconOption(key: 'inbox', label: 'Bandeja', icon: Icons.inbox_rounded),
  ListIconOption(key: 'school', label: 'Universidad', icon: Icons.school_rounded),
  ListIconOption(key: 'home', label: 'Personal', icon: Icons.home_rounded),
  ListIconOption(key: 'computer', label: 'Proyectos', icon: Icons.computer_rounded),
  ListIconOption(key: 'shopping', label: 'Compras', icon: Icons.shopping_cart_rounded),
  ListIconOption(key: 'idea', label: 'Ideas', icon: Icons.lightbulb_rounded),
  ListIconOption(key: 'target', label: 'Objetivos', icon: Icons.track_changes_rounded),
  ListIconOption(key: 'star', label: 'Favoritos', icon: Icons.star_rounded),
  ListIconOption(key: 'tools', label: 'Herramientas', icon: Icons.handyman_rounded),
];

String normalizeListIconKey(String value) {
  return switch (value) {
    '📋' => 'list',
    '📥' => 'inbox',
    '📚' => 'school',
    '🏠' => 'home',
    '💻' => 'computer',
    '🛒' => 'shopping',
    '💡' => 'idea',
    '🎯' => 'target',
    '⭐' => 'star',
    '🧰' => 'tools',
    _ => value,
  };
}

IconData listIconData(String value) {
  return switch (normalizeListIconKey(value)) {
    'inbox' => Icons.inbox_rounded,
    'school' => Icons.school_rounded,
    'home' => Icons.home_rounded,
    'computer' => Icons.computer_rounded,
    'shopping' => Icons.shopping_cart_rounded,
    'idea' => Icons.lightbulb_rounded,
    'target' => Icons.track_changes_rounded,
    'star' => Icons.star_rounded,
    'tools' => Icons.handyman_rounded,
    'list' => Icons.list_alt_rounded,
    _ => Icons.folder_rounded,
  };
}
