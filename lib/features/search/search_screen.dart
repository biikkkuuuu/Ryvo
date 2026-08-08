import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Search",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onSubmitted: (_) => search(),
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: "Search songs...",
                hintStyle: const TextStyle(
                  color: Colors.white54,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white54,
                ),
                suffixIcon: IconButton(
                  onPressed: search,
                  icon: const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xff181818),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xff8B5CF6),
                  ),
                ),
              ),

            if (!loading)
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final song = results[index];

                    return Card(
                      color: const Color(0xff181818),
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(
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
                          BorderRadius.circular(8),
                          child: Image.network(
                            song.thumbnail,
                            width: 55,
                            height: 55,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Icon(
                                Icons.music_note,
                                color: Colors.white54,
                              );
                            },
                          ),
                        ),

                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                          ),
                        ),

                        trailing: const Icon(
                          Icons.play_circle_fill,
                          color: Color(0xff8B5CF6),
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
    );
  }
}