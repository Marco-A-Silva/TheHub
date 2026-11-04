import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:get_it/get_it.dart';
import 'package:front/components.dart';
import 'manager.dart';

final get = GetIt.instance;

void configureDependencies() {
  get.registerSingleton<ApiManager>(ApiManager("localhost:3000"));
  get.registerLazySingleton<AudioManager>(() => AudioManager("localhost:3000"));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  configureDependencies(); 
  runApp(TheHub());
}

class TheHub extends StatelessWidget {
  
  const TheHub({ super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Hub',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.purpleAccent, brightness: Brightness.dark),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black12, scrolledUnderElevation: 0, elevation: 0),
      ),
      home:  HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _curdex = 0;
  final List<String> _titles = ["Mi Biblioteca", "Ajustes"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_curdex])),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.2,
        backgroundColor: Theme.of(context).colorScheme.surface, 
        child: Column( 
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.black12,
            child: const Padding(
              padding: EdgeInsets.only(top: 12.5, bottom: 12.5),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_music, size: 30, color: Colors.purple),
                      Text("The Hub", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    ]
                  ),
                ],
              ),
            ),
          ),
      
      
      ListTile(
        leading: const Icon(Icons.person),
        title: const Text('Artistas'),
        selected: _curdex == 0,
        selectedColor: Colors.purpleAccent, 
        onTap: () {
          setState(() => _curdex = 0);
          Navigator.pop(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.settings),
        title: const Text('Ajustes'),
        selected: _curdex == 1,
        selectedColor: Colors.purpleAccent,
        onTap: () {
          setState(() => _curdex = 1);
          Navigator.pop(context);
        },
      ),
      
      const Spacer(), 
      
      const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Versión 1.0", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      )
    ],
  ),
),
      body: _drawView(),
    );
  }

  Widget _drawView() {
    if (_curdex == 0) {
      return ArtistViews(); 
    } else {
      return const SettingsView();
    }
  }
}

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
    _loadArtists();
    super.initState();
  }
  
  void _loadArtists() async {
    List data = await get<ApiManager>().getArtists();
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
            : ListView.builder(
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
            )
          )
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

  void _load() async {
    List data = await get<ApiManager>().getArtist(widget.artist["id"]);
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
  List _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    _load();
    super.initState();
  }

  void _load() async {
    List data = await get<ApiManager>().getAlbum(widget.album["id"]);
    setState(() {
      _songs = data;
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
              child: ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  var song = _songs[index];
                  return GenCard(
                    title: song["title"] ?? "Unknown Song", 
                    subtitle: "ID ${song['id'] ?? '?'}",
                    icon: Icons.album, 
                    onClick: () {
                      print("Seleccionaste la cancion: ${song["title"]} con id ${song['id']}");
                      get<AudioManager>().play(song["id"]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Pantalla de Ajustes", style: TextStyle(fontSize: 24, color: Colors.grey)),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final ApiManager api;
  const MyHomePage({super.key, required this.api, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _text = 'You have pushed the button this many times:'; 

  void _incrementCounter() async {

    Map data = await widget.api.ping();
    setState(() {         
      _text = "Version ${data['version']}";
      _counter++;
    });
      // This call to setState tells the Flutter framework that something hasThe Render (build() method): Keep this method completely "dumb". It should contain zero network or data-parsing logic and only return the visual tree based on whatever currently exists in the State.
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //The Render (build() method): Keep this method completely "dumb". It should contain zero network or data-parsing logic and only return the visual tree based on whatever currently exists in the State.
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            Text(_text),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
