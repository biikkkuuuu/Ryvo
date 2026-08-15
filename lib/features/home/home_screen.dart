import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_app/features/account/account_screen.dart';
import 'package:music_app/features/player/player_screen.dart';
import 'package:music_app/features/library/library_screen.dart';
import 'package:music_app/features/playlist/playlist_screen.dart';
import 'package:music_app/features/search/search_screen.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/repositories/music_repository.dart';
import 'package:music_app/services/audio_service.dart';
import 'package:music_app/services/library_service.dart';
import 'package:music_app/widgets/song_playlist_picker.dart';


// ============================================================
// GLOBAL GLASS WIDGET
// ============================================================

Widget ryvoGlass({
  required double radius,
  required double blur,
  required Color color,
  required Color borderColor,
  required Widget child,
  Color? shadowColor,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: blur,
        sigmaY: blur,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: shadowColor == null
              ? null
              : [
            BoxShadow(
              color: shadowColor,
              blurRadius: 25,
              spreadRadius: -6,
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}


// ============================================================
// MINI PLAYER
// ============================================================

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = AudioService();

    return ValueListenableBuilder<Song?>(
      valueListenable: audio.currentSong,
      builder: (context, song, _) {
        if (song == null) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<PlayerState>(
          stream: audio.playerStateStream,
          initialData: audio.player.playerState,
          builder: (context, snapshot) {
            final state = snapshot.data ?? audio.player.playerState;

            final playing = state.playing &&
                state.processingState != ProcessingState.completed;

            void openPlayer() {
              final currentSong = audio.currentSong.value;

              if (currentSong == null) {
                return;
              }

              final playbackQueue = List<Song>.from(audio.queue.value);

              final playlist = <Song>[
                currentSong,
                ...playbackQueue,
              ];

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    title: currentSong.title,
                    artist: currentSong.artist,
                    image: currentSong.thumbnail,
                    songId: currentSong.id,
                    playlist: playlist,
                    currentIndex: 0,
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
              child: ryvoGlass(
                radius: 20,
                blur: 24,
                color: Colors.white.withValues(alpha: 0.055),
                borderColor: Colors.white.withValues(alpha: 0.14),
                shadowColor: const Color(0xff8B5CF6)
                    .withValues(alpha: 0.10),
                child: GestureDetector(
                  onTap: openPlayer,
                  child: SizedBox(
                    height: 72,
                    child: Row(
                      children: [
                        const SizedBox(width: 8),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: SizedBox(
                            width: 55,
                            height: 55,
                            child: song.thumbnail.trim().isEmpty
                                ? _fallbackArt()
                                : Image.network(
                              song.thumbnail,
                              fit: BoxFit.cover,
                              cacheWidth: 110,
                              cacheHeight: 110,
                              errorBuilder: (_, __, ___) =>
                                  _fallbackArt(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 11),

                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                decodeMini(song.title),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  if (playing) ...[
                                    const _PlayingBars(),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Text(
                                      decodeMini(song.artist),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white
                                            .withValues(alpha: 0.45),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          onPressed: () async {
                            if (playing) {
                              await audio.pause();
                            } else {
                              await audio.resume();
                            }
                          },
                          icon: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 27,
                          ),
                        ),

                        IconButton(
                          onPressed: openPlayer,
                          icon: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Color(0xffC4B5FD),
                            size: 29,
                          ),
                        ),

                        const SizedBox(width: 2),
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

  Widget _fallbackArt() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff8B5CF6),
            Color(0xff312E81),
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white70,
      ),
    );
  }

  String decodeMini(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}


// ============================================================
// PLAYING BARS
// ============================================================

class _PlayingBars extends StatefulWidget {
  const _PlayingBars();

  @override
  State<_PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<_PlayingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return SizedBox(
          width: 17,
          height: 15,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final value =
                  0.35 + 0.65 * ((controller.value + i * 0.22) % 1.0);

              return Container(
                width: 3,
                height: 15 * value,
                decoration: BoxDecoration(
                  color: const Color(0xffA78BFA),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}


// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicRepository _repository = MusicRepository();

  Map<String, List<Song>> sections = {};

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadHome();
  }


// ============================================================
// LOAD HOME
// ============================================================

  Future<void> loadHome() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final result = await _repository.getHomeSections();

      if (!mounted) return;

      setState(() {
        sections = result;
        loading = false;
      });
    } catch (e) {
      debugPrint("Home loading error: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
        error = "Unable to load music";
      });
    }
  }


// ============================================================
// GET SONGS
// ============================================================

  List<Song> getSongs(String name) {
    return sections[name] ?? [];
  }


// ============================================================
// OPEN PLAYER
// ============================================================

  void openPlayer(
      Song song,
      List<Song> playlist,
      ) {
    if (playlist.isEmpty) return;

    final index = playlist.indexWhere(
          (item) => item.id == song.id,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: song.title,
          artist: song.artist,
          image: song.thumbnail,
          songId: song.id,
          playlist: playlist,
          currentIndex: index < 0 ? 0 : index,
        ),
      ),
    );
  }


// ============================================================
// OPEN PLAYLIST
// ============================================================

  void openPlaylist({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Song> songs,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistScreen(
          playlistName: title,
          subtitle: subtitle,
          icon: icon,
          songs: songs,
        ),
      ),
    );
  }


// ============================================================
// UNIQUE SONGS
// ============================================================

  List<Song> uniqueSongsFromSections() {
    final Map<String, Song> unique = {};

    for (final list in sections.values) {
      for (final song in list) {
        if (song.id.isNotEmpty) {
          unique[song.id] = song;
        }
      }
    }

    return unique.values.toList();
  }


// ============================================================
// BUILD
// ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A0614),
      // Let the scrollable content continue behind the fixed footer.
      // The fade overlay below controls only the content visibility;
      // the original purple background and footer widgets stay unchanged.
      extendBody: true,


// ======================================================
// BOTTOM
// ======================================================

      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: ryvoGlass(
                radius: 30,
                blur: 28,
                color: const Color(0xff15121D)
                    .withValues(alpha: 0.72),
                borderColor: Colors.white.withValues(alpha: 0.13),
                shadowColor: const Color(0xff8B5CF6)
                    .withValues(alpha: 0.08),
                child: SizedBox(
                  height: 68,
                  child: Row(
                    children: [
                      Expanded(
                        child: bottomItem(
                          Icons.home_rounded,
                          "Home",
                          true,
                              () {},
                        ),
                      ),
                      Expanded(
                        child: bottomItem(
                          Icons.library_music_rounded,
                          "Library",
                          false,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LibraryScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: bottomItem(
                          Icons.search_rounded,
                          "Search",
                          false,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SearchScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: bottomItem(
                          Icons.person_rounded,
                          "Account",
                          false,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AccountScreen(),
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
          ],
        ),
      ),

// ======================================================
// BODY
// ======================================================

// ONLY CHANGE:
// SafeArea removed from around the whole body so the
// existing UI can extend behind the bottom navigation.
      body: Stack(
        children: [
// ------------------------------------------------
// GLASSMORPHIC GRADIENT BACKGROUND
// ------------------------------------------------

          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xff2A1152),
                    Color(0xff3B1670),
                    Color(0xff1B0E33),
                    Color(0xff0A0614),
                  ],
                  stops: [0.0, 0.32, 0.68, 1.0],
                ),
              ),
            ),
          ),

// ------------------------------------------------
// SUBTLE AMBIENT PURPLE
// ------------------------------------------------

          Positioned(
            top: -120,
            left: -110,
            child: _ambientLight(
              size: 300,
              color: const Color(0xff7C3AED),
            ),
          ),

          Positioned(
            top: 530,
            right: -130,
            child: _ambientLight(
              size: 270,
              color: const Color(0xff6D28D9),
            ),
          ),

          Positioned(
            top: 1000,
            left: -120,
            child: _ambientLight(
              size: 240,
              color: const Color(0xff9333EA),
            ),
          ),

// ------------------------------------------------
// CONTENT
// ------------------------------------------------

          RefreshIndicator(
            color: const Color(0xffA78BFA),
            backgroundColor: const Color(0xff120C1A),
            onRefresh: loadHome,
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: 180),
              children: [
// ONLY CHANGE:
// Preserve the status-bar spacing that SafeArea
// previously provided.
                SizedBox(
                  height: MediaQuery.of(context).padding.top + 16,
                ),

// ==================================================
// FIXED HEADER SPACE
// ==================================================

                const SizedBox(height: 92),

// ==================================================
// GREETING
// ==================================================

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Good evening",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.52),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "What do you want to hear?",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 27,
                          height: 1.14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

// ==================================================
// SEARCH
// ==================================================

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SearchScreen(),
                        ),
                      );
                    },
                    child: ryvoGlass(
                      radius: 20,
                      blur: 25,
                      color: Colors.white.withValues(alpha: 0.045),
                      borderColor:
                      Colors.white.withValues(alpha: 0.14),
                      shadowColor: const Color(0xff8B5CF6)
                          .withValues(alpha: 0.07),
                      child: SizedBox(
                        height: 58,
                        child: Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 17),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: Color(0xffB794F4),
                                size: 25,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Search songs, artists...",
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(
                                    alpha: 0.38,
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.mic_none_rounded,
                                color: Colors.white.withValues(
                                  alpha: 0.30,
                                ),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

// ==================================================
// CHIPS
// ==================================================

                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      chip("All", true),
                      chip("Hindi", false),
                      chip("Romantic", false),
                      chip("Punjabi", false),
                      chip("English", false),
                      chip("Chill", false),
                    ],
                  ),
                ),

                const SizedBox(height: 31),

// ==================================================
// MUSIC
// ==================================================

                if (loading)
                  loadingView()
                else if (error != null)
                  errorView()
                else ...[
                    section(
                      "Trending",
                      getSongs("Trending"),
                      true,
                    ),

                    section(
                      "Hindi Hits",
                      getSongs("Hindi Hits"),
                      false,
                    ),

                    section(
                      "Romantic",
                      getSongs("Romantic"),
                      false,
                    ),

                    section(
                      "Punjabi",
                      getSongs("Punjabi"),
                      false,
                    ),

                    section(
                      "English",
                      getSongs("English"),
                      false,
                    ),

                    section(
                      "Chill",
                      getSongs("Chill"),
                      false,
                    ),

                    const SizedBox(height: 4),

                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Your playlists",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 13),

                    playlistCard(
                      title: "Late Night",
                      subtitle: "For those quiet hours",
                      icon: Icons.nightlight_round,
                      songs: getPlaylistSongs("Late Night"),
                    ),

                    playlistCard(
                      title: "Workout",
                      subtitle: "Energy for your workout",
                      icon: Icons.fitness_center_rounded,
                      songs: getPlaylistSongs("Workout"),
                    ),

                    playlistCard(
                      title: "Chill Mode",
                      subtitle: "Relax and slow down",
                      icon: Icons.spa_rounded,
                      songs: getPlaylistSongs("Chill Mode"),
                    ),

                    const SizedBox(height: 20),
                  ],
              ],
            ),
          ),

// ==================================================
// BOTTOM CONTENT FADE
// ==================================================
// This sits above the scrollable content but below the fixed
// header/footer. It fades only the content approaching the
// bottom controls, like the reference design.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 230,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xff0A0614).withValues(alpha: 0.48),
                      const Color(0xff0A0614).withValues(alpha: 0.88),
                      const Color(0xff0A0614),
                    ],
                    stops: const [0.0, 0.48, 0.78, 1.0],
                  ),
                ),
              ),
            ),
          ),
