import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/audio_service.dart';
import 'package:music_app/services/library_service.dart';

import '../../services/lyrics_service.dart';

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
  final LyricsService lyricsService = LyricsService();

  late int currentIndex;
  late Song activeSong;

  bool isPlaying = false;
  bool isLoadingSong = false;
  bool isShuffle = false;
  bool isFavorite = false;

  int repeatMode = 0;

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  bool _completionHandled = false;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.currentIndex;

    activeSong = widget.playlist.isNotEmpty
        ? widget.playlist[currentIndex]
        : Song(
            id: widget.songId,
            title: widget.title,
            artist: widget.artist,
            thumbnail: widget.image,
          );

    _initialize();
  }

  Future<void> _initialize() async {
    await LibraryService.instance.init();

    if (!mounted || widget.playlist.isEmpty) return;

    setState(() {
      isFavorite = LibraryService.instance.isLiked(activeSong.id);
    });

    _listenToPlayer();

    audioService.setPlaybackQueue(widget.playlist, currentIndex: currentIndex);

    final current = audioService.currentSong.value;

    if (current?.id == activeSong.id &&
        audioService.audioPlayer.duration != null) {
      if (!mounted) return;

      setState(() {
        activeSong = current!;
        isPlaying = audioService.audioPlayer.playing;
        currentPosition = audioService.currentPosition;
        totalDuration = audioService.totalDuration ?? Duration.zero;
      });

      return;
    }

    await startSong();
  }

  void _listenToPlayer() {
    _stateSub = audioService.playerStateStream.listen((state) {
      if (!mounted) return;

      setState(() {
        isPlaying = state.playing;
      });

      if (state.processingState == ProcessingState.completed) {
        if (!_completionHandled) {
          _completionHandled = true;
          handleSongCompleted();
        }
      } else {
        _completionHandled = false;
      }
    });

    _positionSub = audioService.positionStream.listen((position) {
      if (!mounted) return;

      setState(() {
        currentPosition = position;
      });
    });

    _durationSub = audioService.durationStream.listen((duration) {
      if (!mounted || duration == null) return;

      setState(() {
        totalDuration = duration;
        isLoadingSong = false;
      });
    });

    audioService.currentSong.addListener(_onCurrentSongChanged);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();

    audioService.currentSong.removeListener(_onCurrentSongChanged);

    super.dispose();
  }

  void _onCurrentSongChanged() {
    final song = audioService.currentSong.value;

    if (!mounted || song == null) return;

    final playlistIndex = widget.playlist.indexWhere(
      (item) => item.id == song.id,
    );

    setState(() {
      activeSong = song;

      if (playlistIndex >= 0) {
        currentIndex = playlistIndex;
      }

      isFavorite = LibraryService.instance.isLiked(song.id);
      isLoadingSong = false;
    });
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

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> togglePlayPause() async {
    try {
      if (audioService.audioPlayer.playing) {
        await audioService.pause();
      } else {
        await audioService.resume();
      }
    } catch (e) {
      debugPrint('Play/Pause Error: $e');
    }
  }

  // ============================================================
  // LYRICS
  // ============================================================

  Future<void> showLyrics() async {
    final title = decodeHtml(activeSong.title);
    final artist = decodeHtml(activeSong.artist);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff0f0f0f),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return _LyricsSheet(
          lyricsService: lyricsService,
          title: title,
          artist: artist,
          positionStream: audioService.positionStream,
        );
      },
    );
  }

  // ============================================================
  // START SONG
  // ============================================================

  Future<void> startSong() async {
    if (widget.playlist.isEmpty) return;

    final song = activeSong;
    final current = audioService.currentSong.value;

    if (current?.id == song.id && audioService.audioPlayer.duration != null) {
      if (mounted) {
        setState(() {
          isPlaying = audioService.audioPlayer.playing;
          isLoadingSong = false;
        });
      }

      return;
    }

    if (mounted) {
      setState(() {
        isLoadingSong = true;
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
        _completionHandled = false;
      });
    }

    try {
      await audioService.playSong(
        song.id,
        title: decodeHtml(song.title),
        artist: decodeHtml(song.artist),
        image: song.thumbnail,
        clearQueue: false,
      );

      if (!mounted) return;

      setState(() {
        isFavorite = LibraryService.instance.isLiked(song.id);
      });
    } catch (e) {
      debugPrint('Start Song Error: $e');

      if (mounted) {
        setState(() {
          isLoadingSong = false;
        });
      }
    }
  }

  // ============================================================
  // NEXT
  // ============================================================

  Future<void> playNext() async {
    if (isLoadingSong) return;

    if (audioService.queue.value.isNotEmpty) {
      await audioService.skipToNext();
      return;
    }

    if (widget.playlist.isEmpty) return;

    int nextIndex;

    if (isShuffle) {
      if (widget.playlist.length <= 1) return;

      final random = Random();

      do {
        nextIndex = random.nextInt(widget.playlist.length);
      } while (nextIndex == currentIndex);
    } else {
      if (currentIndex >= widget.playlist.length - 1) {
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
    activeSong = widget.playlist[currentIndex];

    await playCurrentSong();
  }

  // ============================================================
  // PREVIOUS
  // ============================================================

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
        currentIndex = widget.playlist.length - 1;
        activeSong = widget.playlist[currentIndex];

        await playCurrentSong();
      } else {
        await audioService.seek(Duration.zero);
      }

      return;
    }

    currentIndex--;
    activeSong = widget.playlist[currentIndex];

    await playCurrentSong();
  }

  // ============================================================
  // PLAY CURRENT
  // ============================================================

  Future<void> playCurrentSong() async {
    if (widget.playlist.isEmpty) return;

    final song = activeSong;

    if (mounted) {
      setState(() {
        isLoadingSong = true;
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
        isPlaying = false;
        _completionHandled = false;
        isFavorite = LibraryService.instance.isLiked(song.id);
      });
    }

    try {
      await audioService.playSong(
        song.id,
        title: decodeHtml(song.title),
        artist: decodeHtml(song.artist),
        image: song.thumbnail,
        clearQueue: false,
      );
    } catch (e) {
      debugPrint('Song Change Error: $e');

      if (mounted) {
        setState(() {
          isLoadingSong = false;
        });
      }
    }
  }

  // ============================================================
  // COMPLETION
  // ============================================================

  Future<void> handleSongCompleted() async {
    if (!mounted) return;

    if (audioService.queue.value.isNotEmpty) {
      await audioService.skipToNext();
      return;
    }

    if (repeatMode == 2) {
      await playCurrentSong();
      return;
    }

    if (isShuffle) {
      await playNext();
      return;
    }

    if (currentIndex < widget.playlist.length - 1) {
      currentIndex++;
      activeSong = widget.playlist[currentIndex];

      await playCurrentSong();
      return;
    }

    if (repeatMode == 1) {
      currentIndex = 0;
      activeSong = widget.playlist[currentIndex];

      await playCurrentSong();
    }
  }

  // ============================================================
  // FAVORITE
  // ============================================================

  Future<void> toggleFavorite() async {
    final liked = await LibraryService.instance.toggleLike(activeSong);

    if (!mounted) return;

    setState(() {
      isFavorite = liked;
    });
  }

  // ============================================================
  // QUEUE
  // ============================================================

  void addCurrentToQueue() {
    audioService.addToQueue(activeSong);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${decodeHtml(activeSong.title)} added to queue'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void addCurrentToQueueNext() {
    audioService.addToQueueNext(activeSong);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${decodeHtml(activeSong.title)} will play next'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void showQueue() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return ValueListenableBuilder<List<Song>>(
          valueListenable: audioService.queue,
          builder: (context, queue, _) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * .65,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            'Up Next',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${queue.length})',
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (queue.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                audioService.clearQueueItems();
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: Color(0xffA78BFA)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    if (queue.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.queue_music_rounded,
                                color: Colors.white30,
                                size: 55,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Queue is empty',
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: queue.length,
                          itemBuilder: (context, index) {
                            final queuedSong = queue[index];

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 4,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: queuedSong.thumbnail.trim().isEmpty
                                      ? Container(
                                          color: const Color(0xff252525),
                                          child: const Icon(
                                            Icons.music_note_rounded,
                                            color: Colors.white54,
                                          ),
                                        )
                                      : Image.network(
                                          queuedSong.thumbnail,
                                          fit: BoxFit.cover,
                                          cacheWidth: 104,
                                          cacheHeight: 104,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                color: const Color(0xff252525),
                                                child: const Icon(
                                                  Icons.music_note_rounded,
                                                  color: Colors.white54,
                                                ),
                                              ),
                                        ),
                                ),
                              ),
                              title: Text(
                                decodeHtml(queuedSong.title),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                decodeHtml(queuedSong.artist),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                              trailing: IconButton(
                                onPressed: () {
                                  audioService.removeFromQueue(queuedSong);
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white54,
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
          },
        );
      },
    );
  }

  // ============================================================
  // SHUFFLE / REPEAT
  // ============================================================

  void toggleShuffle() {
    setState(() {
      isShuffle = !isShuffle;
    });
  }

  void toggleRepeat() {
    setState(() {
      repeatMode++;

      if (repeatMode > 2) {
        repeatMode = 0;
      }
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (widget.playlist.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No song available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final song = activeSong;

    final height = MediaQuery.of(context).size.height;

    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    final availableHeight = height - topInset;

    final albumSize = availableHeight < 700
        ? availableHeight * .39
        : availableHeight < 800
        ? availableHeight * .42
        : availableHeight * .46;

    final maxValue = totalDuration.inSeconds <= 0
        ? 1.0
        : totalDuration.inSeconds.toDouble();

    final sliderValue = currentPosition.inSeconds.toDouble().clamp(
      0.0,
      maxValue,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Now Playing',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Lyrics',
            onPressed: showLyrics,
            icon: const Icon(
              Icons.lyrics_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          IconButton(
            tooltip: 'Queue',
            onPressed: showQueue,
            icon: ValueListenableBuilder<List<Song>>(
              valueListenable: audioService.queue,
              builder: (context, queue, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.queue_music_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                    if (queue.isNotEmpty)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 17,
                            minHeight: 17,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xff8B5CF6),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${queue.length}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      // ============================================================
      // BLURRED ALBUM ART BACKGROUND
      // ============================================================
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: Container(color: const Color(0xff0d0d0d))),

          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
              child: Image.network(
                song.thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(color: const Color(0xff0d0d0d));
                },
              ),
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.70),
                  ],
                  stops: const [0.0, 0.35, 0.7, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 10),
              child: Column(
                children: [
                  SizedBox(height: kToolbarHeight),

                  SizedBox(
                    width: albumSize,
                    height: albumSize,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: song.thumbnail.trim().isEmpty
                          ? Container(
                              color: const Color(0xff181818),
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: Colors.white54,
                                size: 70,
                              ),
                            )
                          : Image.network(
                              song.thumbnail,
                              fit: BoxFit.cover,
                              cacheWidth: 700,
                              cacheHeight: 700,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  color: const Color(0xff181818),
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

                  Text(
                    decodeHtml(song.title),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: availableHeight < 700 ? 20 : 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    decodeHtml(song.artist),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (isLoadingSong)
                    const SizedBox(
                      height: 38,
                      child: Center(
                        child: SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xff8B5CF6),
                          ),
                        ),
                      ),
                    )
                  else
                    Slider(
                      value: sliderValue,
                      min: 0,
                      max: maxValue,
                      activeColor: const Color(0xff8B5CF6),
                      inactiveColor: Colors.white24,
                      onChanged: (value) {
                        audioService.seek(Duration(seconds: value.toInt()));
                      },
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDuration(currentPosition),
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          formatDuration(totalDuration),
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: isLoadingSong ? null : playPrevious,
                        icon: const Icon(
                          Icons.skip_previous_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),

                      Container(
                        width: 78,
                        height: 78,
                        decoration: const BoxDecoration(
                          color: Color(0xff8B5CF6),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: isLoadingSong ? null : togglePlayPause,
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: isLoadingSong ? null : playNext,
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _control(Icons.shuffle_rounded, isShuffle, toggleShuffle),

                      const SizedBox(width: 8),

                      _control(
                        Icons.playlist_add_rounded,
                        false,
                        addCurrentToQueue,
                      ),

                      const SizedBox(width: 8),

                      _control(
                        Icons.playlist_play_rounded,
                        false,
                        addCurrentToQueueNext,
                      ),

                      const SizedBox(width: 8),

                      _control(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        isFavorite,
                        toggleFavorite,
                      ),

                      const SizedBox(width: 8),

                      _control(
                        repeatMode == 2
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        repeatMode != 0,
                        toggleRepeat,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _control(IconData icon, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xff8B5CF6).withValues(alpha: .16)
              : const Color(0xff151515),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? const Color(0xff8B5CF6) : Colors.white12,
          ),
        ),
        child: Icon(
          icon,
          color: active ? const Color(0xffA87CFF) : Colors.white60,
          size: 22,
        ),
      ),
    );
  }
}

// ================================================================
// LYRICS SHEET
// ================================================================

class _LyricsSheet extends StatefulWidget {
  final LyricsService lyricsService;
  final String title;
  final String artist;
  final Stream<Duration> positionStream;

  const _LyricsSheet({
    required this.lyricsService,
    required this.title,
    required this.artist,
    required this.positionStream,
  });

  @override
  State<_LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<_LyricsSheet> {
  late Future<LyricsResult?> _lyricsFuture;
  StreamSubscription<Duration>? _positionSub;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();

    _lyricsFuture = widget.lyricsService.getLyrics(
      title: widget.title,
      artist: widget.artist,
    );

    _positionSub = widget.positionStream.listen((position) {
      if (!mounted) return;

      setState(() {
        _currentPosition = position;
      });
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .78,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  const Icon(
                    Icons.lyrics_rounded,
                    color: Color(0xffA87CFF),
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lyrics',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: FutureBuilder<LyricsResult?>(
                future: _lyricsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff8B5CF6),
                      ),
                    );
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data == null) {
                    return _emptyLyrics();
                  }

                  final lyrics = snapshot.data!;
                  final synced = lyrics.syncedLyrics;

                  if (synced != null && synced.trim().isNotEmpty) {
                    return _SyncedLyricsView(
                      lyrics: synced,
                      currentPosition: _currentPosition,
                    );
                  }

                  if (lyrics.plainLyrics.trim().isNotEmpty) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                      child: Text(
                        lyrics.plainLyrics,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  return _emptyLyrics();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyLyrics() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lyrics_outlined, color: Colors.white30, size: 60),
            const SizedBox(height: 16),
            Text(
              'Lyrics not available',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Lyrics could not be found for this song.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SYNCED LYRICS
// ================================================================

class _SyncedLyricLine {
  final Duration time;
  final String text;

  const _SyncedLyricLine({required this.time, required this.text});
}

class _SyncedLyricsView extends StatefulWidget {
  final String lyrics;
  final Duration currentPosition;

  const _SyncedLyricsView({
    required this.lyrics,
    required this.currentPosition,
  });

  @override
  State<_SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<_SyncedLyricsView> {
  late List<_SyncedLyricLine> lines;

  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    lines = _parseLyrics(widget.lyrics);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateActiveLine(force: true);
    });
  }

  @override
  void didUpdateWidget(covariant _SyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.lyrics != widget.lyrics) {
      lines = _parseLyrics(widget.lyrics);
      _lastActiveIndex = -1;
    }

    _updateActiveLine();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Text(
          widget.lyrics,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
            height: 1.8,
          ),
        ),
      );
    }

    final currentIndex = _activeIndex();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(22, 110, 22, 180),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 9),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            style: GoogleFonts.poppins(
              color: isActive ? Colors.white : Colors.white38,
              fontSize: isActive ? 21 : 16,
              height: 1.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            child: Text(lines[index].text),
          ),
        );
      },
    );
  }

  int _activeIndex() {
    var active = -1;

    for (var i = 0; i < lines.length; i++) {
      if (lines[i].time <= widget.currentPosition) {
        active = i;
      } else {
        break;
      }
    }

    return active;
  }

  void _updateActiveLine({bool force = false}) {
    if (!mounted) return;

    final index = _activeIndex();

    if (!force && index == _lastActiveIndex) {
      return;
    }

    _lastActiveIndex = index;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToActiveLine(index);
    });
  }

  void _scrollToActiveLine(int index) {
    if (index < 0 || !_scrollController.hasClients) {
      return;
    }

    final viewportHeight = _scrollController.position.viewportDimension;

    const itemHeight = 55.0;

    final target =
        (index * itemHeight) - (viewportHeight * 0.5) + (itemHeight * 0.5);

    final maxScroll = _scrollController.position.maxScrollExtent;

    _scrollController.animateTo(
      target.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  List<_SyncedLyricLine> _parseLyrics(String raw) {
    final result = <_SyncedLyricLine>[];

    final regex = RegExp(r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]\s*(.*)');

    for (final rawLine in raw.split('\n')) {
      final match = regex.firstMatch(rawLine);

      if (match == null) continue;

      final minutes = int.tryParse(match.group(1) ?? '');
      final seconds = int.tryParse(match.group(2) ?? '');

      if (minutes == null || seconds == null) continue;

      final fractionText = match.group(3);
      var milliseconds = 0;

      if (fractionText != null && fractionText.isNotEmpty) {
        if (fractionText.length == 1) {
          milliseconds = int.parse(fractionText) * 100;
        } else if (fractionText.length == 2) {
          milliseconds = int.parse(fractionText) * 10;
        } else {
          milliseconds = int.parse(fractionText.substring(0, 3));
        }
      }

      final lyricText = match.group(4)?.trim() ?? '';

      if (lyricText.isEmpty) continue;

      result.add(
        _SyncedLyricLine(
          time: Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          ),
          text: lyricText,
        ),
      );
    }

    result.sort((a, b) => a.time.compareTo(b.time));

    return result;
  }
}
