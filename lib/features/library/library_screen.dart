
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/features/player/player_screen.dart';
import 'package:music_app/features/playlist/playlist_screen.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/audio_service.dart';
import 'package:music_app/services/library_service.dart';
import 'package:music_app/widgets/song_playlist_picker.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  Color get _primary => Theme.of(context).colorScheme.primary;
  Color get _primaryLight => Theme.of(context).colorScheme.secondary;
  Color get _primaryDark => Theme.of(context).colorScheme.primaryContainer;
  Color get _backgroundColor => Color.lerp(Colors.black, _primaryDark, 0.20)!;
  Color get _cardColor => Color.lerp(Colors.black, _primaryDark, 0.30)!;
  Color get _selectedTabColor => _primaryDark.withValues(alpha: 0.42);

  final AudioService audioService = AudioService();

  List<Song> likedSongs = [];
  List<Song> recentlyPlayed = [];
  List<String> playlistNames = [];

  bool loading = true;
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    loadLibrary();
  }

  Future<void> loadLibrary() async {
    await LibraryService.instance.init();

    final liked = await LibraryService.instance.getLikedSongs();
    final recent = await LibraryService.instance.getRecentlyPlayed();
    final playlists = await LibraryService.instance.getPlaylistNames();

    if (!mounted) return;

    setState(() {
      likedSongs = liked;
      recentlyPlayed = recent;
      playlistNames = playlists;
      loading = false;
    });
  }

  void openPlayer(Song song, List<Song> playlist) {
    if (playlist.isEmpty) return;

    final index = playlist.indexWhere((item) => item.id == song.id);

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

  Future<void> removeLiked(Song song) async {
    await LibraryService.instance.removeLiked(song.id);
    await loadLibrary();
  }

  Future<void> clearRecent() async {
    await LibraryService.instance.clearRecentlyPlayed();
    await loadLibrary();
  }

  void openLikedSongs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibrarySongsScreen(
          title: 'Liked Songs',
          songs: likedSongs,
          type: LibrarySongsType.liked,
        ),
      ),
    ).then((_) => loadLibrary());
  }

  void openRecentlyPlayed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibrarySongsScreen(
          title: 'Recently Played',
          songs: recentlyPlayed,
          type: LibrarySongsType.recent,
        ),
      ),
    ).then((_) => loadLibrary());
  }

  Future<void> _createPlaylist() async {
    String playlistName = '';

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
          title: Text(
            'Create Playlist',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            autofocus: true,
            style: TextStyle(color: Colors.white),
            onChanged: (value) {
              playlistName = value;
            },
            decoration: InputDecoration(
              hintText: 'Playlist name',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _primaryLight,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  playlistName.trim(),
                );
              },
              child: Text(
                'Create',
                style: TextStyle(color: _primaryLight),
              ),
            ),
          ],
        );
      },
    );

    if (name == null || name.trim().isEmpty) return;

    final created = await LibraryService.instance.createPlaylist(name);

    if (!mounted) return;

    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Playlist already exists or name is invalid.',
          ),
        ),
      );
      return;
    }

    await loadLibrary();
  }

  Future<void> _openPlaylist(String name) async {
    final songs = await LibraryService.instance.getPlaylist(name);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistScreen(
          playlistName: name,
          subtitle: 'Your playlist',
          icon: Icons.queue_music_rounded,
          songs: songs,
        ),
      ),
    );
  }

  String decode(String text) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: loading
            ? Center(
          child: CircularProgressIndicator(
            color: _primaryLight,
          ),
        )
            : RefreshIndicator(
          color: _primaryLight,
          backgroundColor: _cardColor,
          onRefresh: loadLibrary,
          child: CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(18, 12, 18, 30),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _topBar(),
                    SizedBox(height: 20),
                    _tabs(),
                    SizedBox(height: 18),
                    _featureGrid(),
                    SizedBox(height: 28),
                    if (selectedTab == 0)
                      _playlistView()
                    else if (selectedTab == 1)
                      _songsView()
                    else
                      _comingSoonView(
                        selectedTab == 2 ? 'Albums' : 'Artists',
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: 42,
            minHeight: 42,
          ),
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        SizedBox(width: 6),
        Text(
          'Library',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        Spacer(),
        IconButton(
          tooltip: 'Refresh',
          onPressed: loadLibrary,
          icon: Icon(
            Icons.refresh_rounded,
            color: Colors.white70,
            size: 27,
          ),
        ),
      ],
    );
  }

  Widget _tabs() {
    const labels = ['Playlists', 'Songs', 'Albums', 'Artists'];

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTab = index;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? _selectedTabColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  labels[index],
                  style: GoogleFonts.poppins(
                    color: selected ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _featureGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _featureCard(
                icon: Icons.favorite_rounded,
                title: 'Liked',
                count: likedSongs.length,
                iconColor: Color(0xffF472B6),
                onTap: openLikedSongs,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _featureCard(
                icon: Icons.history_rounded,
                title: 'Recently Played',
                count: recentlyPlayed.length,
                iconColor: _primaryLight,
                onTap: openRecentlyPlayed,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _featureCard(
                icon: Icons.queue_music_rounded,
                title: 'Queue',
                count: audioService.queue.value.length,
                iconColor: _primary,
                onTap: _showQueue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: SizedBox(height: 86),
            ),
          ],
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
    int? count,
  }) {
    return Material(
      color: _cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 86,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _playlistView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Playlists',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _createPlaylist,
              icon: Icon(
                Icons.add_rounded,
                color: _primaryLight,
                size: 19,
              ),
              label: Text(
                'Create',
                style: GoogleFonts.poppins(
                  color: _primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          playlistNames.isEmpty
              ? 'Create a playlist to organize your music.'
              : '${playlistNames.length} playlist${playlistNames.length == 1 ? '' : 's'}',
          style: GoogleFonts.poppins(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
        SizedBox(height: 18),
        if (playlistNames.isEmpty)
          _emptyCard(
            icon: Icons.queue_music_rounded,
            title: 'No playlists yet',
            subtitle:
            'Create playlists to keep your favorite music organized.',
          )
        else
          ...playlistNames.map(
                (name) => Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Material(
                color: _cardColor,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => _openPlaylist(name),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _primaryLight
                                .withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.queue_music_rounded,
                            color: _primaryLight,
                            size: 25,
                          ),
                        ),
                        SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white38,
                          size: 25,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _songsView() {
    final songs = <Song>[];
    final ids = <String>{};

    for (final song in likedSongs) {
      if (ids.add(song.id)) {
        songs.add(song);
      }
    }

    for (final song in recentlyPlayed) {
      if (ids.add(song.id)) {
        songs.add(song);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'All Songs',
          subtitle: '${songs.length} songs',
          trailing: songs.isEmpty
              ? null
              : TextButton(
            onPressed: () async {
              if (likedSongs.isNotEmpty) {
                await LibraryService.instance.clearLikedSongs();
                await loadLibrary();
              }
            },
            child: Text(
              'Clear liked',
              style: GoogleFonts.poppins(
                color: _primaryLight,
                fontSize: 11,
              ),
            ),
          ),
        ),
        SizedBox(height: 14),
        if (songs.isEmpty)
          _emptyCard(
            icon: Icons.music_note_rounded,
            title: 'No songs yet',
            subtitle:
            'Songs you like or play will appear in your library.',
          )
        else
          ...songs.map(
                (song) => _songTile(
              song: song,
              playlist: songs,
              showRemove:
              likedSongs.any((liked) => liked.id == song.id),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _songTile({
    required Song song,
    required List<Song> playlist,
    bool showRemove = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 9),
      child: Material(
        color: _cardColor,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: () => openPlayer(song, playlist),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            SongPlaylistPicker.show(context, song);
          },
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: EdgeInsets.all(9),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: song.thumbnail.trim().isEmpty
                        ? _fallbackArt()
                        : Image.network(
                      song.thumbnail,
                      fit: BoxFit.cover,
                      cacheWidth: 112,
                      cacheHeight: 112,
                      errorBuilder: (_, _, _) {
                        return _fallbackArt();
                      },
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        decode(song.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        decode(song.artist),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => openPlayer(song, playlist),
                  icon: Icon(
                    Icons.play_circle_fill_rounded,
                    color: _primaryLight,
                    size: 31,
                  ),
                ),
                if (showRemove)
                  IconButton(
                    onPressed: () => removeLiked(song),
                    icon: Icon(
                      Icons.favorite_rounded,
                      color: Color(0xffF472B6),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: .06),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white24,
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _comingSoonView(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 45,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: _primaryLight,
            size: 44,
          ),
          SizedBox(height: 14),
          Text(
            '$title coming soon',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'We will connect this section with real data next.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showQueue() {
    final queue = audioService.queue.value;

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      showDragHandle: true,
      builder: (sheetContext) {
        if (queue.isEmpty) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'Queue is empty',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 20),
            itemCount: queue.length,
            itemBuilder: (context, index) {
              final song = queue[index];

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: song.thumbnail.trim().isEmpty
                        ? _fallbackArt()
                        : Image.network(
                      song.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return _fallbackArt();
                      },
                    ),
                  ),
                ),
                title: Text(
                  decode(song.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  decode(song.artist),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  openPlayer(song, queue);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _fallbackArt() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primary,
            _primaryDark,
          ],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: Colors.white70,
      ),
    );
  }
}

enum LibrarySongsType { liked, recent }

class LibrarySongsScreen extends StatefulWidget {
  final String title;
  final List<Song> songs;
  final LibrarySongsType type;

  const LibrarySongsScreen({
    super.key,
    required this.title,
    required this.songs,
    required this.type,
  });

  @override
  State<LibrarySongsScreen> createState() => _LibrarySongsScreenState();
}

class _LibrarySongsScreenState extends State<LibrarySongsScreen> {
  Color get _primary => Theme.of(context).colorScheme.primary;
  Color get _primaryLight => Theme.of(context).colorScheme.secondary;
  Color get _primaryDark => Theme.of(context).colorScheme.primaryContainer;
  Color get _backgroundColor => Color.lerp(Colors.black, _primaryDark, 0.20)!;
  Color get _cardColor => Color.lerp(Colors.black, _primaryDark, 0.30)!;

  late List<Song> songs;

  @override
  void initState() {
    super.initState();
    songs = List<Song>.from(widget.songs);
  }

  String decode(String text) {
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

  void openPlayer(Song song) {
    if (songs.isEmpty) return;

    final index = songs.indexWhere((item) => item.id == song.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: song.title,
          artist: song.artist,
          image: song.thumbnail,
          songId: song.id,
          playlist: songs,
          currentIndex: index < 0 ? 0 : index,
        ),
      ),
    );
  }

  Future<void> removeLiked(Song song) async {
    await LibraryService.instance.removeLiked(song.id);

    if (!mounted) return;

    setState(() {
      songs.removeWhere((item) => item.id == song.id);
    });
  }

  Future<void> clearRecent() async {
    await LibraryService.instance.clearRecentlyPlayed();

    if (!mounted) return;

    setState(() {
      songs.clear();
    });
  }

  Future<void> refresh() async {
    await LibraryService.instance.init();

    final updated = widget.type == LibrarySongsType.liked
        ? await LibraryService.instance.getLikedSongs()
        : await LibraryService.instance.getRecentlyPlayed();

    if (!mounted) return;

    setState(() {
      songs = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.type == LibrarySongsType.liked;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: _primaryLight,
          backgroundColor: _cardColor,
          onRefresh: refresh,
          child: CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(18, 12, 18, 30),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _header(isLiked),
                    SizedBox(height: 22),
                    _heroHeader(isLiked),
                    SizedBox(height: 18),
                    if (songs.isEmpty)
                      _emptyState(isLiked)
                    else
                      ...songs.map(
                            (song) => _premiumSongTile(song, isLiked),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(bool isLiked) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: 42,
            minHeight: 42,
          ),
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (!songs.isEmpty && !isLiked)
          TextButton(
            onPressed: clearRecent,
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(
                color: _primaryLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _heroHeader(bool isLiked) {
    final countText =
    songs.length == 1 ? '1 song' : '${songs.length} songs';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLiked
              ? [
            Color.lerp(_primaryDark, Colors.black, 0.35)!,
            _cardColor,
          ]
              : [
            Color.lerp(_primary, Colors.black, 0.72)!,
            _cardColor,
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: .06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isLiked
                  ? Color(0xffF472B6).withValues(alpha: .14)
                  : _primaryLight.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(
              isLiked
                  ? Icons.favorite_rounded
                  : Icons.history_rounded,
              color: isLiked
                  ? Color(0xffF472B6)
                  : _primaryLight,
              size: 32,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLiked
                      ? 'Your favorite music'
                      : 'Your listening history',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  countText,
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
    );
  }

  Widget _premiumSongTile(Song song, bool isLiked) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Material(
        color: _cardColor,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: () => openPlayer(song),
          borderRadius: BorderRadius.circular(19),
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 8, 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 62,
                    height: 62,
                    child: song.thumbnail.trim().isEmpty
                        ? _fallbackArt()
                        : Image.network(
                      song.thumbnail,
                      fit: BoxFit.cover,
                      cacheWidth: 124,
                      cacheHeight: 124,
                      errorBuilder: (_, _, _) {
                        return _fallbackArt();
                      },
                    ),
                  ),
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        decode(song.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        decode(song.artist),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Play',
                  onPressed: () => openPlayer(song),
                  icon: Icon(
                    Icons.play_circle_fill_rounded,
                    color: _primaryLight,
                    size: 34,
                  ),
                ),
                if (isLiked)
                  IconButton(
                    tooltip: 'Remove from liked',
                    onPressed: () => removeLiked(song),
                    icon: Icon(
                      Icons.favorite_rounded,
                      color: Color(0xffF472B6),
                      size: 21,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(bool isLiked) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        25,
        55,
        25,
        55,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: .06),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: isLiked
                  ? Color(0xffF472B6).withValues(alpha: .10)
                  : _primaryLight.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLiked
                  ? Icons.favorite_border_rounded
                  : Icons.history_rounded,
              color: isLiked
                  ? Color(0xffF472B6)
                  : _primaryLight,
              size: 34,
            ),
          ),
          SizedBox(height: 18),
          Text(
            isLiked
                ? 'No liked songs yet'
                : 'No recently played songs',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            isLiked
                ? 'Tap the heart on any song to save it here.'
                : 'Songs you listen to will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackArt() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primary,
            _primaryDark,
          ],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: Colors.white70,
      ),
    );
  }
}
