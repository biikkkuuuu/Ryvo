import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/app/theme_controller.dart';
import 'package:music_app/features/account/account_screen.dart';
import 'package:music_app/features/library/library_screen.dart';
import 'package:music_app/features/player/player_screen.dart';
import 'package:music_app/features/playlist/playlist_screen.dart';
import 'package:music_app/features/search/search_screen.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/repositories/music_repository.dart';
import 'package:music_app/services/audio_service.dart';
import 'package:music_app/services/library_service.dart';
import 'package:music_app/theme/app_theme.dart';
import 'package:music_app/widgets/song_playlist_picker.dart';

String decodeHtml(String text) {
  return text.replaceAll('&quot;', '"').replaceAll('&#34;', '"').replaceAll('&amp;', '&').replaceAll('&#38;', '&').replaceAll('&#39;', "'").replaceAll('&apos;', "'").replaceAll('&lt;', '<').replaceAll('&gt;', '>');
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = RyvoThemeController.themes[RyvoThemeController.instance.selectedTheme];

    return PopScope(
      canPop: _currentNavIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentNavIndex != 0) setState(() => _currentNavIndex = 0);
      },
      child: Scaffold(
        backgroundColor: SpotifyColors.background,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentNavIndex,
              children: const [
                _HomeTabContent(),
                SearchScreen(),
                LibraryScreen(),
              ],
            ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SpotifyMiniPlayer(),
                  _buildBottomNavigationBar(currentTheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.85), Colors.black]),
        border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(index: 0, icon: Icons.home_rounded, unselectedIcon: Icons.home_outlined, label: 'Home', accentColor: accentColor),
              _buildNavItem(index: 1, icon: Icons.search_rounded, unselectedIcon: Icons.search_rounded, label: 'Search', accentColor: accentColor),
              _buildNavItem(index: 2, icon: Icons.library_music_rounded, unselectedIcon: Icons.library_music_outlined, label: 'Your Library', accentColor: accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon, required IconData unselectedIcon, required String label, required Color accentColor}) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentNavIndex = index);
      },
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? icon : unselectedIcon, color: isSelected ? SpotifyColors.textPrimary : SpotifyColors.textSecondary, size: 24),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.plusJakartaSans(color: isSelected ? SpotifyColors.textPrimary : SpotifyColors.textSecondary, fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _SpotifyMiniPlayer extends StatelessWidget {
  const _SpotifyMiniPlayer();

  @override
  Widget build(BuildContext context) {
    final audio = AudioService();

    return ValueListenableBuilder<Song?>(
      valueListenable: audio.currentSong,
      builder: (context, song, _) {
        if (song == null || song.id.trim().isEmpty || song.title == 'RYVO') {
            return const SizedBox.shrink();
        }
        
        final currentTheme = RyvoThemeController.themes[RyvoThemeController.instance.selectedTheme];

        return StreamBuilder<PlayerState>(
          stream: audio.playerStateStream,
          initialData: audio.player.playerState,
          builder: (context, snapshot) {
            final state = snapshot.data ?? audio.player.playerState;
            final isPlaying = state.playing && state.processingState != ProcessingState.completed;

            void openFullPlayer() {
              final currentSong = audio.currentSong.value;
              if (currentSong == null || currentSong.id.trim().isEmpty) return;
              final playbackQueue = List<Song>.from(audio.queue.value);
              final playlist = <Song>[currentSong, ...playbackQueue];
              Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(
                title: currentSong.title, artist: currentSong.artist, image: currentSong.thumbnail, songId: currentSong.id, playlist: playlist, currentIndex: 0,
              )));
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: GestureDetector(
                onTap: openFullPlayer,
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  width: 42, height: 42,
                                  child: song.thumbnail.trim().isEmpty
                                      ? Container(color: SpotifyColors.surfaceElevated, child: const Icon(Icons.music_note_rounded, color: SpotifyColors.textSecondary, size: 22))
                                      : Image.network(song.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: SpotifyColors.surfaceElevated, child: const Icon(Icons.music_note_rounded, color: SpotifyColors.textSecondary, size: 22))),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(decodeHtml(song.title), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(decodeHtml(song.artist), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w400)),
                                  ],
                                ),
                              ),
                              _MiniPlayerLikeButton(song: song),
                              IconButton(
                                splashRadius: 20,
                                onPressed: () async {
                                  HapticFeedback.selectionClick();
                                  if (isPlaying) await audio.pause(); else await audio.resume();
                                },
                                icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: SpotifyColors.textPrimary, size: 30),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0, right: 0, bottom: 0,
                          child: StreamBuilder<Duration>(
                            stream: audio.positionStream,
                            builder: (context, posSnapshot) {
                              final position = posSnapshot.data ?? Duration.zero;
                              final total = audio.totalDuration ?? Duration.zero;
                              final progress = (total.inMilliseconds > 0) ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0) : 0.0;
                              return LinearProgressIndicator(value: progress, minHeight: 2.5, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(currentTheme.primary));
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MiniPlayerLikeButton extends StatefulWidget {
  final Song song;
  const _MiniPlayerLikeButton({required this.song});
  @override
  State<_MiniPlayerLikeButton> createState() => _MiniPlayerLikeButtonState();
}

class _MiniPlayerLikeButtonState extends State<_MiniPlayerLikeButton> {
  bool _isLiked = false;
  @override
  void initState() {
    super.initState();
    _checkLiked();
  }
  @override
  void didUpdateWidget(covariant _MiniPlayerLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) _checkLiked();
  }
  void _checkLiked() => _isLiked = LibraryService.instance.isLiked(widget.song.id);
  Future<void> _toggleLike() async {
    HapticFeedback.selectionClick();
    if (_isLiked) await LibraryService.instance.removeLiked(widget.song.id); else await LibraryService.instance.addLiked(widget.song);
    if (mounted) setState(() => _isLiked = !_isLiked);
  }
  @override
  Widget build(BuildContext context) {
    final currentTheme = RyvoThemeController.themes[RyvoThemeController.instance.selectedTheme];
    return IconButton(
      splashRadius: 18,
      onPressed: _toggleLike,
      icon: Icon(_isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _isLiked ? currentTheme.primary : SpotifyColors.textSecondary, size: 22),
    );
  }
}

class _HomeTabContent extends StatefulWidget {
  const _HomeTabContent();
  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
  final MusicRepository _repository = MusicRepository();
  Map<String, List<Song>> _sections = {};
  List<Song> _recentlyPlayed = [];
  List<SearchPlaylistResult> _homePlaylists = [];
  List<SearchAlbumResult> _homeAlbums = [];
  List<dynamic> _radioStations = [];
  List<SearchPlaylistResult> _moodPlaylists = [];
  List<Map<String, String>> _discoverMixes = [];
  List<Map<String, String>> _topShows = [];

  String? _selectedMood;
  bool _loadingMoodPlaylists = false;
  bool _loadingRadio = false;

  static const List<Map<String, dynamic>> _moods = [
    {'label': 'Romantic', 'query': 'Romantic Hindi', 'icon': Icons.favorite_rounded},
    {'label': 'Sad', 'query': 'Sad Hindi', 'icon': Icons.nights_stay_rounded},
    {'label': 'Party', 'query': 'Party Hindi', 'icon': Icons.celebration_rounded},
    {'label': 'Chill', 'query': 'Chill Hindi', 'icon': Icons.spa_rounded},
    {'label': 'Workout', 'query': 'Workout Hindi', 'icon': Icons.fitness_center_rounded},
    {'label': 'Focus', 'query': 'Focus Hindi', 'icon': Icons.psychology_rounded},
  ];

  bool _loading = true;
  String? _error;
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'Music', 'Charts', 'Moods', 'Radio'];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    else if (hour < 17) return 'Good afternoon';
    else return 'Good evening';
  }

  Future<void> _loadMoodPlaylists(Map<String, dynamic> mood) async {
    final label = mood['label'] as String;
    final query = mood['query'] as String;
    setState(() { _selectedMood = label; _loadingMoodPlaylists = true; _moodPlaylists = []; });
    try {
      final playlists = await _repository.playlistSuggestions(query);
      if (!mounted || _selectedMood != label) return;
      setState(() { _moodPlaylists = playlists; _loadingMoodPlaylists = false; });
    } catch (_) {
      if (!mounted || _selectedMood != label) return;
      setState(() => _loadingMoodPlaylists = false);
    }
  }

  Future<void> _loadRadioStations() async {
    if (!mounted) return;
    setState(() => _loadingRadio = true);
    try {
      final songIds = <String>[];
      for (final song in _recentlyPlayed) {
        final id = song.id.trim();
        if (id.isNotEmpty && !songIds.contains(id)) songIds.add(id);
        if (songIds.length == 10) break;
      }
      if (songIds.length < 10) {
        for (final songs in _sections.values) {
          for (final song in songs) {
            final id = song.id.trim();
            if (id.isNotEmpty && !songIds.contains(id)) songIds.add(id);
            if (songIds.length == 10) break;
          }
          if (songIds.length == 10) break;
        }
      }
      if (songIds.isEmpty) {
        if (mounted) setState(() => _loadingRadio = false);
        return;
      }
      final stations = await _repository.getRadioStations(songIds);
      if (!mounted) return;
      setState(() { _radioStations = stations; _loadingRadio = false; });
    } catch (e) {
      debugPrint('RYVO RADIO ERROR: $e');
      if (mounted) setState(() => _loadingRadio = false);
    }
  }

  Future<void> _loadHomeData({bool showLoader = true}) async {
    if (mounted) {
      setState(() {
        if (showLoader) _loading = true;
        _error = null;
        _sections = {}; _homePlaylists = []; _homeAlbums = []; _recentlyPlayed = []; _radioStations = []; _loadingRadio = false;
        _discoverMixes = []; _topShows = [];
      });
    }
    try {
      await LibraryService.instance.init();
      final results = await Future.wait([_repository.getHomeBundle(), LibraryService.instance.getRecentlyPlayed()]);
      if (!mounted) return;
      final home = results[0] as Map<String, dynamic>;
      final recent = results[1] as List<Song>;
      
      setState(() {
        _sections = home['sections'] as Map<String, List<Song>>? ?? {};
        _homePlaylists = home['playlists'] as List<SearchPlaylistResult>? ?? [];
        _homeAlbums = home['albums'] as List<SearchAlbumResult>? ?? [];
        _discoverMixes = home['discover'] as List<Map<String, String>>? ?? [];
        _topShows = home['shows'] as List<Map<String, String>>? ?? [];
        _recentlyPlayed = recent;
        _loading = false; _error = null;
      });
      await _loadRadioStations();
    } catch (e) {
      debugPrint('Home error: $e');
      if (!mounted) return;
      setState(() { _loading = false; if (_sections.isEmpty) _error = 'Unable to load songs. Tap to retry.'; });
    }
  }

  void _playSong(Song song, List<Song> playlist, {int index = 0}) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(
      title: song.title, artist: song.artist, image: song.thumbnail, songId: song.id, playlist: playlist, currentIndex: index,
    )));
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = RyvoThemeController.themes[RyvoThemeController.instance.selectedTheme];
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 108.0;

    return RefreshIndicator(
      onRefresh: () => _loadHomeData(showLoader: false),
      color: currentTheme.primary, backgroundColor: SpotifyColors.surfaceElevated,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedHomeHeaderDelegate(
              minHeight: headerHeight, maxHeight: headerHeight,
              child: SafeArea(
                bottom: false,
                child: Container(
                  color: SpotifyColors.background, padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_getGreeting(), style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen())),
                                child: Container(
                                  width: 34, height: 34,
                                  decoration: BoxDecoration(color: SpotifyColors.surfaceElevated, shape: BoxShape.circle, border: Border.all(color: currentTheme.primary.withValues(alpha: 0.5), width: 1.5)),
                                  child: const Icon(Icons.person_rounded, color: SpotifyColors.textPrimary, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal, itemCount: _filters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final isSelected = _selectedFilterIndex == index;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedFilterIndex = index);
                                if (index == 4 && _radioStations.isEmpty && !_loadingRadio) _loadRadioStations();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(color: isSelected ? currentTheme.primary : SpotifyColors.surfaceElevated, borderRadius: BorderRadius.circular(20)),
                                child: Text(_filters[index], style: GoogleFonts.plusJakartaSans(color: isSelected ? Colors.black : SpotifyColors.textPrimary, fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_loading) SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator(color: currentTheme.primary)))
          else if (_error != null) SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: GestureDetector(
                onTap: () => _loadHomeData(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, color: SpotifyColors.textSecondary, size: 36),
                    const SizedBox(height: 10),
                    Text(_error!, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            ),
          )
          else ...[
            if (_selectedFilterIndex == 0) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 20), child: _buildQuickAccessGrid(currentTheme.primary))),
            if (_selectedFilterIndex == 0) Builder(builder: (context) {
              final forYouSongs = _sections['Made For You'] ?? _sections['For You'] ?? [];
              if (forYouSongs.isEmpty) return const SliverToBoxAdapter();
              return SliverToBoxAdapter(child: _buildTrackSection('For You', forYouSongs, currentTheme.primary));
            }),
            
            if (_selectedFilterIndex == 0 && _discoverMixes.isNotEmpty) SliverToBoxAdapter(child: _buildSimpleSection('Discover & Mixes', _discoverMixes, currentTheme.primary)),
            if (_selectedFilterIndex == 0 && _homePlaylists.isNotEmpty) SliverToBoxAdapter(child: _buildPlaylistsSection('Top Playlists', _homePlaylists, currentTheme.primary)),
            if (_selectedFilterIndex == 0 && _recentlyPlayed.isNotEmpty) SliverToBoxAdapter(child: _buildRecentlyPlayedSection(currentTheme.primary)),
            if (_selectedFilterIndex == 0 && _homeAlbums.isNotEmpty) SliverToBoxAdapter(child: _buildAlbumsSection('Popular Albums', _homeAlbums, currentTheme.primary)),
            
            if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) ..._sections.entries.where((entry) => entry.key != 'Charts' && entry.key != 'Made For You' && entry.key != 'For You').map((entry) {
              if (entry.value.isEmpty) return const SliverToBoxAdapter();
              return SliverToBoxAdapter(child: _buildTrackSection(entry.key, entry.value, currentTheme.primary));
            }),

            if (_selectedFilterIndex == 0 && _topShows.isNotEmpty) SliverToBoxAdapter(child: _buildSimpleSection('Top Shows & Podcasts', _topShows, currentTheme.primary)),

            if (_selectedFilterIndex == 2) Builder(builder: (context) {
              List<Song> chartSongs = _sections['Charts'] ?? [];
              if (chartSongs.isEmpty) chartSongs = _sections['Trending'] ?? _sections['Newly Released'] ?? [];
              if (chartSongs.isEmpty) return const SliverToBoxAdapter();
              return SliverToBoxAdapter(child: _buildTrackSection('Charts', chartSongs, currentTheme.primary));
            }),
            if (_selectedFilterIndex == 3) SliverToBoxAdapter(child: _buildMoodCategories(currentTheme.primary)),
            if (_selectedFilterIndex == 3 && _loadingMoodPlaylists) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))),
            if (_selectedFilterIndex == 3 && _moodPlaylists.isNotEmpty) SliverToBoxAdapter(child: _buildPlaylistsSection(_selectedMood ?? 'Moods', _moodPlaylists, currentTheme.primary)),
            if (_selectedFilterIndex == 4)
              if (_loadingRadio) const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
              else if (_radioStations.isNotEmpty) SliverToBoxAdapter(child: _buildRadioSection(_radioStations, currentTheme.primary))
              else SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.radio_rounded, size: 48, color: SpotifyColors.textSecondary),
                      const SizedBox(height: 16),
                      Text('Radio is unavailable right now', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 14)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: currentTheme.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        onPressed: _loadRadioStations,
                        child: Text('Retry', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodCategories(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick a mood', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 76, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: _moods.length,
            itemBuilder: (context, index) {
              final mood = _moods[index];
              final label = mood['label'] as String;
              final selected = _selectedMood == label;
              return GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); _loadMoodPlaylists(mood); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180), padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: selected ? accentColor.withValues(alpha: 0.28) : SpotifyColors.surfaceElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? accentColor : Colors.white10)),
                  child: Row(
                    children: [
                      Icon(mood['icon'] as IconData, color: selected ? accentColor : SpotifyColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(Color accentColor) {
    final List<Song> quickSongs = [];
    if (_recentlyPlayed.isNotEmpty) quickSongs.addAll(_recentlyPlayed.take(4));
    for (final songList in _sections.values) {
      for (final song in songList) {
        if (quickSongs.length >= 6) break;
        if (!quickSongs.any((s) => s.id == song.id)) quickSongs.add(song);
      }
      if (quickSongs.length >= 6) break;
    }
    if (quickSongs.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 56, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: quickSongs.length.clamp(0, 6),
      itemBuilder: (context, index) {
        final song = quickSongs[index];
        return GestureDetector(
          onTap: () => _playSong(song, quickSongs, index: index),
          child: Container(
            decoration: BoxDecoration(color: SpotifyColors.surfaceElevated, borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                  child: SizedBox(
                    width: 56, height: 56,
                    child: song.thumbnail.isNotEmpty
                        ? Image.network(song.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: SpotifyColors.surfaceHighlight, child: const Icon(Icons.music_note_rounded, color: SpotifyColors.textSecondary)))
                        : Container(color: SpotifyColors.surfaceHighlight, child: const Icon(Icons.music_note_rounded, color: SpotifyColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(decodeHtml(song.title), maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700, height: 1.2)),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    showModalBottomSheet(
                      context: context, backgroundColor: SpotifyColors.surfaceElevated,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                      builder: (_) => SongPlaylistPicker(song: song),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Icon(Icons.more_vert_rounded, color: SpotifyColors.textSecondary, size: 20),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadioSection(List<dynamic> stations, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Text('Radio', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: stations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final station = stations[index];
              final title = station is Map ? station['title']?.toString() ?? 'Radio' : 'Radio';
              final subtitle = station is Map ? station['subtitle']?.toString() ?? 'Radio Station' : 'Radio Station';
              final image = station is Map ? station['image']?.toString() ?? '' : '';

              return SizedBox(
                width: 145,
                child: GestureDetector(
                  onTap: () => HapticFeedback.selectionClick(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: image.isNotEmpty
                              ? Image.network(image, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: accentColor.withValues(alpha: 0.12), child: Icon(Icons.radio_rounded, size: 42, color: accentColor)))
                              : Container(color: accentColor.withValues(alpha: 0.12), child: Icon(Icons.radio_rounded, size: 42, color: accentColor)),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistsSection(String title, List<SearchPlaylistResult> playlists, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: playlists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Loading ${playlist.name}...', style: GoogleFonts.plusJakartaSans(color: Colors.white)), backgroundColor: SpotifyColors.surfaceElevated, duration: const Duration(seconds: 1))
                  );

                  List<Song> songs = await _repository.getPlaylistSongs(playlist.id);
                  
                  if (songs.isEmpty) {
                    songs = await _repository.search(playlist.name, pages: 1);
                  }

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  if (songs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Content is unavailable right now.', style: GoogleFonts.plusJakartaSans(color: Colors.white)), backgroundColor: SpotifyColors.surfaceElevated));
                    return;
                  }

                  Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistScreen(playlistName: playlist.name, subtitle: playlist.subtitle, icon: Icons.playlist_play_rounded, songs: songs)));
                },
                child: SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: playlist.image.isNotEmpty
                              ? Image.network(playlist.image, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: SpotifyColors.surfaceElevated, child: const Icon(Icons.album_rounded, color: SpotifyColors.textSecondary, size: 40)))
                              : Container(color: SpotifyColors.surfaceElevated, child: const Icon(Icons.album_rounded, color: SpotifyColors.textSecondary, size: 40)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(decodeHtml(playlist.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(decodeHtml(playlist.subtitle.isNotEmpty ? playlist.subtitle : 'Playlist'), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRecentlyPlayedSection(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Recently Played', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: _recentlyPlayed.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final song = _recentlyPlayed[index];
              return GestureDetector(
                onTap: () => _playSong(song, _recentlyPlayed, index: index),
                child: SizedBox(
                  width: 125,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: song.thumbnail.isNotEmpty
                              ? Image.network(song.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: SpotifyColors.surfaceElevated, child: const Icon(Icons.music_note_rounded, color: SpotifyColors.textSecondary)))
                              : Container(color: SpotifyColors.surfaceElevated, child: const Icon(Icons.music_note_rounded, color: SpotifyColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(decodeHtml(song.title), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                                Text(decodeHtml(song.artist), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              showModalBottomSheet(
                                context: context, backgroundColor: SpotifyColors.surfaceElevated,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                                builder: (_) => SongPlaylistPicker(song: song),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(top: 2, bottom: 8, left: 4),
                              child: Icon(Icons.more_vert_rounded, color: SpotifyColors.textSecondary, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAlbumsSection(String title, List<SearchAlbumResult> albums, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: albums.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final album = albums[index];
              return GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Loading ${album.name}...', style: GoogleFonts.plusJakartaSans(color: Colors.white)), backgroundColor: SpotifyColors.surfaceElevated, duration: const Duration(seconds: 1))
                  );

                  List<Song> songs = await _repository.getAlbumSongs(album.id);

                  if (songs.isEmpty) {
                    songs = await _repository.search(album.name, pages: 1);
                  }

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  if (songs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Content is unavailable right now.', style: GoogleFonts.plusJakartaSans(color: Colors.white)), backgroundColor: SpotifyColors.surfaceElevated));
                    return;
                  }

                  Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistScreen(playlistName: album.name, subtitle: album.artist, icon: Icons.album_rounded, songs: songs)));
                },
                child: SizedBox(
                  width: 130,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: album.image.isNotEmpty
                              ? Image.network(album.image, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: SpotifyColors.surfaceElevated, child: const Icon(Icons.album_rounded, color: SpotifyColors.textSecondary)))
                              : Container(color: SpotifyColors.surfaceElevated, child: const Icon(Icons.album_rounded, color: SpotifyColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(decodeHtml(album.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(decodeHtml(album.artist), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSimpleSection(String title, List<Map<String, String>> items, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              final type = item['type'] ?? '';
              
              IconData typeIcon = Icons.explore_rounded;
              if (type == 'show' || type == 'podcast') typeIcon = Icons.podcasts_rounded;
              else if (type == 'album') typeIcon = Icons.album_rounded;
              else if (type == 'playlist' || type == 'mix') typeIcon = Icons.queue_music_rounded;

              return GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  final id = item['id']!;
                  final itemTitle = item['title'] ?? 'Playlist';
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Loading $itemTitle...', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                      backgroundColor: SpotifyColors.surfaceElevated,
                      duration: const Duration(seconds: 1),
                    )
                  );

                  try {
                    List<Song> songs = [];
                    if (type == 'album') {
                      songs = await _repository.getAlbumSongs(id);
                    } else {
                      songs = await _repository.getPlaylistSongs(id);
                    }

                    if (songs.isEmpty) {
                       songs = await _repository.search(itemTitle, pages: 1);
                    }

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();

                    if (songs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Content is unavailable right now.', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                          backgroundColor: SpotifyColors.surfaceElevated,
                        )
                      );
                      return;
                    }

                    Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistScreen(
                      playlistName: itemTitle, subtitle: item['subtitle'] ?? 'Mix', 
                      icon: typeIcon, songs: songs
                    )));
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Unable to load this content type right now.', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                        backgroundColor: SpotifyColors.surfaceElevated,
                      )
                    );
                  }
                },
                child: SizedBox(
                  width: 130,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: item['image']!.isNotEmpty
                              ? Image.network(item['image']!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: SpotifyColors.surfaceElevated, child: Icon(typeIcon, color: SpotifyColors.textSecondary)))
                              : Container(color: SpotifyColors.surfaceElevated, child: Icon(typeIcon, color: SpotifyColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(decodeHtml(item['title']!), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(decodeHtml(item['subtitle']!), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTrackSection(String sectionTitle, List<Song> songs, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(sectionTitle, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: songs.length.clamp(0, 8),
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final song = songs[index];
              return GestureDetector(
                onTap: () => _playSong(song, songs, index: index),
                child: SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: song.thumbnail.isNotEmpty
                              ? Image.network(song.thumbnail, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: SpotifyColors.surfaceElevated, child: const Icon(Icons.music_note_rounded, color: SpotifyColors.textSecondary, size: 40)))
                              : Container(color: SpotifyColors.surfaceElevated, child: const Icon(Icons.music_note_rounded, color: SpotifyColors.textSecondary, size: 40)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(decodeHtml(song.title), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(decodeHtml(song.artist), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              showModalBottomSheet(
                                context: context, backgroundColor: SpotifyColors.surfaceElevated,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                                builder: (_) => SongPlaylistPicker(song: song),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(top: 2, bottom: 8, left: 4),
                              child: Icon(Icons.more_vert_rounded, color: SpotifyColors.textSecondary, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PinnedHomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight; final double maxHeight; final Widget child;
  const _PinnedHomeHeaderDelegate({required this.minHeight, required this.maxHeight, required this.child});
  @override double get minExtent => minHeight;
  @override double get maxExtent => maxHeight;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) { return Material(color: SpotifyColors.background, elevation: overlapsContent ? 2 : 0, child: child); }
  @override bool shouldRebuild(covariant _PinnedHomeHeaderDelegate oldDelegate) { return oldDelegate.minHeight != minHeight || oldDelegate.maxHeight != maxHeight || oldDelegate.child != child; }
}