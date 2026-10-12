import 'package:flutter/material.dart';

import '../models/song_models.dart';
import '../services/auth_service.dart';
import 'player_screen.dart';

const _ink = Color(0xFF27312B);
const _green = Color(0xFF678B55);
const _cream = Color(0xFFFFFDF5);
const _butter = Color(0xFFFFF3C4);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SongModel> _songs = [];
  final TextEditingController _searchController = TextEditingController();
  bool _showOnlyLiked = false;
  bool _isLoading = true;

  List<SongModel> get _filteredSongs {
    final query = _searchController.text.trim().toLowerCase();
    return _songs.where((song) {
      final matchesQuery =
          song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
      final matchesTab =
          !_showOnlyLiked || song.likedByUsers.contains(AuthService.currentUser);
      return matchesQuery && matchesTab;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    try {
      final songs = await MusicHiveService.getSongs();
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Không thể tải danh sách bài hát: $error');
    }
  }

  Future<void> _toggleLike(SongModel song) async {
    setState(() {
      if (song.likedByUsers.contains(AuthService.currentUser)) {
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
        if (song.likedByUsers.contains(AuthService.currentUser)) {
          song.likedByUsers.remove(AuthService.currentUser);
        } else {
          song.likedByUsers.add(AuthService.currentUser);
        }
      });
      _showMessage('Không thể lưu bài hát yêu thích: $error');
    }
  }

  Future<void> _showSongDialog({SongModel? song}) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: song?.title ?? '');
    final artistController = TextEditingController(text: song?.artist ?? '');
    final thumbnailController =
        TextEditingController(text: song?.thumbnail ?? '');
    final urlController = TextEditingController(text: song?.url ?? '');

    final result = await showDialog<SongModel>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        title: Text(song == null ? 'Thêm bài hát' : 'Chỉnh sửa bài hát'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _formField(titleController, 'Tên bài hát'),
                _formField(artistController, 'Nghệ sĩ'),
                _formField(thumbnailController, 'URL ảnh bìa', isUrl: true),
                _formField(urlController, 'URL audio (MP3)', isUrl: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _green),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                SongModel(
                  id: song?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                  title: titleController.text.trim(),
                  artist: artistController.text.trim(),
                  thumbnail: thumbnailController.text.trim(),
                  url: urlController.text.trim(),
                  likedByUsers: song?.likedByUsers,
                ),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    titleController.dispose();
    artistController.dispose();
    thumbnailController.dispose();
    urlController.dispose();
    if (result == null || !mounted) return;

    try {
      if (song == null) {
        await MusicHiveService.addSong(result);
      } else {
        await MusicHiveService.updateSong(result);
      }
      await _loadSongs();
      if (mounted) _showMessage(song == null ? 'Đã thêm bài hát.' : 'Đã cập nhật bài hát.');
    } catch (error) {
      if (mounted) _showMessage('Không thể lưu bài hát: $error');
    }
  }

  Widget _formField(
    TextEditingController controller,
    String label, {
    bool isUrl = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return 'Vui lòng nhập $label';
          if (isUrl) {
            final uri = Uri.tryParse(text);
            if (uri == null ||
                !uri.hasScheme ||
                (uri.scheme != 'https' && uri.scheme != 'http') ||
                uri.host.isEmpty) {
              return 'Vui lòng nhập URL http/https hợp lệ';
            }
          }
          return null;
        },
      ),
    );
  }

  Future<void> _deleteSong(SongModel song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        title: const Text('Xóa bài hát?'),
        content: Text('Bạn muốn xóa "${song.title}" khỏi thư viện?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await MusicHiveService.deleteSong(song.id);
      await _loadSongs();
      if (mounted) _showMessage('Đã xóa bài hát.');
    } catch (error) {
      if (mounted) _showMessage('Không thể xóa bài hát: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final songs = _filteredSongs;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GÓC ÂM NHẠC',
              style: TextStyle(
                color: _green,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Xin chào, ${AuthService.currentUser}',
              style: const TextStyle(
                color: _ink,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Thêm bài hát',
            onPressed: () => _showSongDialog(),
            icon: const Icon(Icons.add_circle_outline, color: _green, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: Container(
              decoration: BoxDecoration(
                color: _butter,
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhạc hay,\ntâm trạng tốt.',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 23,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Chọn một giai điệu cho hôm nay',
                          style: TextStyle(color: _ink, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.headphones_rounded, size: 34, color: _green),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm bài hát hoặc nghệ sĩ',
                prefixIcon: const Icon(Icons.search, color: _green),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              children: [
                _filterChip('Tất cả', !_showOnlyLiked, () {
                  setState(() => _showOnlyLiked = false);
                }),
                const SizedBox(width: 8),
                _filterChip('Yêu thích', _showOnlyLiked, () {
                  setState(() => _showOnlyLiked = true);
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Danh sách bài hát',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text('${songs.length} bài', style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _green))
                : songs.isEmpty
                    ? Center(
                        child: Text(
                          _showOnlyLiked
                              ? 'Bạn chưa có bài hát yêu thích.'
                              : 'Không tìm thấy bài hát nào.',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: songs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          final isLiked =
                              song.likedByUsers.contains(AuthService.currentUser);
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            child: ListTile(
                              contentPadding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  song.thumbnail,
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 54,
                                    height: 54,
                                    color: _butter,
                                    child: const Icon(Icons.music_note, color: _green),
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: isLiked ? 'Bỏ yêu thích' : 'Yêu thích',
                                    icon: Icon(
                                      isLiked ? Icons.favorite : Icons.favorite_border,
                                      color: isLiked ? Colors.deepOrange : Colors.black45,
                                    ),
                                    onPressed: () => _toggleLike(song),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: 'Tùy chọn bài hát',
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showSongDialog(song: song);
                                      } else {
                                        _deleteSong(song);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Chỉnh sửa'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => PlayerScreen(
                                    playlist: songs,
                                    initialIndex: index,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _green,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : _ink,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }
}
