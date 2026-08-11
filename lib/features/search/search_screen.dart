import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/features/player/player_screen.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/repositories/music_repository.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final MusicRepository _repository = MusicRepository();

  List<Song> results = [];
  bool loading = false;

  Future<void> search() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      loading = true;
    });

    try {
      final searchedSongs = await _repository.search(
        _controller.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        results = searchedSongs;
      });
    } catch (e) {
      debugPrint(e.toString());
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,

      ),
      child: Scaffold(
        backgroundColor: const Color(0xff0A0614),

        // Same fullscreen behavior as Home
        extendBody: true,
        extendBodyBehindAppBar: true,

        // ======================================================
        // APP BAR
        // ======================================================

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,

          title: Text(
            "Search",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),

          iconTheme: const IconThemeData(
            color: Colors.white,
            size: 34,
          ),
        ),

        // ======================================================
        // BODY
        // ======================================================

        body: Stack(
          children: [
            // --------------------------------------------------
            // SAME HOME BACKGROUND
            // --------------------------------------------------

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

            // --------------------------------------------------
            // AMBIENT PURPLE LIGHT
            // --------------------------------------------------

            Positioned(
              top: -120,
              left: -110,
              child: _ambientLight(
                size: 300,
                color: const Color(0xff7C3AED),
              ),
            ),

            Positioned(
              top: 520,
              right: -130,
              child: _ambientLight(
                size: 270,
                color: const Color(0xff6D28D9),
              ),
            ),

            Positioned(
              bottom: -100,
              left: -100,
              child: _ambientLight(
                size: 250,
                color: const Color(0xff9333EA),
              ),
            ),

            // --------------------------------------------------
            // CONTENT
            // --------------------------------------------------

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  62,
                  20,
                  20,
                ),
                child: Column(
                  children: [
                    // ==================================================
                    // SEARCH FIELD
                    // ==================================================

                    TextField(
                      controller: _controller,
                      onSubmitted: (_) => search(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      cursorColor: const Color(0xffA78BFA),

                      decoration: InputDecoration(
                        hintText: "Search songs...",
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white.withValues(
                            alpha: 0.42,
                          ),
                          fontSize: 16,
                        ),

                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Colors.white54,
                          size: 31,
                        ),

                        suffixIcon: IconButton(
                          onPressed: search,
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),

                        filled: true,
                        fillColor: Colors.white.withValues(
                          alpha: 0.055,
                        ),

                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),

                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: const Color(0xffA78BFA)
                                .withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // RESULTS / LOADING
                    // ==================================================

                    if (loading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xffA78BFA),
                          ),
                        ),
                      ),

                    if (!loading)
                      Expanded(
                        child: ListView.builder(
                          physics:
                          const BouncingScrollPhysics(),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final song = results[index];

                            return Container(
                              margin: const EdgeInsets.only(
                                bottom: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: 0.045,
                                ),
                                borderRadius:
                                BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white
                                      .withValues(alpha: 0.10),
                                ),
                              ),
                              child: ListTile(
                                contentPadding:
                                const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),

                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PlayerScreen(
                                            title: song.title,
                                            artist: song.artist,
                                            image: song.thumbnail,
                                            songId: song.id,

                                            // Complete search list
                                            playlist: results,

                                            // Current song index
                                            currentIndex: index,
                                          ),
                                    ),
                                  );
                                },

                                leading: ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                  child: Image.network(
                                    song.thumbnail,
                                    width: 55,
                                    height: 55,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) {
                                      return Container(
                                        width: 55,
                                        height: 55,
                                        decoration:
                                        BoxDecoration(
                                          color: const Color(
                                            0xff312E81,
                                          ),
                                          borderRadius:
                                          BorderRadius
                                              .circular(10),
                                        ),
                                        child: const Icon(
                                          Icons
                                              .music_note_rounded,
                                          color:
                                          Colors.white54,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                title: Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style:
                                  GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight:
                                    FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),

                                subtitle: Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style:
                                  GoogleFonts.poppins(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),

                                trailing: const Icon(
                                  Icons
                                      .play_circle_fill_rounded,
                                  color: Color(0xffA78BFA),
                                  size: 34,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
}