import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/app/theme_controller.dart';
import 'package:music_app/features/account/account_screen.dart';
import 'package:music_app/features/player/player_screen.dart';
import 'package:music_app/features/playlist/playlist_screen.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/library_service.dart';
import 'package:music_app/services/download_service.dart';
import 'package:music_app/theme/app_theme.dart';
import 'package:music_app/widgets/song_playlist_picker.dart';

enum LibrarySongsType { liked, recent, downloads }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Song> _likedSongs = [];
  List<Song> _recentlyPlayed = [];
  List<String> _playlistNames = [];
  bool _loading = true;
  int _selectedFilterIndex = 0;

  final List<String> _filters = ['All', 'Playlists', 'Liked Songs', 'Downloads', 'Recent'];

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    await LibraryService.instance.init();
    final liked = await LibraryService.instance.getLikedSongs();
    final recent = await LibraryService.instance.getRecentlyPlayed();
    final playlists = await LibraryService.instance.getPlaylistNames();

    if (!mounted) return;
    setState(() {
      _likedSongs = liked;
      _recentlyPlayed = recent;
      _playlistNames = playlists;
      _loading = false;
    });
  }

  void _openLikedSongs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibrarySongsScreen(
          title: 'Liked Songs',
          songs: _likedSongs,
          type: LibrarySongsType.liked,
        ),
      ),
    ).then((_) => _loadLibrary());
  }

  void _openRecentlyPlayed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibrarySongsScreen(
          title: 'Recently Played',
          songs: _recentlyPlayed,
          type: LibrarySongsType.recent,
        ),
      ),
    ).then((_) => _loadLibrary());
  }

  Future<void> _createNewPlaylist() async {
    String playlistName = '';
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: SpotifyColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Give your playlist a name',
            style: GoogleFonts.plusJakartaSans(
              color: SpotifyColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: SpotifyColors.textPrimary),
            onChanged: (value) => playlistName = value,
            decoration: InputDecoration(
              hintText: 'My Playlist #1',
              hintStyle: const TextStyle(color: SpotifyColors.textMuted),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: SpotifyColors.green)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, playlistName.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: SpotifyColors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text('Create', style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
      await LibraryService.instance.createPlaylist(name);
      await _loadLibrary();
    }
  }

  void _confirmDeletePlaylist(String playlistName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpotifyColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Playlist', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$playlistName"? This action cannot be undone.', style: GoogleFonts.plusJakartaSans(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await LibraryService.instance.deletePlaylist(playlistName);
              _loadLibrary(); 
            },
            child: Text('Delete', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = RyvoThemeController.themes[RyvoThemeController.instance.selectedTheme];

    return Scaffold(
      backgroundColor: SpotifyColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
                    },
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: SpotifyColors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: currentTheme.primary.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: const Icon(Icons.person_rounded, color: SpotifyColors.textPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Your Library',
                    style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const Spacer(),
                  IconButton(
                    splashRadius: 22,
                    icon: const Icon(Icons.add_rounded, color: SpotifyColors.textPrimary, size: 28),
                    onPressed: _createNewPlaylist,
                  ),
                ],
              ),
            ),

            // Filter Chips
            SizedBox(
              height: 34,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilterIndex == index;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() { _selectedFilterIndex = index; });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? currentTheme.primary : SpotifyColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _filters[index],
                        style: GoogleFonts.plusJakartaSans(
                          color: isSelected ? Colors.black : SpotifyColors.textPrimary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Library List Content
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: currentTheme.primary))
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Pinned: Liked Songs Card
                        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: Container(
                              width: 54, height: 54,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 26),
                            ),
                            title: Text('Liked Songs', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                            subtitle: Text('Playlist • ${_likedSongs.length} songs', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 13)),
                            onTap: _openLikedSongs,
                          ),
                          
                        // Naya: Downloaded Songs Card (LIVE REACTIVE)
                        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 3)
                          ValueListenableBuilder<List<Song>>(
                            valueListenable: DownloadService.instance.downloadedSongsNotifier,
                            builder: (context, downloadsList, _) {
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                leading: Container(
                                  width: 54, height: 54,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF1DB954), Color(0xFF0F5927)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.offline_pin_rounded, color: Colors.white, size: 26),
                                ),
                                title: Text('Downloads', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                                subtitle: Text('Offline • ${downloadsList.length} songs', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 13)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LibrarySongsScreen(
                                        title: 'Downloads',
                                        songs: downloadsList,
                                        type: LibrarySongsType.downloads,
                                      ),
                                    ),
                                  ).then((_) => _loadLibrary());
                                },
                              );
                            }
                          ),

                        // Pinned: Recently Played Card
                        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 4)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: Container(
                              width: 54, height: 54,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [currentTheme.primaryDark, currentTheme.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.history_rounded, color: Colors.white, size: 26),
                            ),
                            title: Text('Recently Played', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                            subtitle: Text('History', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 13)),
                            onTap: _openRecentlyPlayed,
                          ),

                        // Custom User Playlists
                        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1)
                          ..._playlistNames.map((name) {
                            return FutureBuilder<List<Song>>(
                              future: LibraryService.instance.getPlaylistSongs(name),
                              builder: (context, snapshot) {
                                final songs = snapshot.data ?? [];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  leading: Container(
                                    width: 54, height: 54,
                                    decoration: BoxDecoration(color: SpotifyColors.surfaceElevated, borderRadius: BorderRadius.circular(6)),
                                    child: songs.isNotEmpty && songs.first.thumbnail.isNotEmpty
                                        ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(songs.first.thumbnail, fit: BoxFit.cover))
                                        : const Icon(Icons.music_note_rounded, color: SpotifyColors.textSecondary, size: 26),
                                  ),
                                  title: Text(name, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                                  subtitle: Text('Playlist • ${songs.length} songs', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 13)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 20),
                                    onPressed: () => _confirmDeletePlaylist(name),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PlaylistScreen(
                                          playlistName: name,
                                          subtitle: 'Created by you',
                                          icon: Icons.queue_music_rounded,
                                          songs: songs,
                                        ),
                                      ),
                                    ).then((_) => _loadLibrary()); 
                                  },
                                );
                              },
                            );
                          }),
                      ],
                    ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LIBRARY SONGS SCREEN (FOR LIKED SONGS, DOWNLOADS & RECENTLY PLAYED)
