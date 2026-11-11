import 'package:front/components.dart';
import 'package:flutter/material.dart';
import 'package:front/manager.dart';

class ArtistsView extends StatefulWidget {
  const ArtistsView({super.key});

  @override
  State<ArtistsView> createState() => _ArtistsViewState();
}

class _ArtistsViewState extends State<ArtistsView> {
  List _artists = [];
  bool _isLoading = true;

  @override
  void initState() {
    _load();
    super.initState();
  }
  
  Future<void> _load() async {
    List data = await get<ApiManager>().getArtists();
    if (!mounted) return;
    setState(() {
      _artists = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          Expanded(
            child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: Colors.purple)) 
            : RefreshIndicator(
                color: Colors.purple,
                onRefresh: () async { _load(); },
                child: ListView.builder(
                  itemCount: _artists.length,
                  itemBuilder: (context, index) {
                    var artist = _artists[index];
                    return GenCard(
                      title: artist["name"] ?? "Unknown Artist",
                      subtitle: "ID ${artist['id'] ?? '?'}",
                      icon: Icons.person,
                      onClick: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => ArtistView(artist: artist),
                          ),
                        );
                      },
                    );
                  } 
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ArtistView extends StatefulWidget {
  final Map<String, dynamic> artist;
  const ArtistView({super.key, required this.artist});

  @override
  State<ArtistView> createState() => _ArtistViewState();

}

class _ArtistViewState extends State<ArtistView> {
  List _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    _load();
    super.initState();
  }

  Future<void> _load() async {
    List data = await get<ApiManager>().getArtist(widget.artist["id"]);
    if (!mounted) return;
    setState(() {
      _albums = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.artist["name"] ?? "Artist")),
      body: Center(
        child: _isLoading 
          ? CircularProgressIndicator(color: Colors.purple) 
          : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                color: Colors.purple,
                onRefresh: () async { _load(); },
                child: ListView.builder(
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    var album = _albums[index];
                    return GenCard(
                      title: album["name"] ?? "Unknown Album", 
                      subtitle: "ID ${album['id'] ?? '?'}",
                      icon: Icons.album, 
                      onClick: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => AlbumView(album: album),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlbumView extends StatefulWidget {
  final Map<String, dynamic> album;
  const AlbumView({super.key, required this.album});

  @override
  State<AlbumView> createState() => _AlbumViewState();

}

class _AlbumViewState extends State<AlbumView> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    _load();
    super.initState();
  }

  Future<void> _load() async {
    List data = await get<ApiManager>().getAlbum(widget.album["id"]);
    if (!mounted) return;
    setState(() {
      _songs = data.map((s) => Song.fromMap(s, defaultArtist: widget.album['artist'] ?? 'Artista')).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El AppBar genera automáticamente el botón "Atrás" (←)
      appBar: AppBar(title: Text(widget.album["name"])),
      body: Center(
        child: _isLoading 
          ? CircularProgressIndicator(color: Colors.purple) 
          : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                color: Colors.purple,
                onRefresh: () async { _load(); },
                child: ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    var song = _songs[index];
                    return GenCard(
                      title: song.title, 
                      subtitle: "ID ${song.id}",
                      icon: Icons.album, 
                      onClick: () {
                        print("Seleccionaste la cancion: ${song.title} con id ${song.id}");
                        get<AudioManager>().albumPlay(_songs, index);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
