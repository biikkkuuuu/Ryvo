import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/app/theme_controller.dart';
import 'package:music_app/features/player/player_screen.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/library_service.dart';
import 'package:music_app/theme/app_theme.dart';
import 'package:music_app/widgets/song_playlist_picker.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistName;
  final String subtitle;
  final IconData icon;
  final List<Song> songs; // Initial songs

  const PlaylistScreen({
    super.key,
    required this.playlistName,
    required this.subtitle,
    required this.icon,
    required this.songs,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late List<Song> _songs;

  @override
  void initState() {
    super.initState();
    _songs = widget.songs; // Use initially passed songs for zero loading time
  }

  // Refreshes the song list when a song is removed from the action menu
  Future<void> _refreshSongs() async {
    final updatedSongs = await LibraryService.instance.getPlaylist(widget.playlistName);
    if(mounted) {
      setState(() {
        _songs = updatedSongs;
      });
    }
  }

  String decodeHtml(String text) {
    return text.replaceAll('&quot;', '"').replaceAll('&#34;', '"').replaceAll('&amp;', '&').replaceAll('&#38;', '&').replaceAll('&#39;', "'").replaceAll('&apos;', "'").replaceAll('&lt;', '<').replaceAll('&gt;', '>');
  }

  void _openSong(BuildContext context, int index, List<Song> playlistToPlay) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: playlistToPlay[index].title,
          artist: playlistToPlay[index].artist,
          image: playlistToPlay[index].thumbnail,
          songId: playlistToPlay[index].id,
          playlist: playlistToPlay,
          currentIndex: index,
        ),
      ),
    );
  }

  void _shuffleAndPlay() {
    if (_songs.isEmpty) return;
    HapticFeedback.lightImpact();
    // Create a shuffled copy of the playlist
    final shuffled = List<Song>.from(_songs)..shuffle();
    _openSong(context, 0, shuffled);
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = RyvoThemeController.themes[RyvoThemeController.instance.selectedTheme];

    return Scaffold(
      backgroundColor: SpotifyColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Collapsible Ambient Header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: SpotifyColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [currentTheme.primaryDark.withValues(alpha: 0.6), SpotifyColors.background],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          color: SpotifyColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
                          ],
                        ),
                        // FIX: Dynamic Playlist Cover Art instead of hardcoded Icon
                        child: _songs.isNotEmpty && _songs.first.thumbnail.isNotEmpty
                            ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(_songs.first.thumbnail, fit: BoxFit.cover))
                            : Icon(widget.icon, color: currentTheme.primary, size: 54),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          decodeHtml(widget.playlistName),
                          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${decodeHtml(widget.subtitle)} • ${_songs.length} songs',
                        style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Play All / Shuffle Button Row
          if (_songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tracks', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                    Row(
                      children: [
                        // FIX: Add Shuffle functionality
                        IconButton(
                          splashRadius: 24,
                          icon: const Icon(Icons.shuffle_rounded, color: SpotifyColors.textPrimary, size: 26),
                          onPressed: _shuffleAndPlay,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _openSong(context, 0, _songs),
                          child: Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: currentTheme.primary,
                              boxShadow: [BoxShadow(color: currentTheme.primary.withValues(alpha: 0.35), blurRadius: 14)],
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Track List
          if (_songs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No songs in this playlist.', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 14))),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _songs[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 46, height: 46,
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
                          builder: (_) => SongPlaylistPicker(
                            song: song,
                            currentPlaylistName: widget.playlistName, // Pass the playlist name so it can be removed
                            onActionCompleted: _refreshSongs, // Callback to refresh UI if deleted
                          ),
                        );
                      },
                    ),
                    onTap: () => _openSong(context, index, _songs),
                  );
                },
                childCount: _songs.length,
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 60),
          ),
        ],
      ),
    );
  }
}