// ============================================================
class LibrarySongsScreen extends StatefulWidget {
  final String title;
  final List<Song> songs;
  final LibrarySongsType type;

  const LibrarySongsScreen({
    super.key,
    required this.title,
    required this.songs,
    required this.type,
  });

  @override
  State<LibrarySongsScreen> createState() => _LibrarySongsScreenState();
}

class _LibrarySongsScreenState extends State<LibrarySongsScreen> {
  late List<Song> _songs;

  @override
  void initState() {
    super.initState();
    _songs = List.from(widget.songs);
  }

  String decodeHtml(String text) {
    return text.replaceAll('&quot;', '"').replaceAll('&#34;', '"').replaceAll('&amp;', '&').replaceAll('&#38;', '&').replaceAll('&#39;', "'").replaceAll('&apos;', "'").replaceAll('&lt;', '<').replaceAll('&gt;', '>');
  }

  void _openSong(int index) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: _songs[index].title,
          artist: _songs[index].artist,
          image: _songs[index].thumbnail,
          songId: _songs[index].id,
          playlist: _songs,
          currentIndex: index,
        ),
      ),
    ).then((_) {
      if (mounted && widget.type == LibrarySongsType.downloads) {
        setState(() {
          _songs = DownloadService.instance.downloadedSongs;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpotifyColors.background,
      appBar: AppBar(
        backgroundColor: SpotifyColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
      ),
      body: _songs.isEmpty
          ? Center(child: Text('No tracks found in ${widget.title}', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 14)))
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 48, height: 48,
                      child: song.thumbnail.isNotEmpty ? Image.network(song.thumbnail, fit: BoxFit.cover) : Container(color: SpotifyColors.surfaceElevated),
                    ),
                  ),
                  title: Text(decodeHtml(song.title), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(decodeHtml(song.artist), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert_rounded, color: SpotifyColors.textSecondary, size: 20),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: SpotifyColors.surfaceElevated,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                        builder: (_) => SongPlaylistPicker(song: song),
                      ).then((_) {
                        if (widget.type == LibrarySongsType.downloads) {
                          setState(() {
                            _songs = DownloadService.instance.downloadedSongs;
                          });
                        }
                      });
                    },
                  ),
                  onTap: () => _openSong(index),
                );
              },
            ),
    );
  }
}