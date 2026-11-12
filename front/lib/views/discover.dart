import 'package:flutter/material.dart';
import 'package:front/components.dart';
import 'package:front/manager.dart';

class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _downloading = {};  
  List<ExtSong> _results = [];
  bool _isLoading = false; 

  Future<void> _search(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = [];
    });

    final data = await get<ApiManager>().exSearch(query);
    print(data);
    if (mounted) {
      setState(() {
        _results = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    _results = [];
                  });
                },
              )
            ),
            onSubmitted: _search,
          ),
        ),

       Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.purple))
              : _results.isEmpty
                  ? const Center(child: Text("No Results", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: ((context, index) {
                      final song = _results[index];
                      final isDownloading = _downloading.contains(song.id);
                      return GenCard(
                        title: song.title,
                        subtitle: song.uploader,
                        icon: Icons.music_note,
                        trailing: isDownloading 
                          ? const SizedBox(
                              width: 20, height: 20, 
                              child: CircularProgressIndicator(color: Colors.purpleAccent, strokeWidth: 2),
                            )
                          : Icon(Icons.download, color: Colors.purpleAccent),
                        onClick: () async {
                          setState(() => _downloading.add(song.id)); 

                          bool success = await get<ApiManager>().exDownload(song.url);
                  
                          if (mounted) {
                            setState(() => _downloading.remove(song.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(success ? "Download Ready" : "Download Error"), 
                                backgroundColor: Colors.green
                              )
                            );
                          }
                        },
                      );
                    }),
                  )
        ) 
      ],
    );
  }
}
