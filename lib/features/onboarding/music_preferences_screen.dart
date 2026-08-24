import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_app/theme/app_theme.dart';
import 'package:music_app/services/jiosaavn_service.dart';

class MusicPreferencesScreen extends StatefulWidget {
  const MusicPreferencesScreen({super.key});

  @override
  State<MusicPreferencesScreen> createState() =>
      _MusicPreferencesScreenState();
}

class _MusicPreferencesScreenState extends State<MusicPreferencesScreen> {
  static const genres = [
    'Hindi',
    'English',
    'Punjabi',
    'Bhojpuri',
    'Telugu',
    'Tamil',
    'Bengali',
    'Malayalam',
    'Kannada',
    'Marathi',
    'Gujarati',
    'Haryanvi',
    'Urdu',
    'Odia',
    'Rajasthani',
    'Assamese',
  ];

  final selectedGenres = <String>{};
  final Map<String, String> selectedArtists = {};

  int step = 0;
  String artistQuery = '';
  
  Timer? _debounce;
  bool _isSearching = false;
  List<dynamic> _liveArtists = [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ============================================================
  // GENRE-BASED ARTIST DISCOVERY (INTERLEAVED & DEDUPLICATED)
  // ============================================================
  Future<void> _fetchDefaultArtists() async {
    setState(() => _isSearching = true);
    
    try {
      // 1. Read ALL selected genres
      final genresToSearch = selectedGenres.isNotEmpty 
          ? selectedGenres.toList() 
          : ['Trending'];

      // 2. Fetch discovery data for EVERY selected genre (limit increased to get enough pool)
      final futures = genresToSearch.map(
        (genre) => JioSaavnService().searchSongs(genre, limit: 50),
      );
      
      final responses = await Future.wait(futures);
      
      // We will store lists of artists grouped by genre to interleave them later
      List<List<Map<String, String>>> artistsPerGenre = [];
      
      // 3. Extract actual primary artists from the discovered songs
      for (final results in responses) {
        final genreArtists = <Map<String, String>>[];
        
        if (results is List) {
          for (final song in results) {
            if (song is! Map) continue;
            
            final artistsNode = song['artists'];
            if (artistsNode is Map) {
              final primary = artistsNode['primary'];
              
              if (primary is List) {
                for (final artist in primary) {
                  if (artist is! Map) continue;
                  
                  final id = artist['id']?.toString() ?? '';
                  final name = artist['name']?.toString() ?? artist['title']?.toString() ?? '';
                  
                  if (id.isNotEmpty && name.isNotEmpty) {
                    genreArtists.add({
                      'id': id,
                      'title': name,
                    });
                  }
                }
              }
            }
          }
        }
        artistsPerGenre.add(genreArtists);
      }
      
      // 4. Combine results in an interleaved (round-robin) manner
      final combinedArtists = <dynamic>[];
      final seenIds = <String>{}; 
      
      bool addedAny = true;
      int index = 0;
      
      // Keep picking 1 artist from each genre sequentially until we hit ~50 unique artists
      // Example: Hindi[0], English[0], Bhojpuri[0], Hindi[1], English[1], Bhojpuri[1]...
      while (addedAny && combinedArtists.length < 50) {
        addedAny = false;
        
        for (final genreList in artistsPerGenre) {
          if (index < genreList.length) {
            final artist = genreList[index];
            
            // 5. Deduplicate by exact Artist ID
            if (seenIds.add(artist['id']!)) {
              combinedArtists.add(artist);
            }
            addedAny = true;
          }
        }
        index++;
      }
      
      // 6. Assign _liveArtists ONLY AFTER all processing is fully complete
      if (mounted) {
        setState(() {
          _liveArtists = combinedArtists;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = SpotifyColors.green;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: SpotifyColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    const Image(
                      image: AssetImage('assets/icon/ryvo-icon.png'),
                      width: 34,
                      height: 34,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'RYVO',
                      style: GoogleFonts.plusJakartaSans(
                        color: SpotifyColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.plusJakartaSans(
                          color: SpotifyColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _progress(active: true, color: accent),
                    const SizedBox(width: 6),
                    _progress(active: step == 1, color: accent),
                  ],
                ),
              ),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: step == 0 ? _genres(accent) : _artists(accent),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _canContinue ? _next : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      disabledBackgroundColor: SpotifyColors.surfaceElevated,
                      foregroundColor: Colors.black,
                      disabledForegroundColor: SpotifyColors.textMuted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      step == 0 ? 'Continue' : 'Get My Music',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canContinue =>
      step == 0 ? selectedGenres.isNotEmpty : selectedArtists.isNotEmpty;

  Widget _progress({required bool active, required Color color}) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 4,
        decoration: BoxDecoration(
          color: active ? color : SpotifyColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _genres(Color accent) {
    return SingleChildScrollView(
      key: const ValueKey('genres'),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you like?',
            style: GoogleFonts.plusJakartaSans(
              color: SpotifyColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a few genres so RYVO can build better recommendations for you.',
            style: GoogleFonts.plusJakartaSans(
              color: SpotifyColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: genres.map((genre) {
              final selected = selectedGenres.contains(genre);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (!selected) {
                      selectedGenres.add(genre);
                    } else {
                      selectedGenres.remove(genre);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? accent : SpotifyColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? accent : Colors.white10,
                    ),
                  ),
                  child: Text(
                    genre,
                    style: GoogleFonts.plusJakartaSans(
                      color: selected ? Colors.black : SpotifyColors.textPrimary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _artists(Color accent) {
    return Column(
      key: const ValueKey('artists'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pick your artists',
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose artists you already love, or search for them.',
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: (value) {
                  setState(() {
                    artistQuery = value;
                  });

                  if (_debounce?.isActive ?? false) _debounce!.cancel();

                  final query = value.trim();
                  
                  // LIVE SEARCH UNCHANGED: Reverts to combined genre defaults if empty
                  if (query.isEmpty) {
                    _fetchDefaultArtists();
                    return;
                  }

                  _debounce = Timer(const Duration(milliseconds: 500), () async {
                    if (!mounted) return;
                    setState(() => _isSearching = true);

                    try {
                      // Call the existing artist search API exactly as it is in your project
                      final results = await JioSaavnService().searchArtists(query);

                      if (!mounted || artistQuery.trim() != query) return;

                      setState(() {
                        _liveArtists = results;
                        _isSearching = false;
                      });
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => _isSearching = false);
                    }
                  });
                },
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search artists...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: SpotifyColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: SpotifyColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: SpotifyColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isSearching
              ? Center(child: CircularProgressIndicator(color: accent))
              : _liveArtists.isEmpty
                  ? Center(
                      child: Text(
                        'No artists found',
                        style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      itemCount: _liveArtists.length,
                      itemBuilder: (context, index) {
                        final artist = _liveArtists[index];
                        final String id = artist['id']?.toString() ?? '';
                        final String name =
                            artist['title']?.toString() ?? artist['name']?.toString() ?? 'Unknown';

                        if (id.isEmpty) return const SizedBox.shrink();

                        final selected = selectedArtists.containsKey(id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: selected
                                ? accent.withValues(alpha: 0.16)
                                : SpotifyColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setState(() {
                                  if (!selected) {
                                    selectedArtists[id] = name;
                                  } else {
                                    selectedArtists.remove(id);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: SpotifyColors.surfaceHighlight,
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: selected ? accent : SpotifyColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: SpotifyColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      selected
                                          ? Icons.check_circle_rounded
                                          : Icons.add_circle_outline_rounded,
                                      color: selected ? accent : SpotifyColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _next() {
    if (step == 0) {
      setState(() => step = 1);
      _fetchDefaultArtists();
      return;
    }
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ryvo_preferred_genres', selectedGenres.toList());
    await prefs.setStringList('ryvo_preferred_artists', selectedArtists.values.toList());
    await prefs.setStringList('ryvo_preferred_artist_ids', selectedArtists.keys.toList());
    await prefs.setBool('ryvo_music_preferences_completed', true);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ryvo_music_preferences_completed', true);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}