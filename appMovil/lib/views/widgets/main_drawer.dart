import 'package:flutter/material.dart';
import '../feed/feed_view.dart';
import '../perfil/perfil_view.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF1B5E20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.radar, color: Colors.white, size: 48),
                SizedBox(height: 12),
                Text(
                  'Echoes',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PerfilView()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.feed),
            title: const Text('Muro de Búsquedas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const FeedView()),
              );
            },
          ),
        ],
      ),
    );
  }
}