// ==================================================
// FIXED HEADER
// ==================================================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xff2A1152),
                    Color(0xff351363),
                    Color(0xff3B1670),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          'assets/icon/ryvo-icon.png',
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xffB794F4),
                                    Color(0xff7C3AED),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xff8B5CF6)
                                        .withValues(alpha: 0.28),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.graphic_eq_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "RYVO",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.3,
                            ),
                          ),
                          Text(
                            "Music Reimagined",
                            style: GoogleFonts.poppins(
                              color: const Color(0xffA78BFA),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ryvoGlass(
                        radius: 23,
                        blur: 20,
                        color: Colors.white.withValues(alpha: 0.045),
                        borderColor: Colors.white.withValues(alpha: 0.13),
                        child: SizedBox(
                          width: 46,
                          height: 46,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AccountScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.person_outline_rounded,
                              color: Colors.white70,
                              size: 23,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }


// ============================================================
// AMBIENT LIGHT
// ============================================================

  Widget _ambientLight({
    required double size,
    required Color color,
  }) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 55,
          sigmaY: 55,
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.045),
                color.withValues(alpha: 0.0),
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
// PLAYLIST SONGS
// ============================================================

  List<Song> getPlaylistSongs(String playlistName) {
    final all = uniqueSongsFromSections();

    if (all.isEmpty) {
      return [];
    }

    if (playlistName == "Late Night") {
      return uniqueList([
        ...getSongs("Romantic"),
        ...getSongs("Chill"),
        ...all,
      ]).take(10).toList();
    }

    if (playlistName == "Workout") {
      return uniqueList([
        ...getSongs("Punjabi"),
        ...getSongs("English"),
        ...getSongs("Trending"),
        ...all,
      ]).take(10).toList();
    }

    if (playlistName == "Chill Mode") {
      return uniqueList([
        ...getSongs("Chill"),
        ...getSongs("Romantic"),
        ...all,
      ]).take(10).toList();
    }

    return all.take(10).toList();
  }


// ============================================================
// UNIQUE LIST
// ============================================================

  List<Song> uniqueList(List<Song> songs) {
    final Map<String, Song> map = {};

    for (final song in songs) {
      if (song.id.isNotEmpty) {
        map[song.id] = song;
      }
    }

    return map.values.toList();
  }


// ============================================================
// SECTION
// ============================================================

  Widget section(
      String title,
      List<Song> songs,
      bool featured,
      ) {
    if (songs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Text(
                "See all",
                style: GoogleFonts.poppins(
                  color: const Color(0xffA78BFA),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          height: featured ? 255 : 215,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding:
            const EdgeInsets.symmetric(horizontal: 20),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];

              return GestureDetector(
                onTap: () {
                  openPlayer(song, songs);
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  showSongOptions(song);
                },
                child: Container(
                  width: featured ? 205 : 160,
                  margin:
                  const EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                          BorderRadius.circular(
                            featured ? 24 : 20,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                song.thumbnail,
                                fit: BoxFit.cover,
                                cacheWidth: 500,
                                cacheHeight: 500,
                                errorBuilder:
                                    (_, __, ___) {
                                  return Container(
                                    decoration:
                                    const BoxDecoration(
                                      gradient:
                                      LinearGradient(
                                        colors: [
                                          Color(0xff312E81),
                                          Color(0xff100B18),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.music_note_rounded,
                                      color: Colors.white54,
                                      size: 50,
                                    ),
                                  );
                                },
                              ),

// subtle glass tint
                              Container(
                                decoration:
                                BoxDecoration(
                                  color: const Color(0xff7C3AED)
                                      .withValues(alpha: 0.035),
                                  border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.15),
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(
                                    featured ? 24 : 20,
                                  ),
                                ),
                              ),

// bottom fade
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration:
                                  BoxDecoration(
                                    gradient:
                                    LinearGradient(
                                      begin:
                                      Alignment.topCenter,
                                      end:
                                      Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black
                                            .withValues(alpha: 0.35),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration:
                                  BoxDecoration(
                                    color: const Color(0xff8B5CF6)
                                        .withValues(alpha: 0.88),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.20),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xff8B5CF6)
                                            .withValues(alpha: 0.32),
                                        blurRadius: 18,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 9),

                      Text(
                        decode(song.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: featured ? 15 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        decode(song.artist),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.46),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }


// ============================================================
// PLAYLIST CARD
// ============================================================

  Widget playlistCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Song> songs,
  }) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 6,
      ),
      child: GestureDetector(
        onTap: songs.isEmpty
            ? null
            : () {
          openPlaylist(
            title: title,
            subtitle: subtitle,
            icon: icon,
            songs: songs,
          );
        },
        child: ryvoGlass(
          radius: 20,
          blur: 22,
          color: Colors.white.withValues(alpha: 0.045),
          borderColor:
          Colors.white.withValues(alpha: 0.13),
          shadowColor:
          const Color(0xff8B5CF6).withValues(alpha: 0.06),
          child: SizedBox(
            height: 82,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient:
                      const LinearGradient(
                        colors: [
                          Color(0xff9F7AEA),
                          Color(0xff5B21B6),
                        ],
                      ),
                      borderRadius:
                      BorderRadius.circular(15),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          songs.isEmpty
                              ? subtitle
                              : "${songs.length} songs â€¢ $subtitle",
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(
                              alpha: 0.45,
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
                    decoration: BoxDecoration(
                      color: songs.isEmpty
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xff8B5CF6)
                          .withValues(alpha: 0.82),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: songs.isEmpty
                          ? Colors.white24
                          : Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


// ============================================================
// CHIP
// ============================================================

  Widget chip(
      String text,
      bool selected,
      ) {
    return Container(
      margin:
      const EdgeInsets.only(right: 9),
      padding:
      const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xff8B5CF6)
            .withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.035),
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color: selected
              ? const Color(0xffC4B5FD)
              .withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: selected
            ? [
          BoxShadow(
            color: const Color(0xff8B5CF6)
                .withValues(alpha: 0.20),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ]
            : null,
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color:
          selected ? Colors.white : Colors.white60,
          fontSize: 12,
          fontWeight:
          selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }


// ============================================================
// LOADING
// ============================================================

  Widget loadingView() {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xff8B5CF6)
                    .withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xffA78BFA)
                      .withValues(alpha: 0.18),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xffA78BFA),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Text(
              "Finding music for you...",
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }


// ============================================================
// ERROR
// ============================================================

  Widget errorView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ryvoGlass(
        radius: 20,
        blur: 20,
        color: Colors.white.withValues(alpha: 0.04),
        borderColor:
        Colors.white.withValues(alpha: 0.10),
        child: SizedBox(
          height: 150,
          child: Center(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xffA78BFA),
                ),

                const SizedBox(height: 8),

                Text(
                  "Couldn't load music",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                  ),
                ),

                TextButton(
                  onPressed: loadHome,
                  child: Text(
                    "Try again",
                    style: GoogleFonts.poppins(
                      color: const Color(0xffA78BFA),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


// ============================================================
// BOTTOM NAV
// ============================================================

  Widget bottomItem(
      IconData icon,
      String label,
      bool active,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xff8B5CF6)
              .withValues(alpha: 0.19)
              : Colors.transparent,
          borderRadius:
          BorderRadius.circular(23),
          border: active
              ? Border.all(
            color: const Color(0xffC4B5FD)
                .withValues(alpha: 0.12),
          )
              : null,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active
                  ? const Color(0xffC4B5FD)
                  : Colors.white38,
              size: 22,
            ),

            const SizedBox(height: 3),

            Text(
              label,
              style: GoogleFonts.poppins(
                color: active
                    ? Colors.white
                    : Colors.white38,
                fontSize: 9,
                fontWeight: active
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }


// ============================================================
// SONG OPTIONS
// ============================================================

  void showSongOptions(Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: ryvoGlass(
              radius: 30,
              blur: 25,
              color: const Color(0xff100B17)
                  .withValues(alpha: 0.92),
              borderColor:
              Colors.white.withValues(alpha: 0.10),
              shadowColor:
              const Color(0xff8B5CF6).withValues(alpha: 0.08),
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        ClipRRect(
                          borderRadius:
                          BorderRadius.circular(15),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child:
                            song.thumbnail.trim().isEmpty
                                ? _menuFallbackArt()
                                : Image.network(
                              song.thumbnail,
                              fit: BoxFit.cover,
                              cacheWidth: 128,
                              cacheHeight: 128,
                              errorBuilder:
                                  (_, __, ___) =>
                                  _menuFallbackArt(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                decode(song.title),
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                decode(song.artist),
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _songAction(
                      icon: Icons.queue_music_rounded,
                      title: 'Add to Queue',
                      subtitle:
                      'Add this song to the end of your queue',
                      onTap: () {
                        AudioService().addToQueue(song);
                        Navigator.pop(sheetContext);

                        _showQueueMessage(
                          '${decode(song.title)} added to queue',
                        );
                      },
                    ),

                    _songAction(
                      icon: Icons.playlist_play_rounded,
                      title: 'Play Next',
                      subtitle:
                      'Play this song after the current one',
                      onTap: () {
                        AudioService().addToQueueNext(song);
                        Navigator.pop(sheetContext);

                        _showQueueMessage(
                          '${decode(song.title)} will play next',
                        );
                      },
                    ),

                    _songAction(
                      icon: Icons.favorite_rounded,
                      title: 'Add to Liked Songs',
                      subtitle:
                      'Save this song to your library',
                      iconColor: const Color(0xffF472B6),
                      onTap: () async {
                        final liked =
                        await LibraryService.instance
                            .toggleLike(song);

                        if (!mounted) return;

                        Navigator.pop(sheetContext);

                        _showQueueMessage(
                          liked
                              ? 'Added to Liked Songs'
                              : 'Removed from Liked Songs',
                        );
                      },
                    ),

                    _songAction(
                      icon: Icons.library_add_rounded,
                      title: 'Add to Playlist',
                      subtitle:
                      'Save this song to a playlist',
                      onTap: () async {
                        Navigator.pop(sheetContext);

                        await SongPlaylistPicker.show(
                          context,
                          song,
                        );
                      },
                    ),

                    const SizedBox(height: 4),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pop(sheetContext),
                        style: TextButton.styleFrom(
                          backgroundColor:
                          Colors.white.withValues(
                            alpha: 0.04,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(17),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
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
  }


// ============================================================
// SONG ACTION
// ============================================================

  Widget _songAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor =
    const Color(0xffA78BFA),
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius:
          BorderRadius.circular(18),
          child: Ink(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.04,
              ),
              borderRadius:
              BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.07,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white24,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


// ============================================================
// QUEUE MESSAGE
// ============================================================

  void _showQueueMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          behavior: SnackBarBehavior.floating,
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
            BorderRadius.circular(16),
          ),
          duration:
          const Duration(seconds: 1),
        ),
      );
  }


// ============================================================
// FALLBACK ART
// ============================================================

  Widget _menuFallbackArt() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff8B5CF6),
            Color(0xff312E81),
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white70,
        size: 30,
      ),
    );
  }


// ============================================================
// DECODE
// ============================================================

  String decode(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}




