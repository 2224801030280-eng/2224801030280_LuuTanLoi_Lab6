import 'package:hive_flutter/hive_flutter.dart';

import '../models/song_models.dart';

class AuthService {
  static String currentUser = '';
}

class MusicHiveService {
  static const String boxName = 'songsBox';

  static Box get _box => Hive.box(boxName);

  static Future<List<SongModel>> getSongs() async {
    final sampleSongs = [
      SongModel(
        id: '1',
        title: 'SoundHelix Song 1',
        artist: 'SoundHelix',
        thumbnail: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      ),
      SongModel(
        id: '2',
        title: 'SoundHelix Song 2',
        artist: 'SoundHelix',
        thumbnail: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      ),
      SongModel(
        id: '3',
        title: 'SoundHelix Song 3',
        artist: 'SoundHelix',
        thumbnail: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      ),
    ];

    if (_box.isEmpty) {
      await _box.putAll({
        for (final song in sampleSongs) song.id: song.toMap(),
      });
    } else {
      for (final sample in sampleSongs) {
        final stored = _box.get(sample.id);
        if (stored is Map &&
            stored['url'].toString().contains('actions.google.com/sounds/')) {
          final song = SongModel.fromMap(stored);
          song.title = sample.title;
          song.artist = sample.artist;
          song.url = sample.url;
          await updateSong(song);
        }
      }
    }

    return _box.values
        .map((value) => SongModel.fromMap(value as Map<dynamic, dynamic>))
        .toList();
  }

  static Future<void> updateSong(SongModel song) async {
    await _box.put(song.id, song.toMap());
  }

  static Future<void> addSong(SongModel song) async {
    if (_box.containsKey(song.id)) {
      throw StateError('A song with this id already exists.');
    }
    await _box.put(song.id, song.toMap());
  }

  static Future<void> deleteSong(String id) async {
    await _box.delete(id);
  }
}
