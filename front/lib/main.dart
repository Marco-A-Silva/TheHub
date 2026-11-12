import 'package:flutter/gestures.dart';
import 'package:front/components.dart' show HubTab, MusicPlayer;
import 'package:front/views/discover.dart';
import 'package:media_kit/media_kit.dart';
import 'package:front/views/atrists.dart';
import 'package:front/views/search.dart';
import 'package:flutter/material.dart';
import 'package:front/manager.dart';


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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purpleAccent, brightness: Brightness.dark),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black12, scrolledUnderElevation: 0, elevation: 0),
      ),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      builder: ((context, child) => Column(
        children: [
          Expanded(child: child ?? const SizedBox.shrink()),
          const MusicPlayer(),
        ],
      )),
      home: const HomePage(),
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
  final List<HubTab> _tabs = [
    HubTab(title: 'Discover', icon: Icons.arrow_circle_down, view: const DiscoverView()),
    HubTab(title: 'Search', icon: Icons.search, view: const SearchView()),
    HubTab(title: 'Artists', icon: Icons.person, view: const ArtistsView()),
    HubTab(title: 'Settings', icon: Icons.settings, view: SettingsView())
  ];

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_tabs[_curdex].icon, color: Colors.purple),
            const SizedBox(width: 10),
            Text(_tabs[_curdex].title),
          ]
        ),
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.2,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.black12,
              child: const Padding(
                padding: EdgeInsets.only(top: 12.5 ,bottom: 12.5),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_music, size: 30 , color: Colors.purple),
                        Text("The Hub", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    )
                  ],
                ),
              ),
            ),

            for (int i = 0; i < _tabs.length; i++)
              ListTile(
                leading: Icon(_tabs[i].icon),
                title: Text(_tabs[i].title),
                selected: _curdex == i,
                selectedColor: Colors.purpleAccent, 
                onTap: () {
                  setState(() => _curdex = i);
                  Navigator.pop(context);
                },
              ),

            const Spacer(),
          ],
        ),
      ),
      body: IndexedStack(
        index: _curdex,
        children: _tabs.map((t) => t.view).toList(),
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
