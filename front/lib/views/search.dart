import 'package:front/views/atrists.dart';
import 'package:front/components.dart';
import 'package:flutter/material.dart';
import 'package:front/manager.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  Map _results = {};
  bool _isLoading = false;
  bool _hasSearched = false;
  
  final List<String> _filters = ['All', 'Songs', 'Artists', 'Albums'];
  String _selectedFilter = 'All';

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    
    Map data = await get<ApiManager>().search(query);

    setState(() {
      _results = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List artists = (_results["artists"] as List?) ?? [];
    final List albums = (_results["albums"] as List?) ?? [];
    final List songs = (_results["songs"] as List?) ?? [];

    final bool isEmpty = artists.isEmpty && albums.isEmpty && songs.isEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.purpleAccent),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _results = {};
                    _hasSearched = false;
                  });
                },
              )
            ),
            onSubmitted: _search,
          ),
        ),
        
        if (_hasSearched && !isEmpty)
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    selectedColor: Colors.purpleAccent,
                    backgroundColor: Colors.black26,
                    labelStyle: TextStyle(
                      color: _selectedFilter == filter ? Colors.white : Colors.white70,
                      fontWeight: _selectedFilter == filter ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              },
            ),
          ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.purple))
              : _hasSearched && isEmpty
                  ? const Center(child: Text("No Results", style: TextStyle(color: Colors.grey)))
                  : _buildResultsList(artists, albums, songs),
        ),   
      ],
    );
  }
  Widget _buildResultsList(List artists, List albums, List songs) {
    List<Widget> items = [];

    // Artists
    if ((_selectedFilter == 'All' || _selectedFilter == 'Artists') && artists.isNotEmpty) {
      if (_selectedFilter == 'All') {
        items.add( const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
          child: Text("Artists", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purpleAccent))
        ));
      }
      items.addAll(artists.map((a) => GenCard(
            title: a["name"] ?? "Artist",
            subtitle: "Artist",
            icon: Icons.person,
            onClick: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArtistView(artist: a as Map<String, dynamic>),
                ),
              );
            },
          )));
    }

    // Álbums
    if ((_selectedFilter == 'All' || _selectedFilter == 'Albums') && albums.isNotEmpty) {
      if (_selectedFilter == 'All') {
        items.add(const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text("Albums", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purpleAccent))));
      }
      items.addAll(albums.map((al) => GenCard(
            title: al["name"] ?? "Album",
            subtitle: "Album",
            icon: Icons.album,
            onClick: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlbumView(album: al as Map<String, dynamic>),
                ),
              );
            },
          )));
    }

    // Songs
    if ((_selectedFilter == 'All' || _selectedFilter == 'Songs') && songs.isNotEmpty) {
      if (_selectedFilter == 'All') {
        items.add(const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text("Songs", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purpleAccent))));
      }
      items.addAll(songs.asMap().entries.map((entry) {
        int idx = entry.key;
        var s = entry.value;
        return GenCard(
          title: s["title"] ?? "Song",
          subtitle: s["artist"] ?? "Artist",
          icon: Icons.music_note,
          onClick: () {
            List<Song> songList = songs.map((map) => Song.fromMap(map)).toList();
            get<AudioManager>().albumPlay(songList, idx);
          },
        );
      }));
    }

    if (items.isEmpty) {
      return Center(child: Text("No Results", style: const TextStyle(color: Colors.grey)));
    }

    return ListView(children: items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

