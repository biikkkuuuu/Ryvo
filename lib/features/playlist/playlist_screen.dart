import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/features/player/player_screen.dart';
import 'package:music_app/models/song.dart';

class PlaylistScreen extends StatelessWidget {
  final String playlistName;
  final String subtitle;
  final IconData icon;
  final List<Song> songs;

  const PlaylistScreen({
    super.key,
    required this.playlistName,
    required this.subtitle,
    required this.icon,
    required this.songs,
  });

  void openSong(
      BuildContext context,
      int index,
      ) {
    final song = songs[index];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff070B0C),

      appBar: AppBar(
        backgroundColor: const Color(0xff070B0C),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          playlistName,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ======================================================
          // PLAYLIST HEADER
          // ======================================================

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                20,
              ),
              child: Column(
                children: [
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xffA78BFA),
                          Color(0xff5B21B6),
                        ],
                      ),
                      borderRadius:
                      BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xff8B5CF6,
                          ).withOpacity(0.25),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Text(
                    playlistName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "${songs.length} songs",
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PLAY ALL
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: songs.isEmpty
                          ? null
                          : () {
                        openSong(context, 0);
                      },
                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(
                          0xff8B5CF6,
                        ),
                        disabledBackgroundColor:
                        Colors.white12,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        "Play All",
                        style:
                        GoogleFonts.poppins(
                          color: Colors.white,
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

          // ======================================================
          // SONG LIST
          // ======================================================

          if (songs.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    "No songs in this playlist",
                    style:
                    GoogleFonts.poppins(
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding:
              const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                30,
              ),
              sliver: SliverList(
                delegate:
                SliverChildBuilderDelegate(
                      (context, index) {
                    final song = songs[index];

                    return _songTile(
                      context,
                      song,
                      index,
                    );
                  },
                  childCount: songs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SONG TILE
  // ============================================================

  Widget _songTile(
      BuildContext context,
      Song song,
      int index,
      ) {
    return GestureDetector(
      onTap: () => openSong(
        context,
        index,
      ),
      child: Container(
        margin:
        const EdgeInsets.only(bottom: 10),
        padding:
        const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xff111718),
          borderRadius:
          BorderRadius.circular(17),
          border: Border.all(
            color: Colors.white10,
          ),
        ),
        child: Row(
          children: [
            // NUMBER
            SizedBox(
              width: 25,
              child: Text(
                "${index + 1}",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // IMAGE
            ClipRRect(
              borderRadius:
              BorderRadius.circular(12),
              child: Image.network(
                song.thumbnail,
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) {
                  return Container(
                    width: 55,
                    height: 55,
                    color:
                    const Color(0xff202324),
                    child: const Icon(
                      Icons
                          .music_note_rounded,
                      color: Colors.white54,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 13),

            // TITLE + ARTIST
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
                    style:
                    GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    decode(song.artist),
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // PLAY
            Container(
              width: 38,
              height: 38,
              decoration:
              const BoxDecoration(
                color: Color(0xff8B5CF6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

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