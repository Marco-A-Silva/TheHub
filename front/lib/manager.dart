import 'package:media_kit/media_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'dart:collection';
import 'dart:convert';

/*---------------------------------------------------------------------------------*/
//Data classes
class Song {
  final String id;
  final String title;
  final String artist;
  final String album;

  Song({required this.id, required this.title, required this.artist, required this.album});

  factory Song.fromMap(Map<String, dynamic> map, {String defaultArtist = 'Artista desconocido'}) {
    return Song(
      id: map['id'].toString(),
      title: map['title'] ?? map['name'] ?? 'Sin título',
      artist: map['artist'] ?? defaultArtist,
      album: map["album"] ?? 'Sin Album',
    );
  }
}


/*---------------------------------------------------------------------------------*/
//Global instances
final get = GetIt.instance;

void configureDependencies() {
  get.registerSingleton<ApiManager>(ApiManager("100.99.217.107:3000"));
  get.registerLazySingleton<AudioManager>(() => AudioManager("100.99.217.107:3000"));
}
/*--------------------------------------------------------------------------------*/
//ApiManager

class ApiManager {
  final String baseUrl;
  final http.Client client;

  ApiManager(this.baseUrl): client = http.Client();

  Future<Map> ping() async {
    Map decodedResponse = {};
    try { 
      var url = Uri.http(baseUrl, "/api/ping");
      var response = await client.get(url);

      if (response.statusCode == 200) {
        decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      } else {
        print('Server rejected the request with status code: ${response.statusCode}');

      }
    } catch (e) {
      print('Failed to reach the server. Is the VPN connected? Error: $e');
    }
    return decodedResponse;
  }

  Future<List> getSimilarSongs(String id) async {
    List similarSongs = [];
    try {
      var url = Uri.http(baseUrl, "/api/similarSongs", {"id": id});
      var response = await client.get(url);

      if (response.statusCode == 200) {
        similarSongs = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      } else {
        print("Server rejected the request with status code ${response.statusCode}");
      }
    } catch (e) {
      print('Failed to reach the server. Is the VPN connected? Error: $e');
    }
    return similarSongs;

  }

  Future<List> getArtists() async {
    List artists = [];
    try {
      var url = Uri.http(baseUrl, "/api/getArtists");
      var response = await client.get(url);

        if (response.statusCode == 200) {
          artists = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        } else {
          print('Server rejected the request with status code: ${response.statusCode}');
        }
    } catch (e) {
      print('Failed to reach the server. Is the VPN connected? Error: $e');
    }
    return artists;
  }

  Future<List> getArtist(String id) async {
    List albums = [];
    try {
      var url = Uri.http(baseUrl, "/api/getArtist", {"id": id});
      var response = await client.get(url);

      if (response.statusCode == 200) {
        albums = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      } else {
        print("Server rejected the request with status code ${response.statusCode}");
      }
    } catch (e) {
      print('Failed to reach the server. Is the VPN connected? Error: $e');
    }
    return albums;
  }

  Future<List> getAlbum(String id) async {
    List songs = [];
    try { 
      var url = Uri.http(baseUrl, "/api/getAlbum", {"id": id});
      var response = await client.get(url);
      
      if (response.statusCode == 200) {
        songs = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      } else {
        print("Server rejected the request with status code ${response.statusCode}");
      }
    } catch (e) {
      print("Failed to reach the serve. Is the VPN connected? Error: $e");
    }
    return songs;
  }

  Future<Map> search(String query) async {
    Map<String, dynamic> results = {};
    try {
      var url = Uri.http(baseUrl, "/api/search", {"q": query});
      var response = await client.get(url);
      
      if (response.statusCode == 200) {
        results = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        print("Server rejected the request with status code ${response.statusCode}");
      }
    } catch (e) {
      print("Failed to reach the serve. Is the VPN connected? Error: $e");
    }
    return results;
  }
}

/*--------------------------------------------------------------------------------*/
//AudioManager

class AudioManager extends ChangeNotifier{
  final Player player;
  String baseUrl;
  List<Song> queue = [];
  ListQueue<Song> extraQueue = ListQueue();
  int index = -1;

  Song? get currentSong {
    if (index >= 0 && index < queue.length) {
      return queue[index];
    }
    return null;
  }

  AudioManager(this.baseUrl): player = Player(
    configuration: const PlayerConfiguration(bufferSize: 32 * 1024 * 1024)
  ) {
      player.stream.completed.listen((completed) {
        if (completed) {
          next();
        }
      });
  }

  Future<void> fillQueue(String id) async {
    try {
      List data = await get<ApiManager>().getSimilarSongs(id);
      List<Song> similarSongs = data.map((s) => Song.fromMap(s as Map<String, dynamic>)).toList();
      List<Song> newSongs = similarSongs.where((nueva) => !queue.any((existente) => existente.id == nueva.id)).toList();
      queue.addAll(newSongs);
    } catch (e) {
      print("Error llenando la cola: $e");
    }
  }

  Future<void> play(String id) async {
    try {
      var url = Uri.http(baseUrl, "/api/stream", {"id": id});
      await player.open(Media(url.toString()));
    }catch (e) {
      print("Error $e");
    }
  }

  Future<void> albumPlay(List<Song> songs, int ind) async {
    try {
      final clicked = songs[ind];
      final posEnCola = queue.indexWhere((s) => s.id == clicked.id);

      if (posEnCola >= 0) { index = posEnCola; } else {
        queue = List.of(songs);       
        index = ind;
        extraQueue.clear();
      }

      notifyListeners();
      await play(queue[index].id);
    } catch (e) {
      print("Error $e");
    }
  }

  Future<void> next() async {
    try {
      index += 1;
      if (extraQueue.isNotEmpty){
        var next = extraQueue.removeFirst();
        queue.insert(index, next);
      } 
      if (index >= queue.length - 2) {
        await fillQueue(queue[index-1].id);
      }
      print(queue.map((q) => q.title).toList());
      if (index < queue.length) {
        notifyListeners();
        await play(queue[index].id);
        return;
      } else {
        index = queue.length - 1;
        print("End of Queue");
      }
    } catch (e) {
      print("Error $e");
    }
  }

  Future<void> prev() async {
    try {
      index -=1;
      notifyListeners();
      await play(queue[index].id);
    } catch (e) {
      print("Error $e");
    }
  }

  Future<void> toggle() async {
    try {
      if (player.state.playing) {
        await player.pause();
      } else { await player.play(); }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> stop() async {
    try {
      await player.stop();
    } catch (e) {
      print("Error: $e");
    }
  }
}
