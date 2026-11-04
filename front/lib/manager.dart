import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart';
import 'dart:convert';

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
}

class AudioManager {
  final Player player;
  String baseUrl;

  AudioManager(this.baseUrl): player = Player(configuration: const PlayerConfiguration(bufferSize: 32 * 1024 * 1024));

  Future<void> play(String id) async {
    try {
      var url = Uri.http(baseUrl, "/api/stream", {"id": id});
      final sw = Stopwatch()..start();
      await player.open(Media(url.toString()));
      print("setUrl: ${sw.elapsedMilliseconds} ms");
      print("play() devuelto: ${sw.elapsedMilliseconds} ms");
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
