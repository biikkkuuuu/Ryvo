import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/app/theme_controller.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/audio_service.dart';
import 'package:music_app/services/library_service.dart';
import 'package:music_app/services/lyrics_service.dart';
import 'package:music_app/theme/app_theme.dart';
import 'package:music_app/widgets/song_playlist_picker.dart';

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
  int repeatMode = 0; // 0 = off, 1 = repeat all, 2 = repeat one

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  bool _isDraggingSlider = false;
  double _dragValue = 0.0;
  bool _completionHandled = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.currentIndex;
    activeSong = widget.playlist.isNotEmpty
        ? widget.playlist[currentIndex.clamp(0, widget.playlist.length - 1)]
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
      if (!mounted || _isDraggingSlider) return;
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

  Future<void> startSong() async {
    if (widget.playlist.isEmpty) return;

    final song = activeSong;
    setState(() {
      isLoadingSong = true;
    });

    try {
      await audioService.playSong(
        song.id,
        title: song.title,
        artist: song.artist,
        image: song.thumbnail,
      );
      await LibraryService.instance.addRecentlyPlayed(song);
    } catch (e) {
      debugPrint('Play Song Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSong = false;
        });
      }
    }
  }

  Future<void> togglePlayPause() async {
    HapticFeedback.selectionClick();
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

  Future<void> playNext() async {
    HapticFeedback.lightImpact();
    if (widget.playlist.isEmpty) return;

    if (isShuffle) {
      final nextIndex = (currentIndex + 1) % widget.playlist.length;
      setState(() {
        currentIndex = nextIndex;
        activeSong = widget.playlist[currentIndex];
      });
      await startSong();
      return;
    }

    if (currentIndex < widget.playlist.length - 1) {
      setState(() {
        currentIndex++;
        activeSong = widget.playlist[currentIndex];
      });
      await startSong();
    } else if (repeatMode == 1) {
      setState(() {
        currentIndex = 0;
        activeSong = widget.playlist[0];
      });
      await startSong();
    }
  }

  Future<void> playPrevious() async {
    HapticFeedback.lightImpact();
    if (widget.playlist.isEmpty) return;

    if (currentPosition.inSeconds > 4) {
      await audioService.seek(Duration.zero);
      return;
    }

    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        activeSong = widget.playlist[currentIndex];
      });
      await startSong();
    } else {
      await audioService.seek(Duration.zero);
    }
  }

  void handleSongCompleted() {
    if (repeatMode == 2) {
      startSong();
    } else {
      playNext();
    }
  }

  Future<void> toggleFavorite() async {
    HapticFeedback.selectionClick();
    if (isFavorite) {
      await LibraryService.instance.removeLiked(activeSong.id);
    } else {
      await LibraryService.instance.addLiked(activeSong);
    }
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  void toggleRepeatMode() {
    HapticFeedback.selectionClick();
    setState(() {
      repeatMode = (repeatMode + 1) % 3;
    });
  }

  void toggleShuffle() {
    HapticFeedback.selectionClick();
    setState(() {
      isShuffle = !isShuffle;
    });
  }

  void _showQueueSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Playback Queue',
                        style: GoogleFonts.plusJakartaSans(
                          color: SpotifyColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${widget.playlist.length} tracks',
                        style: GoogleFonts.plusJakartaSans(
                          color: SpotifyColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: widget.playlist.length,
                    itemBuilder: (context, index) {
                      final item = widget.playlist[index];
                      final isCurrent = index == currentIndex;
                      final currentTheme = RyvoThemeController.themes[
                          RyvoThemeController.instance.selectedTheme];

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: item.thumbnail.isNotEmpty
                                ? Image.network(item.thumbnail, fit: BoxFit.cover)
                                : Container(color: SpotifyColors.surfaceElevated),
                          ),
                        ),
                        title: Text(
                          decodeHtml(item.title),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: isCurrent ? currentTheme.primary : SpotifyColors.textPrimary,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          decodeHtml(item.artist),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: SpotifyColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: isCurrent
                            ? Icon(Icons.volume_up_rounded, color: currentTheme.primary, size: 20)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            currentIndex = index;
                            activeSong = widget.playlist[index];
                          });
                          startSong();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLyricsSheet() {
    final title = decodeHtml(activeSong.title);
    final artist = decodeHtml(activeSong.artist);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return FutureBuilder<LyricsResult?>(
              future: lyricsService.getLyrics(title: title, artist: artist),
              builder: (context, snapshot) {
                final lyricsData = snapshot.data;
                final rawLyrics = lyricsData?.plainLyrics.isNotEmpty == true
                    ? lyricsData!.plainLyrics
                    : (lyricsData?.syncedLyrics ?? '');
                final lines = rawLyrics.isNotEmpty
                    ? rawLyrics
                        .split('\n')
                        .map((l) => l.replaceAll(RegExp(r'\[.*?\]'), '').trim())
                        .where((l) => l.isNotEmpty)
                        .toList()
                    : <String>[];

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lyrics',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: SpotifyColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '$title • $artist',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: SpotifyColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    Expanded(
                      child: snapshot.connectionState == ConnectionState.waiting
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: SpotifyColors.green,
                              ),
                            )
                          : lines.isEmpty
                              ? Center(
                                  child: Text(
                                    'Lyrics not available for this track.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: SpotifyColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  itemCount: lines.length,
                                  itemBuilder: (context, index) {
                                    final line = lines[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        line,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          height: 1.4,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = RyvoThemeController.themes[
        RyvoThemeController.instance.selectedTheme];

    final safePosition = _isDraggingSlider
        ? Duration(milliseconds: _dragValue.toInt())
        : currentPosition;

    return Scaffold(
      backgroundColor: SpotifyColors.background,
      body: Stack(
        children: [
          // Dynamic Ambient Glow
          Positioned(
            top: -120,
            left: -40,
            right: -40,
            height: 480,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    currentTheme.primaryDark.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Top App Bar
                  SizedBox(
                    height: 52,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 34,
                            color: SpotifyColors.textPrimary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'PLAYING FROM PLAYLIST',
                                style: GoogleFonts.plusJakartaSans(
                                  color: SpotifyColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                decodeHtml(activeSong.artist),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  color: SpotifyColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 24,
                            color: SpotifyColors.textPrimary,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: SpotifyColors.surfaceElevated,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              builder: (_) => SongPlaylistPicker(song: activeSong),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Center Square 1:1 Album Artwork (Spotify Style)
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.82,
                      height: MediaQuery.of(context).size.width * 0.82,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.65),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: activeSong.thumbnail.isNotEmpty
                            ? Image.network(
                                activeSong.thumbnail,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: SpotifyColors.surfaceElevated,
                                  child: const Icon(
                                    Icons.music_note_rounded,
                                    color: SpotifyColors.textSecondary,
                                    size: 64,
                                  ),
                                ),
                              )
                            : Container(
                                color: SpotifyColors.surfaceElevated,
                                child: const Icon(
                                  Icons.music_note_rounded,
                                  color: SpotifyColors.textSecondary,
                                  size: 64,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Track Info & Like Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              decodeHtml(activeSong.title),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: SpotifyColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              decodeHtml(activeSong.artist),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: SpotifyColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        splashRadius: 24,
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite ? currentTheme.primary : SpotifyColors.textSecondary,
                          size: 28,
                        ),
                        onPressed: toggleFavorite,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Custom Spotify Seekbar
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.5,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          activeTrackColor: currentTheme.primary,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: SpotifyColors.textPrimary,
                        ),
                        child: Slider(
                          min: 0.0,
                          max: (totalDuration.inMilliseconds > 0)
                              ? totalDuration.inMilliseconds.toDouble()
                              : 1.0,
                          value: (safePosition.inMilliseconds.toDouble())
                              .clamp(0.0, (totalDuration.inMilliseconds > 0 ? totalDuration.inMilliseconds.toDouble() : 1.0)),
                          onChangeStart: (value) {
                            setState(() {
                              _isDraggingSlider = true;
                              _dragValue = value;
                            });
                          },
                          onChanged: (value) {
                            setState(() {
                              _dragValue = value;
                            });
                          },
                          onChangeEnd: (value) async {
                            final target = Duration(milliseconds: value.toInt());
                            await audioService.seek(target);
                            setState(() {
                              _isDraggingSlider = false;
                              currentPosition = target;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatDuration(safePosition),
                              style: GoogleFonts.plusJakartaSans(
                                color: SpotifyColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '-${formatDuration(totalDuration - safePosition > Duration.zero ? totalDuration - safePosition : Duration.zero)}',
                              style: GoogleFonts.plusJakartaSans(
                                color: SpotifyColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Playback Controls Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Shuffle
                      IconButton(
                        splashRadius: 22,
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: isShuffle ? currentTheme.primary : SpotifyColors.textSecondary,
                          size: 24,
                        ),
                        onPressed: toggleShuffle,
                      ),

                      // Previous
                      IconButton(
                        splashRadius: 26,
                        icon: const Icon(
                          Icons.skip_previous_rounded,
                          color: SpotifyColors.textPrimary,
                          size: 38,
                        ),
                        onPressed: playPrevious,
                      ),

                      // Big Circular Play / Pause Button
                      GestureDetector(
                        onTap: togglePlayPause,
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentTheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: currentTheme.primary.withValues(alpha: 0.35),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: isLoadingSong
                                ? const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.black,
                                    size: 38,
                                  ),
                          ),
                        ),
                      ),

                      // Next
                      IconButton(
                        splashRadius: 26,
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: SpotifyColors.textPrimary,
                          size: 38,
                        ),
                        onPressed: playNext,
                      ),

                      // Repeat
                      IconButton(
                        splashRadius: 22,
                        icon: Icon(
                          repeatMode == 2
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          color: repeatMode > 0 ? currentTheme.primary : SpotifyColors.textSecondary,
                          size: 24,
                        ),
                        onPressed: toggleRepeatMode,
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // Bottom Action Buttons (Lyrics & Queue)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _showLyricsSheet,
                        icon: const Icon(
                          Icons.lyrics_rounded,
                          color: SpotifyColors.textSecondary,
                          size: 18,
                        ),
                        label: Text(
                          'Lyrics',
                          style: GoogleFonts.plusJakartaSans(
                            color: SpotifyColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        splashRadius: 22,
                        icon: const Icon(
                          Icons.queue_music_rounded,
                          color: SpotifyColors.textSecondary,
                          size: 24,
                        ),
                        onPressed: _showQueueSheet,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
