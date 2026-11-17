import 'package:flutter/material.dart';
import 'package:front/manager.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _autoplayEnabled = false; 
  final TextEditingController _playlistUrlController = TextEditingController();

  @override
  void dispose() {
    _playlistUrlController.dispose();
    super.dispose();
  }

  void _descargarPlaylist() {
    final url = _playlistUrlController.text.trim();
    if (url.isEmpty) return;
    
    get<ApiManager>().exDownload(url);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Iniciando descarga de playlist: $url")),
    );
    _playlistUrlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text("Autoplay"),
            subtitle: const Text("Reproducir canciones similares automáticamente al terminar la cola"),
            value: _autoplayEnabled,
            onChanged: (bool value) {
              setState(() {
                _autoplayEnabled = value;
              });
              // Idea futura: get<AudioManager>().setAutoplay(value);
            },
          ),
          const Divider(height: 40),
          
          const Text("Playlist Import", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
          const SizedBox(height: 10),
          TextField(
            controller: _playlistUrlController,
            decoration: InputDecoration(
              labelText: "Insert URL (YouTube)",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.download, color: Colors.purpleAccent),
                onPressed: _descargarPlaylist,
              ),
            ),
            onSubmitted: (_) => _descargarPlaylist(),
          ),
        ],
      ),
    );
  }
}
