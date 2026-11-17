import 'package:flutter/material.dart';
import 'package:front/components.dart';

class PlaylistsView extends StatefulWidget {
  const PlaylistsView({super.key});

  @override
  State<PlaylistsView> createState() => _PlaylistsViewState();
}

class _PlaylistsViewState extends State<PlaylistsView> {
  final List<String> _playlists = ["Mis Favoritos", "Rock Nacional", "Descargadas YT"];

  void _crearPlaylist() {
    print("Botón de crear playlist presionado");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _crearPlaylist,
            icon: const Icon(Icons.add),
            label: const Text("Crear Nueva Playlist"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _playlists.length,
            itemBuilder: (context, index) {
              return GenCard(
                title: _playlists[index],
                subtitle: "Playlist",
                icon: Icons.queue_music,
                onClick: () {
                  print("Abriendo ${_playlists[index]}");
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    print("Eliminar ${_playlists[index]}");
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
