import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/player/player_screen.dart';
import '../../models/song.dart';
import '../../repositories/music_repository.dart';
import 'package:music_app/theme/app_theme.dart';
import 'package:music_app/widgets/song_playlist_picker.dart';

class ArtistProfileScreen extends StatefulWidget {
  final String artistId;
  final String artistName;
  final String artistImage;

  const ArtistProfileScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    required this.artistImage,
  });

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  final MusicRepository _repository = MusicRepository();
  final ScrollController _scrollController = ScrollController();
  final List<Song> _songs = [];
  final Set<String> _songIds = {};

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _nextPage = 0;
  int? _total;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      _loadPage(loadMore: true);
    }
  }

  Future<void> _loadPage({bool loadMore = false}) async {
    if (loadMore && (_loading || _loadingMore || !_hasMore)) return;

    setState(() {
      if (loadMore) {
        _loadingMore = true;
      } else {
        _loading = true;
        _error = null;
      }
    });

    try {
      final result = await _repository.getArtistSongsPage(
        widget.artistId,
        page: _nextPage,
      );
      if (!mounted) return;

      final newSongs = <Song>[];
      for (final song in result.songs) {
        if (_songIds.add(song.id)) newSongs.add(song);
      }

      setState(() {
        _songs.addAll(newSongs);
        _total ??= result.total;
        _nextPage++;
        _hasMore =
            result.songs.isNotEmpty &&
            newSongs.isNotEmpty &&
            (_total == null || _songs.length < _total!);
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load this artist’s songs.';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _openSong(Song song, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: song.title,
          artist: song.artist,
          image: song.thumbnail,
          songId: song.id,
          playlist: _songs,
          currentIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: const Color(0xFF0B0B0B),
            title: Text(
              widget.artistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 72,
                      backgroundImage: widget.artistImage.isNotEmpty
                          ? NetworkImage(widget.artistImage)
                          : null,
                      child: widget.artistImage.isEmpty
                          ? const Icon(Icons.person, size: 64)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Artist',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Songs',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ?? 'No songs available',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white60),
                    ),
                    if (_error != null)
                      TextButton(
                        onPressed: _loadPage,
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == _songs.length) {
                  return _hasMore
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox(height: 120);
                }

                final song = _songs[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: song.thumbnail.isNotEmpty
                          ? Image.network(
                              song.thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _songPlaceholder(),
                            )
                          : _songPlaceholder(),
                    ),
                  ),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  // FIX: ADDED 3-DOT MENU TO ARTIST SCREEN
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: SpotifyColors.surfaceElevated,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => SongPlaylistPicker(song: song),
                      );
                    },
                  ),
                  onTap: () => _openSong(song, index),
                );
              }, childCount: _songs.length + 1),
            ),
        ],
      ),
    );
  }

  Widget _songPlaceholder() => Container(
    color: Colors.white10,
    child: const Icon(Icons.music_note, color: Colors.white54),
  );
}