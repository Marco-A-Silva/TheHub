import 'package:flutter/material.dart';

class GenCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onClick;

  const GenCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.circle,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onClick,
      ),
    );
  }
}
