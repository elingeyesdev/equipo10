import 'package:flutter/material.dart';
import '../feed/feed_view.dart';
import '../mis_operativos/mis_operativos_view.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Current route name check can be tricky without named routes, 
    // so we just pushReplacement or pop according to needs.
    // For simplicity, we just use PushReplacement.

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
            leading: const Icon(Icons.feed),
            title: const Text('Muro de Operativos'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const FeedView()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_shared),
            title: const Text('Mis Operativos'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MisOperativosView()),
              );
            },
          ),
        ],
      ),
    );
  }
}
