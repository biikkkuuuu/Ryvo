import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app/app/theme_controller.dart';
import 'package:music_app/features/player/player_screen.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/repositories/music_repository.dart';
import 'package:music_app/features/artist/artist_profile_screen.dart';
import 'package:music_app/theme/app_theme.dart';
import 'package:music_app/widgets/song_playlist_picker.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final MusicRepository _repository = MusicRepository();

  List<Song> _searchResults = [];
  List<SearchArtistResult> _fullSearchArtists = [];
  List<Song> _songSuggestions = [];
  List<SearchArtistResult> _artistSuggestions = [];
  List<SearchPlaylistResult> _playlistSuggestions = [];

  bool _loading = false;
  bool _searching = false;
  List<String> _searchHistory = [];

  static const String _searchHistoryKey = 'ryvo_search_history';
  static const int _maxSearchHistory = 10;
  Timer? _debounce;

  final List<Map<String, dynamic>> _browseCategories = [
    {
      'title': 'Pop Hits',
      'color': const Color(0xFF1E3264),
      'icon': Icons.music_note_rounded,
    },
    {
      'title': 'Bollywood',
      'color': const Color(0xFFE91429),
      'icon': Icons.movie_filter_rounded,
    },
    {
      'title': 'Punjabi',
      'color': const Color(0xFFE8115B),
      'icon': Icons.flash_on_rounded,
    },
    {
      'title': 'Lo-Fi & Chill',
      'color': const Color(0xFF477D95),
      'icon': Icons.nightlight_round,
    },
    {
      'title': 'Hip-Hop',
      'color': const Color(0xFFBA5D07),
      'icon': Icons.speaker_group_rounded,
    },
    {
      'title': 'Indie Vibes',
      'color': const Color(0xFF8D67AB),
      'icon': Icons.graphic_eq_rounded,
    },
    {
      'title': 'Romantic',
      'color': const Color(0xFF8C1932),
      'icon': Icons.favorite_rounded,
    },
    {
      'title': 'Workout Beat',
      'color': const Color(0xFF006450),
      'icon': Icons.fitness_center_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_searchHistoryKey) ?? [];
    if (!mounted) return;
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _saveSearchHistory(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(_searchHistory);
    updated.removeWhere((item) => item.toLowerCase() == value.toLowerCase());
    updated.insert(0, value);

    if (updated.length > _maxSearchHistory) {
      updated.removeRange(_maxSearchHistory, updated.length);
    }

    await prefs.setStringList(_searchHistoryKey, updated);
    if (!mounted) return;
    setState(() {
      _searchHistory = updated;
    });
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
    if (!mounted) return;
    setState(() {
      _searchHistory = [];
    });
  }

  void _onQueryChanged() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _songSuggestions = [];
        _artistSuggestions = [];
        _playlistSuggestions = [];
        _searchResults = [];
        _fullSearchArtists = [];
        _searching = false;
      });
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchLiveSuggestions(query);
    });
  }

  Future<void> _fetchLiveSuggestions(String query) async {
    try {
      final results = await Future.wait([
        _repository.songSuggestions(query),
        _repository.artistSuggestions(query),
        _repository.playlistSuggestions(query),
      ]);

      if (!mounted || _controller.text.trim() != query) return;

      setState(() {
        _songSuggestions = results[0] as List<Song>;
        _artistSuggestions = results[1] as List<SearchArtistResult>;
        _playlistSuggestions = results[2] as List<SearchPlaylistResult>;
      });
    } catch (e) {
      debugPrint('Live search suggestions error: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    _focusNode.unfocus();
    _saveSearchHistory(q);

    setState(() {
      _loading = true;
      _searching = true;
    });

    try {
      final results = await Future.wait([
        _repository.search(q, pages: 2),
        _repository.artistSuggestions(q),
      ]);
      if (!mounted) return;
      setState(() {
        _searchResults = results[0] as List<Song>;
        _fullSearchArtists = results[1] as List<SearchArtistResult>;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  String decodeHtml(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#34;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#38;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#x27;', "'");
  }

  void _openSong(Song song, List<Song> playlist, int index) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: song.title,
          artist: song.artist,
          image: song.thumbnail,
          songId: song.id,
          playlist: playlist,
          currentIndex: index,
        ),
      ),
    );
  }

  void _openArtist(SearchArtistResult artist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtistProfileScreen(
          artistId: artist.id,
          artistName: artist.name,
          artistImage: artist.image,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme =
        RyvoThemeController.themes[RyvoThemeController.instance.selectedTheme];

    final isTyping = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: SpotifyColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'Search',
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Spotify Search Input Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: SpotifyColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: GoogleFonts.plusJakartaSans(
                    color: SpotifyColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _performSearch,
                  decoration: InputDecoration(
                    hintText: 'What do you want to play?',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: SpotifyColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: SpotifyColors.textSecondary,
                      size: 22,
                    ),
                    suffixIcon: isTyping
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: SpotifyColors.textSecondary,
                              size: 18,
                            ),
                            onPressed: () {
                              _controller.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Body Area
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: currentTheme.primary,
                      ),
                    )
                  : (_searching &&
                        (_searchResults.isNotEmpty ||
                            _fullSearchArtists.isNotEmpty))
                  ? _buildFullSearchResults(currentTheme.primary)
                  : isTyping
                  ? _buildLiveSuggestions(currentTheme.primary)
                  : _buildBrowseAndHistory(currentTheme.primary),
            ),

            // Space for Bottom Nav Bar & Mini Player
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BROWSE CATEGORIES & SEARCH HISTORY (DEFAULT VIEW)
  // ============================================================
  Widget _buildBrowseAndHistory(Color accentColor) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Recent Searches
        if (_searchHistory.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent searches',
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: _clearSearchHistory,
                child: Text(
                  'Clear',
                  style: GoogleFonts.plusJakartaSans(
                    color: SpotifyColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((query) {
              return GestureDetector(
                onTap: () {
                  _controller.text = query;
                  _performSearch(query);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: SpotifyColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        color: SpotifyColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        query,
                        style: GoogleFonts.plusJakartaSans(
                          color: SpotifyColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Browse All Header
        Text(
          'Browse all',
          style: GoogleFonts.plusJakartaSans(
            color: SpotifyColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 12),

        // 2-Column Spotify Category Cards
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 96,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _browseCategories.length,
          itemBuilder: (context, index) {
            final cat = _browseCategories[index];
            return GestureDetector(
              onTap: () {
                _controller.text = cat['title'] as String;
                _performSearch(cat['title'] as String);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cat['color'] as Color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Text(
                      cat['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: Transform.rotate(
                        angle: 0.35,
                        child: Icon(
                          cat['icon'] as IconData,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // LIVE SUGGESTIONS
  // ============================================================
  Widget _buildLiveSuggestions(Color accentColor) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_songSuggestions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Songs',
              style: GoogleFonts.plusJakartaSans(
                color: SpotifyColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ...List.generate(_songSuggestions.length, (index) {
            final song = _songSuggestions[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: song.thumbnail.isNotEmpty
                      ? Image.network(song.thumbnail, fit: BoxFit.cover)
                      : Container(color: SpotifyColors.surfaceElevated),
                ),
              ),
              title: Text(
                decodeHtml(song.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                decodeHtml(song.artist),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              onTap: () => _openSong(song, _songSuggestions, index),
            );
          }),
        ],

        if (_artistSuggestions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Artists',
              style: GoogleFonts.plusJakartaSans(
                color: SpotifyColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ..._artistSuggestions.map((artist) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 22,
                backgroundImage: artist.image.isNotEmpty
                    ? NetworkImage(artist.image)
                    : null,
                backgroundColor: SpotifyColors.surfaceElevated,
                child: artist.image.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: SpotifyColors.textSecondary,
                      )
                    : null,
              ),
              title: Text(
                decodeHtml(artist.name),
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Artist',
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              onTap: () => _openArtist(artist),
            );
          }),
        ],

        if (_playlistSuggestions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Playlists',
              style: GoogleFonts.plusJakartaSans(
                color: SpotifyColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ..._playlistSuggestions.map((playlist) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: playlist.image.isNotEmpty
                      ? Image.network(playlist.image, fit: BoxFit.cover)
                      : Container(color: SpotifyColors.surfaceElevated),
                ),
              ),
              title: Text(
                decodeHtml(playlist.name),
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Playlist',
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                _controller.text = playlist.name;
                _performSearch(playlist.name);
              },
            );
          }),
        ],
      ],
    );
  }

  // ============================================================
  // FULL SEARCH RESULTS VIEW
  // ============================================================
  Widget _buildFullSearchResults(Color accentColor) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _fullSearchArtists.length + _searchResults.length,
      itemBuilder: (context, index) {
        if (index < _fullSearchArtists.length) {
          final artist = _fullSearchArtists[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 2),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: SpotifyColors.surfaceElevated,
              backgroundImage: artist.image.isNotEmpty
                  ? NetworkImage(artist.image)
                  : null,
              child: artist.image.isEmpty
                  ? const Icon(Icons.person, color: SpotifyColors.textSecondary)
                  : null,
            ),
            title: Text(
              decodeHtml(artist.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: SpotifyColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Artist',
              style: GoogleFonts.plusJakartaSans(
                color: SpotifyColors.textSecondary,
                fontSize: 12,
              ),
            ),
            onTap: () => _openArtist(artist),
          );
        }
        final song = _searchResults[index - _fullSearchArtists.length];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 48,
              height: 48,
              child: song.thumbnail.isNotEmpty
                  ? Image.network(song.thumbnail, fit: BoxFit.cover)
                  : Container(color: SpotifyColors.surfaceElevated),
            ),
          ),
          title: Text(
            decodeHtml(song.title),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: SpotifyColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            decodeHtml(song.artist),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: SpotifyColors.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: SpotifyColors.textSecondary,
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
          onTap: () => _openSong(song, _searchResults, index),
        );
      },
    );
  }
}
