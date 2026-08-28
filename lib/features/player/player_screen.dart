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

class LyricLine {
  final Duration time;
  final String text;
  LyricLine({required this.time, required this.text});
}

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

  bool _isDraggingSlider = false;
  double _dragValue = 0.0;
  bool _completionHandled = false;

  bool _isLyricsMode = false;
  bool _isLoadingLyrics = false;
  bool _isSyncedLyrics = false;
  List<LyricLine> _parsedLyrics = [];
  final ScrollController _lyricsScrollController = ScrollController();
  int _lastActiveLyricIndex = -1;
  final List<GlobalKey> _lyricKeys = [];

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
    _fetchLyrics();

    audioService.setPlaybackQueue(widget.playlist, currentIndex: currentIndex);

    final current = audioService.currentSong.value;
    if (current?.id == activeSong.id && audioService.audioPlayer.duration != null) {
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

      if (_isLyricsMode && _isSyncedLyrics && _parsedLyrics.isNotEmpty) {
        final activeIndex = _getActiveLyricIndex();
        if (activeIndex != _lastActiveLyricIndex && activeIndex != -1) {
          _lastActiveLyricIndex = activeIndex;
          
          if (activeIndex < _lyricKeys.length) {
            final key = _lyricKeys[activeIndex];
            if (key.currentContext != null) {
              Scrollable.ensureVisible(
                key.currentContext!,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                alignment: 0.5,
              );
            }
          }
        }
      }
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
    _lyricsScrollController.dispose();
    audioService.currentSong.removeListener(_onCurrentSongChanged);
    super.dispose();
  }

  void _onCurrentSongChanged() {
    final song = audioService.currentSong.value;
    if (!mounted || song == null) return;

    final playlistIndex = widget.playlist.indexWhere((item) => item.id == song.id);

    setState(() {
      activeSong = song;
      if (playlistIndex >= 0) currentIndex = playlistIndex;
      isFavorite = LibraryService.instance.isLiked(song.id);
      isLoadingSong = false;
      _parsedLyrics.clear();
      _lyricKeys.clear();
      _lastActiveLyricIndex = -1;
    });
    
    _fetchLyrics();
  }

  Future<void> _fetchLyrics() async {
    setState(() => _isLoadingLyrics = true);
    final title = decodeHtml(activeSong.title);
    final artist = decodeHtml(activeSong.artist);

    try {
      final data = await lyricsService.getLyrics(title: title, artist: artist);
      List<LyricLine> tempLines = [];
      bool isSynced = false;

      if (data != null) {
        if (data.syncedLyrics != null && data.syncedLyrics!.contains('[')) {
          final lines = data.syncedLyrics!.split('\n');
          final RegExp regex = RegExp(r'\[(\d+):(\d+\.?\d*)\](.*)');
          for (var line in lines) {
            final match = regex.firstMatch(line);
            if (match != null) {
              final min = int.parse(match.group(1)!);
              final sec = double.parse(match.group(2)!);
              final text = match.group(3)!.trim();
              if (text.isNotEmpty) {
                tempLines.add(LyricLine(
                  time: Duration(milliseconds: (min * 60000 + sec * 1000).toInt()),
                  text: text,
                ));
              }
            }
          }
          isSynced = tempLines.isNotEmpty;
        }
        
        if (!isSynced) {
          final raw = data.plainLyrics.isNotEmpty ? data.plainLyrics : (data.syncedLyrics ?? '');
          final lines = raw.split('\n').map((l) => l.replaceAll(RegExp(r'\[.*?\]'), '').trim()).where((l) => l.isNotEmpty);
          for (var text in lines) {
            tempLines.add(LyricLine(time: Duration.zero, text: text));
          }
        }
      }

      if (mounted) {
        setState(() {
          _parsedLyrics = tempLines;
          _isSyncedLyrics = isSynced;
          _isLoadingLyrics = false;
          _lyricKeys.clear();
          _lyricKeys.addAll(List.generate(tempLines.length, (index) => GlobalKey()));
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLyrics = false);
    }
  }

  int _getActiveLyricIndex() {
    if (!_isSyncedLyrics || _parsedLyrics.isEmpty) return -1;
    for (int i = 0; i < _parsedLyrics.length; i++) {
      if (i == _parsedLyrics.length - 1) return i;
      if (currentPosition >= _parsedLyrics[i].time && currentPosition < _parsedLyrics[i + 1].time) {
        return i;
      }
    }
    return -1;
  }

  void _toggleLyricsMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isLyricsMode = !_isLyricsMode;
    });
    
    if (_isLyricsMode && _isSyncedLyrics) {
      Future.delayed(const Duration(milliseconds: 150), () {
        final activeIndex = _getActiveLyricIndex();
        if (activeIndex != -1 && activeIndex < _lyricKeys.length) {
          final key = _lyricKeys[activeIndex];
          if (key.currentContext != null) {
            Scrollable.ensureVisible(
              key.currentContext!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              alignment: 0.5,
            );
          }
        }
      });
    }
  }

  String decodeHtml(String text) {
    return text.replaceAll('&quot;', '"').replaceAll('&#34;', '"').replaceAll('&amp;', '&').replaceAll('&#38;', '&').replaceAll('&#39;', "'").replaceAll('&apos;', "'").replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&#x27;', "'");
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> startSong() async {
    if (widget.playlist.isEmpty) return;
    final song = activeSong;
    setState(() => isLoadingSong = true);

    try {
      await audioService.playSong(
        song.id, title: song.title, artist: song.artist, image: song.thumbnail,
      );
      await LibraryService.instance.addRecentlyPlayed(song);
    } catch (e) {
      debugPrint('Play Song Error: $e');
    } finally {
      if (mounted) setState(() => isLoadingSong = false);
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
      setState(() {
        currentIndex = (currentIndex + 1) % widget.playlist.length;
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
    setState(() => isFavorite = !isFavorite);
  }

  void toggleRepeatMode() {
    HapticFeedback.selectionClick();
    setState(() => repeatMode = (repeatMode + 1) % 3);
  }

  void toggleShuffle() {
    HapticFeedback.selectionClick();
    setState(() => isShuffle = !isShuffle);
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
          initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.95, expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Playback Queue', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                      Text('${widget.playlist.length} tracks', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 13)),
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
                      final currentTheme = RyvoThemeController.themes[RyvoThemeController.instance.selectedTheme];

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 44, height: 44,
                            child: item.thumbnail.isNotEmpty ? Image.network(item.thumbnail, fit: BoxFit.cover) : Container(color: SpotifyColors.surfaceElevated),
                          ),
                        ),
                        title: Text(
                          decodeHtml(item.title),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(color: isCurrent ? currentTheme.primary : SpotifyColors.textPrimary, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500, fontSize: 14),
                        ),
                        subtitle: Text(decodeHtml(item.artist), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 12)),
                        trailing: isCurrent ? Icon(Icons.volume_up_rounded, color: currentTheme.primary, size: 20) : null,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() { currentIndex = index; activeSong = widget.playlist[index]; });
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

  Widget _buildPlayerControls(Duration safePosition, dynamic currentTheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    decodeHtml(activeSong.title),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    decodeHtml(activeSong.artist),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            IconButton(
              splashRadius: 24,
              icon: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? currentTheme.primary : SpotifyColors.textSecondary,
                size: 28,
              ),
              onPressed: toggleFavorite,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: currentTheme.primary,
                inactiveTrackColor: Colors.white24,
                thumbColor: SpotifyColors.textPrimary,
              ),
              child: Slider(
                min: 0.0,
                max: (totalDuration.inMilliseconds > 0) ? totalDuration.inMilliseconds.toDouble() : 1.0,
                value: (safePosition.inMilliseconds.toDouble()).clamp(0.0, (totalDuration.inMilliseconds > 0 ? totalDuration.inMilliseconds.toDouble() : 1.0)),
                onChangeStart: (value) => setState(() { _isDraggingSlider = true; _dragValue = value; }),
                onChanged: (value) => setState(() => _dragValue = value),
                onChangeEnd: (value) async {
                  final target = Duration(milliseconds: value.toInt());
                  await audioService.seek(target);
                  setState(() { _isDraggingSlider = false; currentPosition = target; });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(safePosition), style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                  Text('-${formatDuration(totalDuration - safePosition > Duration.zero ? totalDuration - safePosition : Duration.zero)}', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              splashRadius: 22,
              icon: Icon(Icons.shuffle_rounded, color: isShuffle ? currentTheme.primary : SpotifyColors.textSecondary, size: 24),
              onPressed: toggleShuffle,
            ),
            IconButton(
              splashRadius: 26,
              icon: const Icon(Icons.skip_previous_rounded, color: SpotifyColors.textPrimary, size: 38),
              onPressed: playPrevious,
            ),
            GestureDetector(
              onTap: togglePlayPause,
              child: Container(
                width: 66, height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentTheme.primary,
                  boxShadow: [ BoxShadow(color: currentTheme.primary.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: 1) ],
                ),
                child: Center(
                  child: isLoadingSong
                      ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                      : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 38),
                ),
              ),
            ),
            IconButton(
              splashRadius: 26,
              icon: const Icon(Icons.skip_next_rounded, color: SpotifyColors.textPrimary, size: 38),
              onPressed: playNext,
            ),
            IconButton(
              splashRadius: 22,
              icon: Icon(repeatMode == 2 ? Icons.repeat_one_rounded : Icons.repeat_rounded, color: repeatMode > 0 ? currentTheme.primary : SpotifyColors.textSecondary, size: 24),
              onPressed: toggleRepeatMode,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = RyvoThemeController.themes[RyvoThemeController.instance.selectedTheme];
    final safePosition = _isDraggingSlider ? Duration(milliseconds: _dragValue.toInt()) : currentPosition;
    final activeLyricIndex = _getActiveLyricIndex();

    return Scaffold(
      backgroundColor: SpotifyColors.background,
      body: Stack(
        children: [
          // 1. FIXED SEAMLESS GRADIENT - Matching exactly with Scaffold background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    currentTheme.primaryDark.withValues(alpha: 0.6),
                    SpotifyColors.background, // Match the exact app background to eliminate seam
                  ],
                  stops: const [0.0, 0.7],
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
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 34, color: SpotifyColors.textPrimary),
                          onPressed: () {
                            if (_isLyricsMode) {
                              _toggleLyricsMode();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('PLAYING FROM PLAYLIST', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                              const SizedBox(height: 2),
                              Text(decodeHtml(activeSong.artist), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert_rounded, size: 24, color: SpotifyColors.textPrimary),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: SpotifyColors.surfaceElevated,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                              builder: (_) => SongPlaylistPicker(song: activeSong),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // MAIN ANIMATED SECTION
                  Expanded(
                    child: Stack(
                      children: [
                        // 1. FIXED OVERLAP: Positioned layer limits the scroll boundary below the artwork
                        Positioned(
                          top: 90, // Strict boundary so lyrics NEVER go behind or above the minimized cover
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            ignoring: !_isLyricsMode,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: _isLyricsMode ? 1.0 : 0.0,
                              child: _isLoadingLyrics
                                  ? const Center(child: CircularProgressIndicator(color: SpotifyColors.green))
                                  : _parsedLyrics.isEmpty
                                      ? Center(child: Text('Lyrics not available for this track.', style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 14)))
                                      : ListView(
                                          controller: _lyricsScrollController,
                                          physics: const BouncingScrollPhysics(),
                                          padding: EdgeInsets.only(
                                            top: 16,
                                            bottom: MediaQuery.of(context).size.height * 0.5,
                                          ),
                                          children: _parsedLyrics.asMap().entries.map((entry) {
                                            final index = entry.key;
                                            final line = entry.value;
                                            final isCurrentLine = _isSyncedLyrics && index == activeLyricIndex;
                                            
                                            return Padding(
                                              key: _lyricKeys[index], 
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              child: Text(
                                                line.text,
                                                style: GoogleFonts.plusJakartaSans(
                                                  // FIXED BLURRY TEXT: Increased alpha to 0.6 for sharp readability
                                                  color: isCurrentLine ? Colors.white : Colors.white.withValues(alpha: 0.6),
                                                  fontSize: isCurrentLine ? 22 : 18,
                                                  fontWeight: isCurrentLine ? FontWeight.w800 : FontWeight.w600,
                                                  height: 1.4,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                            ),
                          ),
                        ),

                        // 2. Player Controls Layer
                        IgnorePointer(
                          ignoring: _isLyricsMode,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _isLyricsMode ? 0.0 : 1.0,
                            child: _buildPlayerControls(safePosition, currentTheme),
                          ),
                        ),

                        // 3. Animated Artwork Layer
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          alignment: _isLyricsMode ? Alignment.topLeft : const Alignment(0.0, -0.65),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            margin: EdgeInsets.only(
                              top: _isLyricsMode ? 10 : 0, 
                            ),
                            width: _isLyricsMode ? 72 : MediaQuery.of(context).size.width * 0.76, 
                            height: _isLyricsMode ? 72 : MediaQuery.of(context).size.width * 0.76,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(_isLyricsMode ? 8 : 12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: _isLyricsMode ? 0.3 : 0.65),
                                  blurRadius: _isLyricsMode ? 10 : 30,
                                  offset: Offset(0, _isLyricsMode ? 4 : 16),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(_isLyricsMode ? 8 : 12),
                              child: activeSong.thumbnail.isNotEmpty
                                  ? Image.network(activeSong.thumbnail, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: SpotifyColors.surfaceElevated, child: const Icon(Icons.music_note_rounded, color: SpotifyColors.textSecondary, size: 64)))
                                  : Container(color: SpotifyColors.surfaceElevated, child: const Icon(Icons.music_note_rounded, color: SpotifyColors.textSecondary, size: 64)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bottom Action Buttons Layer (Fixed, Unobstructed)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _toggleLyricsMode, 
                        icon: Icon(
                          Icons.lyrics_rounded,
                          color: _isLyricsMode ? currentTheme.primary : SpotifyColors.textSecondary,
                          size: 18,
                        ),
                        label: Text(
                          'Lyrics',
                          style: GoogleFonts.plusJakartaSans(
                            color: _isLyricsMode ? currentTheme.primary : SpotifyColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        splashRadius: 22,
                        icon: const Icon(Icons.queue_music_rounded, color: SpotifyColors.textSecondary, size: 24),
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