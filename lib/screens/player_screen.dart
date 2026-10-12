import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song_models.dart';
import '../services/auth_service.dart';

const _playerGreen = Color(0xFF678B55);
const _playerInk = Color(0xFF27312B);
const _playerCream = Color(0xFFFFFDF5);

class PlayerScreen extends StatefulWidget {
  final List<SongModel> playlist;
  final int initialIndex;

  const PlayerScreen({
    super.key,
    required this.playlist,
    required this.initialIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final AudioPlayer _audioPlayer;
  late int _currentIndex;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool _isLoadingSong = true;
  bool _isPlaying = false;

  SongModel get _currentSong => widget.playlist[_currentIndex];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _currentIndex = widget.initialIndex
        .clamp(0, widget.playlist.isEmpty ? 0 : widget.playlist.length - 1)
        .toInt();
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        _isLoadingSong =
            state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
      });
      if (state.processingState == ProcessingState.completed) {
        _playSong((_currentIndex + 1) % widget.playlist.length);
      }
    });
    if (widget.playlist.isNotEmpty) _playSong(_currentIndex);
  }

  Future<void> _playSong(int index) async {
    if (widget.playlist.isEmpty) return;
    setState(() {
      _currentIndex = index;
      _isLoadingSong = true;
    });
    try {
      await _audioPlayer.setUrl(widget.playlist[index].url);
      await _audioPlayer.play();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingSong = false;
        _isPlaying = false;
      });
      _showMessage('Không thể phát bài hát này: $error');
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (error) {
      if (mounted) _showMessage('Không thể điều khiển trình phát: $error');
    }
  }

  Future<void> _toggleLike(SongModel song) async {
    final wasLiked = song.likedByUsers.contains(AuthService.currentUser);
    setState(() {
      if (wasLiked) {
        song.likedByUsers.remove(AuthService.currentUser);
      } else {
        song.likedByUsers.add(AuthService.currentUser);
      }
    });
    try {
      await MusicHiveService.updateSong(song);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (wasLiked) {
          song.likedByUsers.add(AuthService.currentUser);
        } else {
          song.likedByUsers.remove(AuthService.currentUser);
        }
      });
      _showMessage('Không thể lưu bài hát yêu thích: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.playlist.isEmpty) {
      return Scaffold(
        backgroundColor: _playerCream,
        appBar: AppBar(backgroundColor: _playerCream),
        body: const Center(child: Text('Danh sách phát đang trống.')),
      );
    }

    final song = _currentSong;
    final isLiked = song.likedByUsers.contains(AuthService.currentUser);
    return Scaffold(
      backgroundColor: _playerCream,
      appBar: AppBar(
        backgroundColor: _playerCream,
        foregroundColor: _playerInk,
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'ĐANG PHÁT TỪ',
              style: TextStyle(
                color: _playerGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            Text(
              'Danh sách bài hát',
              style: TextStyle(
                color: _playerInk,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 36,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        song.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFFFF3C4),
                          child: const Icon(
                            Icons.music_note_rounded,
                            size: 90,
                            color: _playerGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _playerInk,
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: isLiked ? 'Bỏ yêu thích' : 'Yêu thích',
                        onPressed: () => _toggleLike(song),
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.deepOrange : _playerGreen,
                          size: 29,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<Duration?>(
                    stream: _audioPlayer.durationStream,
                    builder: (context, durationSnapshot) {
                      final duration = durationSnapshot.data ?? Duration.zero;
                      final max = duration.inMilliseconds.toDouble();
                      return StreamBuilder<Duration>(
                        stream: _audioPlayer.positionStream,
                        builder: (context, positionSnapshot) {
                          final position =
                              positionSnapshot.data ?? Duration.zero;
                          final sliderMax = max > 0 ? max : 1.0;
                          final sliderValue = position.inMilliseconds
                              .toDouble()
                              .clamp(0.0, sliderMax);
                          return Column(
                            children: [
                              Slider(
                                activeColor: _playerGreen,
                                inactiveColor: const Color(0xFFDDE3D3),
                                min: 0,
                                max: sliderMax,
                                value: sliderValue,
                                onChanged: max <= 0
                                    ? null
                                    : (value) => _audioPlayer.seek(
                                        Duration(milliseconds: value.toInt()),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Bài trước',
                        iconSize: 38,
                        color: _playerInk,
                        onPressed: () => _playSong(
                          (_currentIndex - 1 + widget.playlist.length) %
                              widget.playlist.length,
                        ),
                        icon: const Icon(Icons.skip_previous_rounded),
                      ),
                      const SizedBox(width: 22),
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _playerGreen,
                            foregroundColor: Colors.white,
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: _togglePlayPause,
                          child: _isLoadingSong
                              ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Icon(
                                  _isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 42,
                                ),
                        ),
                      ),
                      const SizedBox(width: 22),
                      IconButton(
                        tooltip: 'Bài tiếp theo',
                        iconSize: 38,
                        color: _playerInk,
                        onPressed: () => _playSong(
                          (_currentIndex + 1) % widget.playlist.length,
                        ),
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Đang phát cho ${AuthService.currentUser}',
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '${duration.inMinutes}:$seconds';
  }
}
