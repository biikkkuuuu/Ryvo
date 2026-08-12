import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_app/features/player/player_screen.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/repositories/music_repository.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller =
  TextEditingController();

  final MusicRepository _repository =
  MusicRepository();

  final FocusNode _focusNode =
  FocusNode();

  List<Song> results = [];

  List<Song> songSuggestions = [];

  List<SearchArtistResult> artistSuggestions = [];

  List<SearchPlaylistResult> playlistSuggestions = [];

  bool loading = false;
  bool suggestionLoading = false;
  bool showSuggestions = false;

  List<String> _searchHistory = [];

  static const String _searchHistoryKey = 'ryvo_search_history';
  static const int _maxSearchHistory = 10;

  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();

    _loadSearchHistory();

    _controller.addListener(
      _onQueryChanged,
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus &&
          _controller.text.trim().isNotEmpty) {
        if (!mounted) return;

        setState(() {
          showSuggestions = true;
        });
      }
    });
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final history =
        prefs.getStringList(_searchHistoryKey) ?? [];

    if (!mounted) return;

    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _saveSearchHistory(String query) async {
    final value = query.trim();

    if (value.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    final updatedHistory = List<String>.from(_searchHistory);

    updatedHistory.removeWhere(
          (item) => item.toLowerCase() == value.toLowerCase(),
    );

    updatedHistory.insert(0, value);

    if (updatedHistory.length > _maxSearchHistory) {
      updatedHistory.removeRange(
        _maxSearchHistory,
        updatedHistory.length,
      );
    }

    await prefs.setStringList(
      _searchHistoryKey,
      updatedHistory,
    );

    if (!mounted) return;

    setState(() {
      _searchHistory = updatedHistory;
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

  Future<void> _searchFromHistory(String query) async {
    _controller.text = query;
    await _search();
  }

  // ============================================================
  // LIVE SEARCH
  // ============================================================

  Future<void> _onQueryChanged() async {
    final query = _controller.text.trim();

    if (query.isEmpty) {
      if (!mounted) return;

      setState(() {
        songSuggestions = [];
        artistSuggestions = [];
        playlistSuggestions = [];
        showSuggestions = false;
        suggestionLoading = false;
      });

      return;
    }

    final requestId = ++_searchRequestId;

    if (mounted) {
      setState(() {
        showSuggestions = true;
        suggestionLoading = true;
      });
    }

    await Future.delayed(
      const Duration(milliseconds: 350),
    );

    if (!mounted) return;

    if (requestId != _searchRequestId) {
      return;
    }

    if (_controller.text.trim() != query) {
      return;
    }

    try {
      final response =
      await Future.wait<dynamic>([
        _repository.songSuggestions(query),
        _repository.artistSuggestions(query),
        _repository.playlistSuggestions(query),
      ]);

      if (!mounted) return;

      if (requestId != _searchRequestId) {
        return;
      }

      setState(() {
        songSuggestions =
        response[0] as List<Song>;

        artistSuggestions =
        response[1]
        as List<SearchArtistResult>;

        playlistSuggestions =
        response[2]
        as List<SearchPlaylistResult>;

        suggestionLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Live search error: $e',
      );

      if (!mounted) return;

      if (requestId == _searchRequestId) {
        setState(() {
          suggestionLoading = false;
        });
      }
    }
  }

  // ============================================================
  // FULL SEARCH
  // ============================================================

  Future<void> _search() async {
    final query = _controller.text.trim();

    if (query.isEmpty) {
      return;
    }

    await _saveSearchHistory(query);

    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
      showSuggestions = false;
      results = [];
    });

    try {
      final searchedSongs =
      await _repository.search(
        query,
        pages: 3,
      );

      if (!mounted) return;

      setState(() {
        results = searchedSongs;
        loading = false;
      });
    } catch (e) {
      debugPrint(
        'Search error: $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showMessage(
        'Unable to search right now',
      );
    }
  }

  // ============================================================
  // SONG SUGGESTION TAP
  // ============================================================

  Future<void> _openSongFromSuggestion(
      Song song,
      ) async {
    final query = _controller.text.trim();

    setState(() {
      showSuggestions = false;
      loading = true;
    });

    try {
      final playlist =
      await _repository.search(
        query.isEmpty ? song.title : query,
        pages: 3,
      );

      if (!mounted) return;

      final finalPlaylist =
      playlist.isEmpty ? [song] : playlist;

      final index =
      finalPlaylist.indexWhere(
            (item) => item.id == song.id,
      );

      setState(() {
        results = finalPlaylist;
        loading = false;
      });

      _openPlayer(
        song,
        finalPlaylist,
        index < 0 ? 0 : index,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _openPlayer(
        song,
        [song],
        0,
      );
    }
  }

  // ============================================================
  // ARTIST TAP
  //
  // IMPORTANT:
  // Artist suggestion does NOT directly replace the search list.
  //
  // It opens a BIG dedicated artist page.
  // ============================================================

  Future<void> _openArtist(
      SearchArtistResult artist,
      ) async {
    FocusScope.of(context).unfocus();

    final songs =
    await Navigator.push<List<Song>>(
      context,
      MaterialPageRoute(
        builder: (_) => _ArtistDetailScreen(
          artist: artist,
          repository: _repository,
        ),
      ),
    );

    if (!mounted) return;

    // Keep search screen state intact.
    // If artist page returned songs, show them in search too.
    if (songs != null && songs.isNotEmpty) {
      setState(() {
        results = songs;
        _controller.text = artist.name;
        showSuggestions = false;
      });
    }
  }

  // ============================================================
  // PLAYLIST TAP
  // ============================================================

  Future<void> _openPlaylist(
      SearchPlaylistResult playlist,
      ) async {
    FocusScope.of(context).unfocus();

    setState(() {
      showSuggestions = false;
      loading = true;
      results = [];
    });

    try {
      final songs =
      await _repository.getPlaylistSongs(
        playlist.id,
      );

      if (!mounted) return;

      setState(() {
        results = songs;
        loading = false;
      });

      if (songs.isEmpty) {
        _showMessage(
          'No songs found in this playlist',
        );

        return;
      }

      _openPlayer(
        songs.first,
        songs,
        0,
      );
    } catch (e) {
      debugPrint(
        'Playlist error: $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showMessage(
        'Unable to load playlist',
      );
    }
  }

  // ============================================================
  // PLAYER
  // ============================================================

  void _openPlayer(
      Song song,
      List<Song> playlist,
      int index,
      ) {
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
        Brightness.light,
        statusBarBrightness:
        Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
        const Color(0xff0A0614),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // ==================================================
            // BACKGROUND
            // ==================================================

            Positioned.fill(
              child: Container(
                decoration:
                const BoxDecoration(
                  gradient:
                  LinearGradient(
                    begin:
                    Alignment.topLeft,
                    end:
                    Alignment.bottomRight,
                    colors: [
                      Color(0xff2A1152),
                      Color(0xff3B1670),
                      Color(0xff1B0E33),
                      Color(0xff0A0614),
                    ],
                    stops: [
                      0.0,
                      0.32,
                      0.68,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: -100,
              left: -100,
              child: _ambientLight(
                300,
                const Color(0xff7C3AED),
              ),
            ),

            Positioned(
              top: 450,
              right: -130,
              child: _ambientLight(
                280,
                const Color(0xff6D28D9),
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // ==================================================
                  // HEADER
                  // ==================================================

                  Padding(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              Navigator.pop(
                                context,
                              ),
                          child: _glassBox(
                            width: 44,
                            height: 44,
                            radius: 15,
                            child:
                            const Icon(
                              Icons
                                  .arrow_back_ios_new_rounded,
                              color:
                              Colors.white70,
                              size: 19,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        Text(
                          'Search',
                          style:
                          GoogleFonts.poppins(
                            color:
                            Colors.white,
                            fontSize: 23,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // SEARCH FIELD
                  // ==================================================

                  Padding(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: _glassBox(
                      radius: 20,
                      height: 58,
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 15,
                          ),

                          const Icon(
                            Icons
                                .search_rounded,
                            color:
                            Color(0xffB794F4),
                            size: 24,
                          ),

                          const SizedBox(
                            width: 11,
                          ),

                          Expanded(
                            child:
                            TextField(
                              controller:
                              _controller,
                              focusNode:
                              _focusNode,
                              textInputAction:
                              TextInputAction
                                  .search,
                              onSubmitted:
                                  (_) =>
                                  _search(),
                              style:
                              GoogleFonts
                                  .poppins(
                                color:
                                Colors.white,
                                fontSize: 13,
                              ),
                              cursorColor:
                              const Color(
                                0xffA78BFA,
                              ),
                              decoration:
                              InputDecoration(
                                hintText:
                                'Search songs, artists...',
                                hintStyle:
                                GoogleFonts
                                    .poppins(
                                  color: Colors
                                      .white
                                      .withValues(
                                    alpha: 0.38,
                                  ),
                                  fontSize: 13,
                                ),
                                border:
                                InputBorder
                                    .none,
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: _search,
                            child: Container(
                              width: 44,
                              height: 44,
                              margin:
                              const EdgeInsets
                                  .only(
                                right: 6,
                              ),
                              decoration:
                              BoxDecoration(
                                color:
                                const Color(
                                  0xff8B5CF6,
                                ).withValues(
                                  alpha: 0.78,
                                ),
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  15,
                                ),
                              ),
                              child:
                              const Icon(
                                Icons
                                    .search_rounded,
                                color:
                                Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // MAIN AREA
                  // ==================================================

                  Expanded(
                    child: _controller.text.trim().isEmpty &&
                        _searchHistory.isNotEmpty
                        ? _searchHistoryView()
                        : loading
                        ? _loadingView()
                        : showSuggestions &&
                        _hasSuggestions
                        ? _suggestionsView()
                        : _resultsView(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchHistoryView() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      children: [
        Row(
          children: [
            Text(
              'Recent Searches',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _clearSearchHistory,
              child: Text(
                'Clear',
                style: GoogleFonts.poppins(
                  color: const Color(0xffA78BFA),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        ..._searchHistory.map(
              (query) => GestureDetector(
            onTap: () => _searchFromHistory(query),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.045),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: Color(0xffA78BFA),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      query,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.north_west_rounded,
                    color: Colors.white30,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HAS SUGGESTIONS
  // ============================================================

  bool get _hasSuggestions {
    return songSuggestions.isNotEmpty ||
        artistSuggestions.isNotEmpty ||
        playlistSuggestions.isNotEmpty ||
        suggestionLoading;
  }

  // ============================================================
  // SUGGESTIONS
  // ============================================================

  Widget _suggestionsView() {
    return ListView(
      physics:
      const BouncingScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(
        20,
        4,
        20,
        30,
      ),
      children: [
        if (suggestionLoading)
          const Padding(
            padding:
            EdgeInsets.all(30),
            child: Center(
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color:
                Color(0xffA78BFA),
              ),
            ),
          ),

        if (artistSuggestions.isNotEmpty)
          _suggestionSectionTitle(
            'Artists',
          ),

        if (artistSuggestions.isNotEmpty)
          ...artistSuggestions
              .take(4)
              .map(_artistSuggestionTile),

        if (songSuggestions.isNotEmpty)
          _suggestionSectionTitle(
            'Songs',
          ),

        if (songSuggestions.isNotEmpty)
          ...songSuggestions
              .take(6)
              .map(_songSuggestionTile),

        if (playlistSuggestions.isNotEmpty)
          _suggestionSectionTitle(
            'Playlists',
          ),

        if (playlistSuggestions.isNotEmpty)
          ...playlistSuggestions
              .take(4)
              .map(
            _playlistSuggestionTile,
          ),
      ],
    );
  }

  // ============================================================
  // ARTIST SUGGESTION
  // ============================================================

  Widget _artistSuggestionTile(
      SearchArtistResult artist,
      ) {
    return GestureDetector(
      onTap: () => _openArtist(artist),
      child: _glassTile(
        child: Row(
          children: [
            _networkImage(
              artist.image,
              size: 48,
              radius: 24,
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    artist.name,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    GoogleFonts.poppins(
                      color:
                      Colors.white,
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    artist.role.isEmpty
                        ? 'Artist'
                        : artist.role,
                    style:
                    GoogleFonts.poppins(
                      color:
                      Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .person_outline_rounded,
              color:
              Color(0xffA78BFA),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SONG SUGGESTION
  // ============================================================

  Widget _songSuggestionTile(
      Song song,
      ) {
    return GestureDetector(
      onTap: () =>
          _openSongFromSuggestion(song),
      child: _glassTile(
        child: Row(
          children: [
            _networkImage(
              song.thumbnail,
              size: 48,
              radius: 13,
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    _decode(song.title),
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    GoogleFonts.poppins(
                      color:
                      Colors.white,
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    _decode(song.artist),
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    GoogleFonts.poppins(
                      color:
                      Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.play_arrow_rounded,
              color:
              Color(0xffA78BFA),
              size: 27,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PLAYLIST SUGGESTION
  // ============================================================

  Widget _playlistSuggestionTile(
      SearchPlaylistResult playlist,
      ) {
    return GestureDetector(
      onTap: () =>
          _openPlaylist(playlist),
      child: _glassTile(
        child: Row(
          children: [
            _networkImage(
              playlist.image,
              size: 48,
              radius: 13,
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    GoogleFonts.poppins(
                      color:
                      Colors.white,
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    playlist.songCount !=
                        null
                        ? '${playlist.songCount} songs'
                        : playlist.subtitle,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    GoogleFonts.poppins(
                      color:
                      Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .playlist_play_rounded,
              color:
              Color(0xffA78BFA),
              size: 27,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESULTS
  // ============================================================

  Widget _resultsView() {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xff8B5CF6,
                  ).withValues(
                    alpha: 0.10,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child:
                const Icon(
                  Icons
                      .search_rounded,
                  color:
                  Color(0xffA78BFA),
                  size: 32,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              Text(
                'Search for something',
                style:
                GoogleFonts.poppins(
                  color:
                  Colors.white70,
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                'Songs, artists and playlists',
                style:
                GoogleFonts.poppins(
                  color:
                  Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics:
      const BouncingScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(
        20,
        4,
        20,
        30,
      ),
      itemCount: results.length,
      itemBuilder:
          (context, index) {
        final song =
        results[index];

        return GestureDetector(
          onTap: () {
            _openPlayer(
              song,
              results,
              index,
            );
          },
          child: _glassTile(
            child: Row(
              children: [
                _networkImage(
                  song.thumbnail,
                  size: 58,
                  radius: 14,
                ),

                const SizedBox(
                  width: 13,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        _decode(
                          song.title,
                        ),
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        GoogleFonts
                            .poppins(
                          color:
                          Colors.white,
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        _decode(
                          song.artist,
                        ),
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        GoogleFonts
                            .poppins(
                          color: Colors
                              .white
                              .withValues(
                            alpha: 0.42,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 38,
                  height: 38,
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xff8B5CF6,
                    ).withValues(
                      alpha: 0.78,
                    ),
                    shape:
                    BoxShape.circle,
                  ),
                  child:
                  const Icon(
                    Icons
                        .play_arrow_rounded,
                    color:
                    Colors.white,
                    size: 23,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _loadingView() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xff8B5CF6,
              ).withValues(
                alpha: 0.10,
              ),
              shape:
              BoxShape.circle,
              border: Border.all(
                color:
                const Color(
                  0xffA78BFA,
                ).withValues(
                  alpha: 0.18,
                ),
              ),
            ),
            child:
            const Padding(
              padding:
              EdgeInsets.all(14),
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color:
                Color(0xffA78BFA),
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            'Searching...',
            style:
            GoogleFonts.poppins(
              color:
              Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _suggestionSectionTitle(
      String title,
      ) {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        2,
        14,
        2,
        8,
      ),
      child: Text(
        title,
        style:
        GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight:
          FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // GLASS TILE
  // ============================================================

  Widget _glassTile({
    required Widget child,
  }) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 9,
      ),
      padding:
      const EdgeInsets.all(10),
      decoration:
      BoxDecoration(
        color: Colors.white
            .withValues(
          alpha: 0.045,
        ),
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.white
              .withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // GLASS BOX
  // ============================================================

  Widget _glassBox({
    double? width,
    double? height,
    double radius = 20,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius:
      BorderRadius.circular(
        radius,
      ),
      child: BackdropFilter(
        filter:
        ImageFilter.blur(
          sigmaX: 22,
          sigmaY: 22,
        ),
        child: Container(
          width: width,
          height: height,
          decoration:
          BoxDecoration(
            color: Colors.white
                .withValues(
              alpha: 0.045,
            ),
            borderRadius:
            BorderRadius.circular(
              radius,
            ),
            border: Border.all(
              color: Colors.white
                  .withValues(
                alpha: 0.12,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // NETWORK IMAGE
  // ============================================================

  Widget _networkImage(
      String url, {
        required double size,
        required double radius,
      }) {
    if (url.trim().isEmpty) {
      return _imageFallback(
        size,
        radius,
      );
    }

    return ClipRRect(
      borderRadius:
      BorderRadius.circular(
        radius,
      ),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: 160,
        cacheHeight: 160,
        errorBuilder:
            (_, _, _) =>
            _imageFallback(
              size,
              radius,
            ),
      ),
    );
  }

  Widget _imageFallback(
      double size,
      double radius,
      ) {
    return Container(
      width: size,
      height: size,
      decoration:
      BoxDecoration(
        borderRadius:
        BorderRadius.circular(
          radius,
        ),
        gradient:
        const LinearGradient(
          colors: [
            Color(0xff8B5CF6),
            Color(0xff312E81),
          ],
        ),
      ),
      child:
      const Icon(
        Icons.music_note_rounded,
        color:
        Colors.white70,
      ),
    );
  }

  // ============================================================
  // AMBIENT LIGHT
  // ============================================================

  Widget _ambientLight(
      double size,
      Color color,
      ) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter:
        ImageFilter.blur(
          sigmaX: 55,
          sigmaY: 55,
        ),
        child: Container(
          width: size,
          height: size,
          decoration:
          BoxDecoration(
            shape:
            BoxShape.circle,
            gradient:
            RadialGradient(
              colors: [
                color.withValues(
                  alpha: 0.15,
                ),
                color.withValues(
                  alpha: 0.045,
                ),
                color.withValues(
                  alpha: 0,
                ),
              ],
              stops: const [
                0.0,
                0.52,
                1.0,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style:
            GoogleFonts.poppins(
              fontSize: 12,
            ),
          ),
          behavior:
          SnackBarBehavior.floating,
          margin:
          const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            18,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              15,
            ),
          ),
        ),
      );
  }

  // ============================================================
  // DECODE
  // ============================================================

  String _decode(String text) {
    return text
        .replaceAll(
      '&quot;',
      '"',
    )
        .replaceAll(
      '&amp;',
      '&',
    )
        .replaceAll(
      '&#39;',
      "'",
    )
        .replaceAll(
      '&apos;',
      "'",
    )
        .replaceAll(
      '&lt;',
      '<',
    )
        .replaceAll(
      '&gt;',
      '>',
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
      _onQueryChanged,
    );
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

// ============================================================================
// ARTIST DETAIL SCREEN
// ============================================================================
//
// Kept in THIS SAME FILE intentionally.
// No new artist_detail_screen.dart file is required.
// ============================================================================

class _ArtistDetailScreen
    extends StatefulWidget {
  final SearchArtistResult artist;
  final MusicRepository repository;

  const _ArtistDetailScreen({
    required this.artist,
    required this.repository,
  });

  @override
  State<_ArtistDetailScreen> createState() =>
      _ArtistDetailScreenState();
}

class _ArtistDetailScreenState
    extends State<_ArtistDetailScreen> {
  List<Song> songs = [];

  bool loading = true;

  String errorMessage = '';

  @override
  void initState() {
    super.initState();

    _loadArtistSongs();
  }

  // ============================================================
  // LOAD ARTIST SONGS
  // ============================================================

  Future<void> _loadArtistSongs() async {
    try {
      final loadedSongs =
      await widget.repository
          .searchArtistSongs(
        widget.artist.id,
        pages: 5,
      );

      if (!mounted) return;

      setState(() {
        songs = loadedSongs;
        loading = false;
      });
    } catch (e) {
      debugPrint(
        'Artist detail error: $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage =
        'Unable to load artist songs';
      });
    }
  }

  // ============================================================
  // PLAYER
  // ============================================================

  void _openPlayer(
      Song song,
      int index,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: song.title,
          artist: song.artist,
          image: song.thumbnail,
          songId: song.id,
          playlist: songs,
          currentIndex: index,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:
        Colors.transparent,
        statusBarIconBrightness:
        Brightness.light,
        statusBarBrightness:
        Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
        const Color(0xff0A0614),
        body: Stack(
          children: [
            // ==================================================
            // BACKGROUND
            // ==================================================

            Positioned.fill(
              child: Container(
                decoration:
                const BoxDecoration(
                  gradient:
                  LinearGradient(
                    begin:
                    Alignment.topCenter,
                    end:
                    Alignment.bottomCenter,
                    colors: [
                      Color(0xff32115E),
                      Color(0xff1C0D35),
                      Color(0xff0A0614),
                    ],
                    stops: [
                      0.0,
                      0.48,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: -140,
              left: -80,
              child: _artistAmbientLight(
                360,
                const Color(0xff8B5CF6),
              ),
            ),

            Positioned(
              top: 300,
              right: -180,
              child: _artistAmbientLight(
                360,
                const Color(0xff6D28D9),
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            SafeArea(
              child: CustomScrollView(
                physics:
                const BouncingScrollPhysics(),
                slivers: [
                  // ==================================================
                  // APP BAR
                  // ==================================================

                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                      const EdgeInsets.fromLTRB(
                        20,
                        10,
                        20,
                        0,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                Navigator.pop(
                                  context,
                                ),
                            child:
                            _artistGlassBox(
                              width: 44,
                              height: 44,
                              radius: 15,
                              child:
                              const Icon(
                                Icons
                                    .arrow_back_ios_new_rounded,
                                color: Colors
                                    .white70,
                                size: 19,
                              ),
                            ),
                          ),

                          const Spacer(),

                          Text(
                            'Artist',
                            style:
                            GoogleFonts
                                .poppins(
                              color: Colors
                                  .white70,
                              fontSize: 12,
                              fontWeight:
                              FontWeight
                                  .w500,
                            ),
                          ),

                          const Spacer(),

                          const SizedBox(
                            width: 44,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ==================================================
                  // ARTIST HEADER
                  // ==================================================

                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                      const EdgeInsets
                          .fromLTRB(
                        20,
                        30,
                        20,
                        20,
                      ),
                      child: Column(
                        children: [
                          // Artist image
                          _largeArtistImage(
                            widget.artist.image,
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          // Artist name
                          Text(
                            _decode(
                              widget.artist.name,
                            ),
                            textAlign:
                            TextAlign.center,
                            maxLines: 2,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            GoogleFonts
                                .poppins(
                              color: Colors
                                  .white,
                              fontSize: 27,
                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            'Artist',
                            style:
                            GoogleFonts
                                .poppins(
                              color: Colors
                                  .white54,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          // Song count
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            decoration:
                            BoxDecoration(
                              color: Colors
                                  .white
                                  .withValues(
                                alpha: 0.06,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                30,
                              ),
                              border:
                              Border.all(
                                color: Colors
                                    .white
                                    .withValues(
                                  alpha: 0.10,
                                ),
                              ),
                            ),
                            child: Text(
                              loading
                                  ? 'Loading songs...'
                                  : '${songs.length} songs',
                              style:
                              GoogleFonts
                                  .poppins(
                                color: Colors
                                    .white70,
                                fontSize: 11,
                                fontWeight:
                                FontWeight
                                    .w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ==================================================
                  // SONG HEADER
                  // ==================================================

                  if (!loading &&
                      songs.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                        const EdgeInsets
                            .fromLTRB(
                          20,
                          10,
                          20,
                          12,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Songs',
                              style:
                              GoogleFonts
                                  .poppins(
                                color:
                                Colors.white,
                                fontSize: 19,
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${songs.length}',
                              style:
                              GoogleFonts
                                  .poppins(
                                color:
                                Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ==================================================
                  // LOADING
                  // ==================================================

                  if (loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                          Color(
                            0xffA78BFA,
                          ),
                        ),
                      ),
                    ),

                  // ==================================================
                  // ERROR / EMPTY
                  // ==================================================

                  if (!loading &&
                      songs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding:
                          const EdgeInsets
                              .all(30),
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                            children: [
                              const Icon(
                                Icons
                                    .music_off_rounded,
                                color: Colors
                                    .white38,
                                size: 42,
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Text(
                                errorMessage
                                    .isEmpty
                                    ? 'No songs found'
                                    : errorMessage,
                                textAlign:
                                TextAlign
                                    .center,
                                style:
                                GoogleFonts
                                    .poppins(
                                  color: Colors
                                      .white54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ==================================================
                  // SONG LIST
                  // ==================================================

                  if (!loading &&
                      songs.isNotEmpty)
                    SliverPadding(
                      padding:
                      const EdgeInsets
                          .fromLTRB(
                        20,
                        0,
                        20,
                        35,
                      ),
                      sliver:
                      SliverList(
                        delegate:
                        SliverChildBuilderDelegate(
                              (context, index) {
                            final song =
                            songs[index];

                            return GestureDetector(
                              onTap: () =>
                                  _openPlayer(
                                    song,
                                    index,
                                  ),
                              child:
                              _artistSongTile(
                                song,
                                index,
                              ),
                            );
                          },
                          childCount:
                          songs.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ARTIST IMAGE
  // ============================================================

  Widget _largeArtistImage(
      String url,
      ) {
    return Container(
      width: 190,
      height: 190,
      decoration:
      BoxDecoration(
        shape:
        BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xff8B5CF6,
            ).withValues(
              alpha: 0.25,
            ),
            blurRadius: 45,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: url.trim().isEmpty
            ? _artistImageFallback()
            : Image.network(
          url,
          width: 190,
          height: 190,
          fit: BoxFit.cover,
          cacheWidth: 500,
          cacheHeight: 500,
          errorBuilder:
              (_, _, _) =>
              _artistImageFallback(),
        ),
      ),
    );
  }

  Widget _artistImageFallback() {
    return Container(
      width: 190,
      height: 190,
      decoration:
      const BoxDecoration(
        shape:
        BoxShape.circle,
        gradient:
        LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            Color(0xff8B5CF6),
            Color(0xff312E81),
          ],
        ),
      ),
      child:
      const Icon(
        Icons.person_rounded,
        color:
        Colors.white70,
        size: 80,
      ),
    );
  }

  // ============================================================
  // SONG TILE
  // ============================================================

  Widget _artistSongTile(
      Song song,
      int index,
      ) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 9,
      ),
      padding:
      const EdgeInsets.all(9),
      decoration:
      BoxDecoration(
        color: Colors.white
            .withValues(
          alpha: 0.045,
        ),
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.white
              .withValues(
            alpha: 0.08,
          ),
        ),
      ),
      child: Row(
        children: [
          // Number
          SizedBox(
            width: 28,
            child: Text(
              '${index + 1}',
              textAlign:
              TextAlign.center,
              style:
              GoogleFonts.poppins(
                color:
                Colors.white38,
                fontSize: 11,
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          // Cover
          _artistNetworkImage(
            song.thumbnail,
            55,
            13,
          ),

          const SizedBox(
            width: 13,
          ),

          // Song information
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _decode(
                    song.title,
                  ),
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  GoogleFonts.poppins(
                    color:
                    Colors.white,
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  _decode(
                    song.artist,
                  ),
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  GoogleFonts.poppins(
                    color:
                    Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Container(
            width: 38,
            height: 38,
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xff8B5CF6,
              ).withValues(
                alpha: 0.72,
              ),
              shape:
              BoxShape.circle,
            ),
            child:
            const Icon(
              Icons
                  .play_arrow_rounded,
              color:
              Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _artistNetworkImage(
      String url,
      double size,
      double radius,
      ) {
    if (url.trim().isEmpty) {
      return _smallImageFallback(
        size,
        radius,
      );
    }

    return ClipRRect(
      borderRadius:
      BorderRadius.circular(
        radius,
      ),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: 160,
        cacheHeight: 160,
        errorBuilder:
            (_, _, _) =>
            _smallImageFallback(
              size,
              radius,
            ),
      ),
    );
  }

  Widget _smallImageFallback(
      double size,
      double radius,
      ) {
    return Container(
      width: size,
      height: size,
      decoration:
      BoxDecoration(
        borderRadius:
        BorderRadius.circular(
          radius,
        ),
        gradient:
        const LinearGradient(
          colors: [
            Color(0xff8B5CF6),
            Color(0xff312E81),
          ],
        ),
      ),
      child:
      const Icon(
        Icons.music_note_rounded,
        color:
        Colors.white70,
        size: 22,
      ),
    );
  }

  // ============================================================
  // GLASS
  // ============================================================

  Widget _artistGlassBox({
    double? width,
    double? height,
    double radius = 20,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius:
      BorderRadius.circular(
        radius,
      ),
      child: BackdropFilter(
        filter:
        ImageFilter.blur(
          sigmaX: 22,
          sigmaY: 22,
        ),
        child: Container(
          width: width,
          height: height,
          decoration:
          BoxDecoration(
            color: Colors.white
                .withValues(
              alpha: 0.045,
            ),
            borderRadius:
            BorderRadius.circular(
              radius,
            ),
            border: Border.all(
              color: Colors.white
                  .withValues(
                alpha: 0.12,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // AMBIENT
  // ============================================================

  Widget _artistAmbientLight(
      double size,
      Color color,
      ) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter:
        ImageFilter.blur(
          sigmaX: 55,
          sigmaY: 55,
        ),
        child: Container(
          width: size,
          height: size,
          decoration:
          BoxDecoration(
            shape:
            BoxShape.circle,
            gradient:
            RadialGradient(
              colors: [
                color.withValues(
                  alpha: 0.15,
                ),
                color.withValues(
                  alpha: 0.04,
                ),
                color.withValues(
                  alpha: 0,
                ),
              ],
              stops: const [
                0.0,
                0.52,
                1.0,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DECODE
  // ============================================================

  String _decode(String text) {
    return text
        .replaceAll(
      '&quot;',
      '"',
    )
        .replaceAll(
      '&amp;',
      '&',
    )
        .replaceAll(
      '&#39;',
      "'",
    )
        .replaceAll(
      '&apos;',
      "'",
    )
        .replaceAll(
      '&lt;',
      '<',
    )
        .replaceAll(
      '&gt;',
      '>',
    );
  }
}