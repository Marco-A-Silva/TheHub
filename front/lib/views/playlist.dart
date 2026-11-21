import 'package:flutter/material.dart';
import 'package:front/components.dart';
import 'package:front/manager.dart';

class PlaylistsView extends StatefulWidget {
  const PlaylistsView({super.key});

  @override
  State<PlaylistsView> createState() => _PlaylistsViewState();
}

class _PlaylistsViewState extends State<PlaylistsView> {
  List _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    _load();
    super.initState();
  }

  Future<void> _load() async {
    List data = await get<ApiManager>().getPlaylists();
    if (!mounted) return;
    setState(() {
      _playlists = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.add),
            label: const Text("Create Playlist"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),
        Expanded( 
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: Colors.purple)) 
            : RefreshIndicator(
                color: Colors.purple,
                onRefresh: () async { _load(); },
                child: ListView.builder(
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    print(_playlists.length);
                    var playlist = _playlists[index];
                    return GenCard(
                      title: playlist["name"],
                      subtitle: "${playlist["id"] ?? '?'} - ${playlist["comment"] ?? '?'}",
                      icon: Icons.queue_music,
                      onClick: () {
                        print("Selected ${playlist["name"]}");
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () {
                          get<ApiManager>().deletePlaylist(playlist["id"]); 
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
      ],
    );
  }
}
