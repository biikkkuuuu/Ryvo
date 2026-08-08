import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/services/audio_service.dart';
import 'package:music_app/models/song.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String artist;
  final String image;
  final String songId;

  final List<Song> playlist;
  final int currentIndex;

  const PlayerScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.image,
    required this.songId,
    required this.playlist,
    required this.currentIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioService audioService = AudioService();

  late int currentIndex;

  bool isPlaying = false;
  bool isLoadingSong = false;

  bool isShuffle = false;
  bool isFavorite = false;

  // 0 = OFF
  // 1 = REPEAT ALL
  // 2 = REPEAT ONE
  int repeatMode = 0;

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  DateTime lastPlaybackTap =
  DateTime.fromMillisecondsSinceEpoch(0);

  bool completionHandled = false;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.currentIndex;

    startSong();

    // ==========================================
    // PLAYER STATE
    // ==========================================

    audioService.audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;

      setState(() {
        isPlaying = state.playing;
      });

      if (state.processingState.toString().contains("completed")) {
        if (!completionHandled) {
          completionHandled = true;
          handleSongCompleted();
        }
      } else {
        completionHandled = false;
      }
    });

    // ==========================================
    // POSITION
    // ==========================================

    audioService.positionStream.listen((position) {
      if (!mounted) return;

      setState(() {
        currentPosition = position;
      });
    });

    // ==========================================
    // DURATION
    // ==========================================

    audioService.durationStream.listen((duration) {
      if (!mounted) return;

      if (duration != null && duration > Duration.zero) {
        setState(() {
          totalDuration = duration;
          isLoadingSong = false;
        });
      }
    });
  }

  // ==========================================
  // START SONG
  // ==========================================

  Future<void> startSong() async {
    try {
      await audioService.playSong(
        widget.playlist[currentIndex].id,
      );
    } catch (e) {
      debugPrint("Start Song Error: $e");
    }
  }

  @override
  void dispose() {
    audioService.dispose();
    super.dispose();
  }

  // ==========================================
  // DECODE HTML
  // ==========================================

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
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', '/');
  }

  // ==========================================
  // FORMAT TIME
  // ==========================================

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  // ==========================================
  // PLAY / PAUSE
  // ==========================================

  Future<void> togglePlayPause() async {
    final now = DateTime.now();

    if (now.difference(lastPlaybackTap).inMilliseconds < 300) {
      return;
    }

    lastPlaybackTap = now;

    try {
      if (audioService.audioPlayer.playing) {
        await audioService.pause();
      } else {
        await audioService.resume();
      }
    } catch (e) {
      debugPrint("Play Pause Error: $e");
    }
  }

  // ==========================================
  // NEXT SONG
  // ==========================================

  Future<void> playNext() async {
    if (widget.playlist.isEmpty || isLoadingSong) {
      return;
    }

    int nextIndex;

    if (isShuffle) {
      if (widget.playlist.length <= 1) {
        return;
      }

      final random = Random();

      do {
        nextIndex = random.nextInt(
          widget.playlist.length,
        );
      } while (nextIndex == currentIndex);
    } else {
      if (currentIndex >=
          widget.playlist.length - 1) {
        if (repeatMode == 1) {
          nextIndex = 0;
        } else {
          return;
        }
      } else {
        nextIndex = currentIndex + 1;
      }
    }

    currentIndex = nextIndex;

    await playCurrentSong();
  }

  // ==========================================
  // PREVIOUS SONG
  // ==========================================

  Future<void> playPrevious() async {
    if (widget.playlist.isEmpty || isLoadingSong) {
      return;
    }

    if (currentPosition.inSeconds > 3) {
      await audioService.seek(Duration.zero);
      return;
    }

    if (currentIndex <= 0) {
      if (repeatMode == 1) {
        currentIndex =
            widget.playlist.length - 1;

        await playCurrentSong();
      } else {
        await audioService.seek(Duration.zero);
      }

      return;
    }

    currentIndex--;

    await playCurrentSong();
  }

  // ==========================================
  // PLAY CURRENT SONG
  // ==========================================

  Future<void> playCurrentSong() async {
    final song = widget.playlist[currentIndex];

    setState(() {
      isLoadingSong = true;
      currentPosition = Duration.zero;
      totalDuration = Duration.zero;
      isPlaying = false;
      completionHandled = false;
    });

    try {
      await audioService.playSong(song.id);
    } catch (e) {
      debugPrint("Song Change Error: $e");

      if (!mounted) return;

      setState(() {
        isLoadingSong = false;
      });
    }
  }

  // ==========================================
  // SONG COMPLETED
  // ==========================================

  Future<void> handleSongCompleted() async {
    if (!mounted || widget.playlist.isEmpty) {
      return;
    }

    // REPEAT ONE
    if (repeatMode == 2) {
      await playCurrentSong();
      return;
    }

    // SHUFFLE
    if (isShuffle) {
      await playNext();
      return;
    }

    // NORMAL NEXT
    if (currentIndex <
        widget.playlist.length - 1) {
      currentIndex++;
      await playCurrentSong();
      return;
    }

    // REPEAT ALL
    if (repeatMode == 1) {
      currentIndex = 0;
      await playCurrentSong();
    }
  }

  // ==========================================
  // SHUFFLE
  // ==========================================

  void toggleShuffle() {
    setState(() {
      isShuffle = !isShuffle;
    });
  }

  // ==========================================
  // FAVORITE
  // ==========================================

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  // ==========================================
  // REPEAT
  // ==========================================

  void toggleRepeat() {
    setState(() {
      repeatMode++;

      if (repeatMode > 2) {
        repeatMode = 0;
      }
    });
  }

  // ==========================================
  // REPEAT ICON
  // ==========================================

  IconData get repeatIcon {
    if (repeatMode == 2) {
      return Icons.repeat_one_rounded;
    }

    return Icons.repeat_rounded;
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final song = widget.playlist[currentIndex];

    final screenHeight =
        MediaQuery.of(context).size.height;

    double albumSize;

    if (screenHeight < 700) {
      albumSize = screenHeight * 0.39;
    } else if (screenHeight < 800) {
      albumSize = screenHeight * 0.42;
    } else {
      albumSize = screenHeight * 0.46;
    }

    return Scaffold(
      backgroundColor: Colors.black,

      // ========================================
      // APP BAR
      // ========================================

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),

        title: Text(
          "Now Playing",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),

      // ========================================
      // BODY
      // ========================================

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            22,
            8,
            22,
            10,
          ),

          child: Column(
            children: [
              // ==================================
              // ALBUM ART
              // ==================================

              SizedBox(
                width: albumSize,
                height: albumSize,

                child: ClipRRect(
                  borderRadius:
                  BorderRadius.circular(28),

                  child: Image.network(
                    song.thumbnail,

                    fit: BoxFit.cover,

                    errorBuilder: (_, __, ___) {
                      return Container(
                        color:
                        const Color(0xff181818),

                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white54,
                          size: 70,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================
              // SONG TITLE
              // ==================================

              Text(
                decodeHtml(song.title),

                textAlign: TextAlign.center,

                maxLines: 2,

                overflow:
                TextOverflow.ellipsis,

                style: GoogleFonts.poppins(
                  color: Colors.white,

                  fontSize:
                  screenHeight < 700
                      ? 20
                      : 22,

                  fontWeight: FontWeight.w700,

                  height: 1.2,
                ),
              ),

              const SizedBox(height: 5),

              // ==================================
              // ARTIST
              // ==================================

              Text(
                decodeHtml(song.artist),

                textAlign: TextAlign.center,

                maxLines: 1,

                overflow:
                TextOverflow.ellipsis,

                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 12),

              // ==================================
              // PROGRESS
              // ==================================

              if (isLoadingSong)
                const SizedBox(
                  height: 38,

                  child: Center(
                    child: SizedBox(
                      width: 17,
                      height: 17,

                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                        Color(0xff8B5CF6),
                      ),
                    ),
                  ),
                )
              else
                SliderTheme(
                  data:
                  SliderTheme.of(context)
                      .copyWith(
                    trackHeight: 4,

                    thumbShape:
                    const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),

                    overlayShape:
                    const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                  ),

                  child: Slider(
                    value: currentPosition
                        .inSeconds
                        .toDouble()
                        .clamp(
                      0,
                      totalDuration
                          .inSeconds ==
                          0
                          ? 1
                          : totalDuration
                          .inSeconds
                          .toDouble(),
                    ),

                    min: 0,

                    max: totalDuration
                        .inSeconds ==
                        0
                        ? 1
                        : totalDuration
                        .inSeconds
                        .toDouble(),

                    activeColor:
                    const Color(0xff8B5CF6),

                    inactiveColor:
                    Colors.white24,

                    onChanged:
                        (value) async {
                      try {
                        await audioService.seek(
                          Duration(
                            seconds:
                            value.toInt(),
                          ),
                        );
                      } catch (e) {
                        debugPrint(
                          "Seek Error: $e",
                        );
                      }
                    },
                  ),
                ),

              // ==================================
              // TIME
              // ==================================

              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 4,
                ),

                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

                  children: [
                    Text(
                      formatDuration(
                        currentPosition,
                      ),

                      style:
                      GoogleFonts.poppins(
                        color:
                        Colors.white54,
                        fontSize: 12,
                      ),
                    ),

                    Text(
                      formatDuration(
                        totalDuration,
                      ),

                      style:
                      GoogleFonts.poppins(
                        color:
                        Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ==================================
              // MAIN CONTROLS
              // ==================================

              Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .spaceEvenly,

                children: [
                  // PREVIOUS
                  IconButton(
                    onPressed:
                    isLoadingSong
                        ? null
                        : playPrevious,

                    icon: const Icon(
                      Icons
                          .skip_previous_rounded,

                      color: Colors.white,

                      size: 42,
                    ),
                  ),

                  // PLAY / PAUSE
                  Container(
                    width: 78,
                    height: 78,

                    decoration:
                    const BoxDecoration(
                      color:
                      Color(0xff8B5CF6),

                      shape: BoxShape.circle,
                    ),

                    child: IconButton(
                      onPressed:
                      isLoadingSong
                          ? null
                          : togglePlayPause,

                      icon: Icon(
                        isPlaying
                            ? Icons
                            .pause_rounded
                            : Icons
                            .play_arrow_rounded,

                        color: Colors.white,

                        size: 42,
                      ),
                    ),
                  ),

                  // NEXT
                  IconButton(
                    onPressed:
                    isLoadingSong
                        ? null
                        : playNext,

                    icon: const Icon(
                      Icons
                          .skip_next_rounded,

                      color: Colors.white,

                      size: 42,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ==================================
              // SECONDARY CONTROLS
              // ==================================

              Row(
                mainAxisAlignment:
                MainAxisAlignment.center,

                children: [
                  // SHUFFLE
                  _premiumControlButton(
                    icon:
                    Icons.shuffle_rounded,

                    label: isShuffle
                        ? "Shuffle"
                        : null,

                    active: isShuffle,

                    onTap: toggleShuffle,
                  ),

                  const SizedBox(width: 10),

                  // FAVORITE
                  _premiumControlButton(
                    icon: isFavorite
                        ? Icons.favorite_rounded
                        : Icons
                        .favorite_border_rounded,

                    label: isFavorite
                        ? "Liked"
                        : null,

                    active: isFavorite,

                    onTap: toggleFavorite,
                  ),

                  const SizedBox(width: 10),

                  // REPEAT
                  _premiumControlButton(
                    icon: repeatIcon,

                    label: repeatMode == 1
                        ? "Repeat All"
                        : repeatMode == 2
                        ? "Repeat One"
                        : null,

                    active: repeatMode != 0,

                    onTap: toggleRepeat,
                  ),
                ],
              ),

              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // PREMIUM SECONDARY BUTTON
  // ==========================================

  Widget _premiumControlButton({
    required IconData icon,
    required String? label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 220),

        curve: Curves.easeOut,

        padding: EdgeInsets.symmetric(
          horizontal:
          label != null ? 14 : 0,
        ),

        width:
        label != null ? 105 : 52,

        height: 52,

        decoration: BoxDecoration(
          color: active
              ? const Color(0xff8B5CF6)
              .withOpacity(0.16)
              : const Color(0xff151515),

          borderRadius:
          BorderRadius.circular(18),

          border: Border.all(
            color: active
                ? const Color(0xff8B5CF6)
                : Colors.white12,

            width: 1,
          ),
        ),

        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,

          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(
              icon,

              color: active
                  ? const Color(0xffA87CFF)
                  : Colors.white60,

              size: 23,
            ),

            if (label != null) ...[
              const SizedBox(width: 7),

              Flexible(
                child: Text(
                  label,

                  maxLines: 1,

                  overflow:
                  TextOverflow.ellipsis,

                  style:
                  GoogleFonts.poppins(
                    color:
                    const Color(
                        0xffA87CFF),

                    fontSize: 11,

                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}