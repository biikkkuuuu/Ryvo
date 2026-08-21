
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/app/theme_controller.dart';
import 'package:music_app/features/account/account_screen.dart';
import 'package:music_app/features/library/library_screen.dart';
import 'package:music_app/features/player/player_screen.dart';
import 'package:music_app/features/playlist/playlist_screen.dart';
import 'package:music_app/features/search/search_screen.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/repositories/music_repository.dart';
import 'package:music_app/services/audio_service.dart';
import 'package:music_app/services/library_service.dart';
import 'package:music_app/theme/app_theme.dart';
import 'package:music_app/widgets/song_playlist_picker.dart';

// ============================================================
// HELPER: HTML DECODER
// ============================================================
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

// ============================================================
// MAIN HOME SCREEN (WITH BOTTOM NAV & MINI PLAYER)
// ============================================================
class HomeScreen extends StatefulWidget {
const HomeScreen({super.key});

@override
State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
int _currentNavIndex = 0;

@override
void initState() {
super.initState();
WidgetsBinding.instance.addObserver(this);
}

@override
void dispose() {
WidgetsBinding.instance.removeObserver(this);
super.dispose();
}

@override
Widget build(BuildContext context) {
final currentTheme = RyvoThemeController.themes[
RyvoThemeController.instance.selectedTheme];

return PopScope(
canPop: _currentNavIndex == 0,
onPopInvokedWithResult: (didPop, result) {
if (didPop) return;

if (_currentNavIndex != 0) {
setState(() {
_currentNavIndex = 0;
});
}
},
child: Scaffold(
backgroundColor: SpotifyColors.background,
body: Stack(
children: [
// Current Tab Body
IndexedStack(
index: _currentNavIndex,
children: const [
_HomeTabContent(),
SearchScreen(),
LibraryScreen(),
],
),

// Floating Mini Player & Navigation Bar at bottom
Positioned(
left: 0,
right: 0,
bottom: 0,
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const _SpotifyMiniPlayer(),
_buildBottomNavigationBar(currentTheme.primary),
],
),
),
],
),
),
);
}

Widget _buildBottomNavigationBar(Color accentColor) {
return Container(
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [
Colors.black.withValues(alpha: 0.85),
Colors.black,
],
),
border: const Border(
top: BorderSide(color: Colors.white10, width: 0.5),
),
),
child: SafeArea(
top: false,
child: SizedBox(
height: 60,
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
_buildNavItem(
index: 0,
icon: Icons.home_rounded,
unselectedIcon: Icons.home_outlined,
label: 'Home',
accentColor: accentColor,
),
_buildNavItem(
index: 1,
icon: Icons.search_rounded,
unselectedIcon: Icons.search_rounded,
label: 'Search',
accentColor: accentColor,
),
_buildNavItem(
index: 2,
icon: Icons.library_music_rounded,
unselectedIcon: Icons.library_music_outlined,
label: 'Your Library',
accentColor: accentColor,
),
],
),
),
),
);
}

Widget _buildNavItem({
required int index,
required IconData icon,
required IconData unselectedIcon,
required String label,
required Color accentColor,
}) {
final isSelected = _currentNavIndex == index;

return GestureDetector(
behavior: HitTestBehavior.opaque,
onTap: () {
HapticFeedback.selectionClick();
setState(() {
_currentNavIndex = index;
});
},
child: SizedBox(
width: 80,
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
isSelected ? icon : unselectedIcon,
color: isSelected ? SpotifyColors.textPrimary : SpotifyColors.textSecondary,
size: 24,
),
const SizedBox(height: 4),
Text(
label,
style: GoogleFonts.plusJakartaSans(
color: isSelected ? SpotifyColors.textPrimary : SpotifyColors.textSecondary,
fontSize: 11,
fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
),
),
],
),
),
);
}
}

// ============================================================
// SPOTIFY DOCKED MINI PLAYER
// ============================================================
class _SpotifyMiniPlayer extends StatelessWidget {
const _SpotifyMiniPlayer();

@override
Widget build(BuildContext context) {
final audio = AudioService();

return ValueListenableBuilder<Song?>(
valueListenable: audio.currentSong,
builder: (context, song, _) {
if (song == null) {
return const SizedBox.shrink();
}

final currentTheme = RyvoThemeController.themes[
RyvoThemeController.instance.selectedTheme];

return StreamBuilder<PlayerState>(
stream: audio.playerStateStream,
initialData: audio.player.playerState,
builder: (context, snapshot) {
final state = snapshot.data ?? audio.player.playerState;
final isPlaying = state.playing &&
state.processingState != ProcessingState.completed;

void openFullPlayer() {
final currentSong = audio.currentSong.value;
if (currentSong == null) return;

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
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
child: GestureDetector(
onTap: openFullPlayer,
child: Container(
height: 58,
decoration: BoxDecoration(
color: const Color(0xFF242424),
borderRadius: BorderRadius.circular(10),
boxShadow: [
BoxShadow(
color: Colors.black.withValues(alpha: 0.6),
blurRadius: 16,
offset: const Offset(0, 4),
),
],
),
child: ClipRRect(
borderRadius: BorderRadius.circular(10),
child: Stack(
children: [
// Content Row
Padding(
padding: const EdgeInsets.symmetric(horizontal: 8),
child: Row(
children: [
// Artwork
ClipRRect(
borderRadius: BorderRadius.circular(6),
child: SizedBox(
width: 42,
height: 42,
child: song.thumbnail.trim().isEmpty
? Container(
color: SpotifyColors.surfaceElevated,
child: const Icon(
Icons.music_note_rounded,
color: SpotifyColors.textSecondary,
size: 22,
),
)
    : Image.network(
song.thumbnail,
fit: BoxFit.cover,
errorBuilder: (_, _, _) => Container(
color: SpotifyColors.surfaceElevated,
child: const Icon(
Icons.music_note_rounded,
color: SpotifyColors.textSecondary,
size: 22,
),
),
),
),
),

const SizedBox(width: 12),

// Title & Artist
Expanded(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
decodeHtml(song.title),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textPrimary,
fontSize: 13,
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 2),
Text(
decodeHtml(song.artist),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textSecondary,
fontSize: 11,
fontWeight: FontWeight.w400,
),
),
],
),
),

// Like button
_MiniPlayerLikeButton(song: song),

// Play / Pause Icon
IconButton(
splashRadius: 20,
onPressed: () async {
HapticFeedback.selectionClick();
if (isPlaying) {
await audio.pause();
} else {
await audio.resume();
}
},
icon: Icon(
isPlaying
? Icons.pause_rounded
    : Icons.play_arrow_rounded,
color: SpotifyColors.textPrimary,
size: 30,
),
),
],
),
),

// Realtime Progress Indicator Bar
Positioned(
left: 0,
right: 0,
bottom: 0,
child: StreamBuilder<Duration>(
stream: audio.positionStream,
builder: (context, posSnapshot) {
final position = posSnapshot.data ?? Duration.zero;
final total = audio.totalDuration ?? Duration.zero;
final progress = (total.inMilliseconds > 0)
? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
    : 0.0;

return LinearProgressIndicator(
value: progress,
minHeight: 2.5,
backgroundColor: Colors.white12,
valueColor: AlwaysStoppedAnimation<Color>(
currentTheme.primary,
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
);
},
);
},
);
}
}

class _MiniPlayerLikeButton extends StatefulWidget {
final Song song;
const _MiniPlayerLikeButton({required this.song});

@override
State<_MiniPlayerLikeButton> createState() => _MiniPlayerLikeButtonState();
}

class _MiniPlayerLikeButtonState extends State<_MiniPlayerLikeButton> {
bool _isLiked = false;

@override
void initState() {
super.initState();
_checkLiked();
}

@override
void didUpdateWidget(covariant _MiniPlayerLikeButton oldWidget) {
super.didUpdateWidget(oldWidget);
if (oldWidget.song.id != widget.song.id) {
_checkLiked();
}
}

void _checkLiked() {
_isLiked = LibraryService.instance.isLiked(widget.song.id);
}

Future<void> _toggleLike() async {
HapticFeedback.selectionClick();
if (_isLiked) {
await LibraryService.instance.removeLiked(widget.song.id);
} else {
await LibraryService.instance.addLiked(widget.song);
}
if (mounted) {
setState(() {
_isLiked = !_isLiked;
});
}
}

@override
Widget build(BuildContext context) {
final currentTheme = RyvoThemeController.themes[
RyvoThemeController.instance.selectedTheme];

return IconButton(
splashRadius: 18,
onPressed: _toggleLike,
icon: Icon(
_isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
color: _isLiked ? currentTheme.primary : SpotifyColors.textSecondary,
size: 22,
),
);
}
}

// ============================================================
// HOME TAB CONTENT (SPOTIFY STYLE)
// ============================================================
class _HomeTabContent extends StatefulWidget {
const _HomeTabContent();

@override
State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
final MusicRepository _repository = MusicRepository();

Map<String, List<Song>> _sections = {};
List<Song> _recentlyPlayed = [];
List<SearchPlaylistResult> _homePlaylists = [];
List<SearchAlbumResult> _homeAlbums = [];
List<dynamic> _radioStations = [];
  List<SearchPlaylistResult> _moodPlaylists = [];

bool _loading = true;
String? _error;
int _selectedFilterIndex = 0;

final List<String> _filters = ['All', 'Music', 'Charts', 'Moods', 'Radio'];

@override
void initState() {
super.initState();
_loadHomeData();
}

String _getGreeting() {
final hour = DateTime.now().hour;
if (hour < 12) {
return 'Good morning';
} else if (hour < 17) {
return 'Good afternoon';
} else {
return 'Good evening';
}
}

Future<List<SearchPlaylistResult>> _loadMoodPlaylists() async {
    const moodQueries = [
      'Romantic Hindi',
      'Sad Hindi',
      'Party Hindi',
      'Chill Hindi',
      'Workout Hindi',
    ];

    final results = await Future.wait(
      moodQueries.map(_repository.playlistSuggestions),
    );

    final seen = <String>{};
    return results
        .expand((playlists) => playlists)
        .where((playlist) => seen.add(playlist.id))
        .take(15)
        .toList();
  }

  Future<void> _loadRadioStations() async {
  try {
    final songIds = <String>[];

    for (final songs in _sections.values) {
      for (final song in songs) {
        final id = song.id.trim();

        if (id.isNotEmpty && !songIds.contains(id)) {
          songIds.add(id);
        }

        if (songIds.length == 10) break;
      }

      if (songIds.length == 10) break;
    }

    if (songIds.isEmpty) {
      debugPrint('RYVO RADIO: No live song IDs available.');
      return;
    }

    debugPrint(
      'RYVO RADIO: requesting  live song IDs',
    );

    final stations = await _repository.getRadioStations(songIds);

    if (!mounted) return;

    setState(() {
      _radioStations = stations;
    });

    debugPrint(
      'RYVO RADIO: received  stations',
    );
  } catch (e) {
    debugPrint('RYVO RADIO ERROR: $e');
  }
}

Future<void> _loadHomeData({bool showLoader = true}) async {
if (mounted && showLoader) {
setState(() {
_loading = true;
_error = null;
});
}

try {
await LibraryService.instance.init();
final results = await Future.wait([
_repository.getHomeBundle(),
LibraryService.instance.getRecentlyPlayed(),
_loadMoodPlaylists(),
]);

if (!mounted) return;

final home = results[0] as Map<String, dynamic>;
final recent = results[1] as List<Song>;
final moods = results[2] as List<SearchPlaylistResult>;

setState(() {
_sections = home['sections'] as Map<String, List<Song>>? ?? {};
_homePlaylists = home['playlists'] as List<SearchPlaylistResult>? ?? [];
_homeAlbums = home['albums'] as List<SearchAlbumResult>? ?? [];
_recentlyPlayed = recent;
_moodPlaylists = moods;
_loading = false;
_error = null;
});
await _loadRadioStations();
} catch (e) {
debugPrint('Home error: $e');
if (!mounted) return;
setState(() {
_loading = false;
if (_sections.isEmpty) {
_error = 'Unable to load songs. Tap to retry.';
}
});
}
}

void _playSong(Song song, List<Song> playlist, {int index = 0}) {
HapticFeedback.lightImpact();
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => PlayerScreen(
title: song.title,
artist: song.artist,
image: song.thumbnail,
songId: song.id,
playlist: playlist,
currentIndex: index,
),
),
);
}

@override
Widget build(BuildContext context) {
final currentTheme = RyvoThemeController.themes[
RyvoThemeController.instance.selectedTheme];

return RefreshIndicator(
onRefresh: () => _loadHomeData(showLoader: false),
color: currentTheme.primary,
backgroundColor: SpotifyColors.surfaceElevated,
child: CustomScrollView(
physics: const BouncingScrollPhysics(
parent: AlwaysScrollableScrollPhysics(),
),
slivers: [
// Top Header & Greeting
SliverToBoxAdapter(
child: SafeArea(
bottom: false,
child: Padding(
padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Greeting Row with Account Avatar
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
_getGreeting(),
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textPrimary,
fontSize: 24,
fontWeight: FontWeight.w800,
letterSpacing: -0.5,
),
),
Row(
children: [
IconButton(
splashRadius: 22,
icon: const Icon(
Icons.bolt_rounded,
color: SpotifyColors.textPrimary,
size: 24,
),
onPressed: () {
_loadHomeData(showLoader: false);
},
),
const SizedBox(width: 4),
GestureDetector(
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const AccountScreen(),
),
);
},
child: Container(
width: 34,
height: 34,
decoration: BoxDecoration(
color: SpotifyColors.surfaceElevated,
shape: BoxShape.circle,
border: Border.all(
color: currentTheme.primary.withValues(alpha: 0.5),
width: 1.5,
),
),
child: const Icon(
Icons.person_rounded,
color: SpotifyColors.textPrimary,
size: 20,
),
),
),
],
),
],
),

const SizedBox(height: 14),

// Filter Chips (Spotify Pills)
SizedBox(
height: 32,
child: ListView.separated(
scrollDirection: Axis.horizontal,
itemCount: _filters.length,
separatorBuilder: (_, __) => const SizedBox(width: 8),
itemBuilder: (context, index) {
final isSelected = _selectedFilterIndex == index;
return GestureDetector(
onTap: () {
HapticFeedback.selectionClick();
setState(() {
_selectedFilterIndex = index;
});
},
child: AnimatedContainer(
duration: const Duration(milliseconds: 200),
padding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 6,
),
decoration: BoxDecoration(
color: isSelected
? currentTheme.primary
    : SpotifyColors.surfaceElevated,
borderRadius: BorderRadius.circular(20),
),
child: Text(
_filters[index],
style: GoogleFonts.plusJakartaSans(
color: isSelected
? Colors.black
    : SpotifyColors.textPrimary,
fontSize: 12,
fontWeight: isSelected
? FontWeight.w700
    : FontWeight.w500,
),
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
),

// Loading Indicator or Error
if (_loading)
SliverFillRemaining(
hasScrollBody: false,
child: Center(
child: CircularProgressIndicator(
color: currentTheme.primary,
),
),
)
else if (_error != null)
SliverFillRemaining(
hasScrollBody: false,
child: Center(
child: GestureDetector(
onTap: () => _loadHomeData(),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(
Icons.refresh_rounded,
color: SpotifyColors.textSecondary,
size: 36,
),
const SizedBox(height: 10),
Text(
_error!,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textSecondary,
fontSize: 14,
),
),
],
),
),
),
)
else ...[
            // 1. 2-COLUMN QUICK ACCESS GRID
            if (_selectedFilterIndex == 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: _buildQuickAccessGrid(currentTheme.primary),
                ),
              ),

            // 2. MADE FOR YOU / PLAYLISTS CAROUSEL
            if (_selectedFilterIndex == 0 &&
                _homePlaylists.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildPlaylistsSection(
                  'Made For You',
                  _homePlaylists,
                  currentTheme.primary,
                ),
              ),


            // 3. RECENTLY PLAYED SECTION
            if (_selectedFilterIndex == 0 &&
                _recentlyPlayed.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildRecentlyPlayedSection(currentTheme.primary),
              ),

            // 4. POPULAR ALBUMS CAROUSEL
            if (_selectedFilterIndex == 0 &&
                _homeAlbums.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildAlbumsSection(
                  'Popular Albums',
                  _homeAlbums,
                  currentTheme.primary,
                ),
              ),
            // 5. MUSIC SECTIONS
            // All + Music: show real API music sections, excluding Charts.
            if (_selectedFilterIndex == 0 ||
                _selectedFilterIndex == 1)
              ..._sections.entries
                  .where((entry) => entry.key != 'Charts')
                  .map((entry) {
                if (entry.value.isEmpty) {
                  return const SliverToBoxAdapter();
                }
                return SliverToBoxAdapter(
                  child: _buildTrackSection(
                    entry.key,
                    entry.value,
                    currentTheme.primary,
                  ),
                );
              }),


            // 6. CHARTS ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â real backend chart data
            if (_selectedFilterIndex == 2 &&
                (_sections['Charts'] ?? []).isNotEmpty)
              SliverToBoxAdapter(
                child: _buildTrackSection(
                  'Charts',
                  _sections['Charts']!,
                  currentTheme.primary,
                ),
              ),

            // 7. RADIO
            if (_selectedFilterIndex == 4 &&
                _radioStations.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildRadioSection(
                  _radioStations,
                  currentTheme.primary,
                ),
              ),
            // 7. MOODS ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â real JioSaavn playlist search results
            if (_selectedFilterIndex == 3 && _moodPlaylists.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildPlaylistsSection(
                  'Moods',
                  _moodPlaylists,
                  currentTheme.primary,
                ),
              ),

            // Padding at bottom for Mini Player & Nav Bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 140),
            ),
          ],
],
),
);
}

// ============================================================
// QUICK ACCESS 2-COLUMN GRID
// ============================================================
Widget _buildQuickAccessGrid(Color accentColor) {
// Gather quick items from sections or recently played
final List<Song> quickSongs = [];
if (_recentlyPlayed.isNotEmpty) {
quickSongs.addAll(_recentlyPlayed.take(4));
}
for (final songList in _sections.values) {
for (final song in songList) {
if (quickSongs.length >= 6) break;
if (!quickSongs.any((s) => s.id == song.id)) {
quickSongs.add(song);
}
}
if (quickSongs.length >= 6) break;
}

if (quickSongs.isEmpty) return const SizedBox.shrink();

return GridView.builder(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 2,
mainAxisExtent: 56,
crossAxisSpacing: 8,
mainAxisSpacing: 8,
),
itemCount: quickSongs.length.clamp(0, 6),
itemBuilder: (context, index) {
final song = quickSongs[index];
return GestureDetector(
onTap: () => _playSong(song, quickSongs, index: index),
child: Container(
decoration: BoxDecoration(
color: SpotifyColors.surfaceElevated,
borderRadius: BorderRadius.circular(6),
),
child: Row(
children: [
ClipRRect(
borderRadius: const BorderRadius.horizontal(
left: Radius.circular(6),
),
child: SizedBox(
width: 56,
height: 56,
child: song.thumbnail.isNotEmpty
? Image.network(
song.thumbnail,
fit: BoxFit.cover,
errorBuilder: (_, __, ___) => Container(
color: SpotifyColors.surfaceHighlight,
child: const Icon(
Icons.music_note_rounded,
color: SpotifyColors.textSecondary,
),
),
)
    : Container(
color: SpotifyColors.surfaceHighlight,
child: const Icon(
Icons.music_note_rounded,
color: SpotifyColors.textSecondary,
),
),
),
),
const SizedBox(width: 8),
Expanded(
child: Text(
decodeHtml(song.title),
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textPrimary,
fontSize: 12,
fontWeight: FontWeight.w700,
height: 1.2,
),
),
),
const SizedBox(width: 6),
],
),
),
);
},
);
}

// ============================================================
// PLAYLIST CAROUSEL
// ============================================================
Widget _buildRadioSection(
  List<dynamic> stations,
  Color accentColor,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Text(
          'Radio',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      SizedBox(
        height: 190,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: stations.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final station = stations[index];

            final title = station is Map
                ? station['title']?.toString() ?? 'Radio'
                : 'Radio';

            final subtitle = station is Map
                ? station['subtitle']?.toString() ?? 'Radio Station'
                : 'Radio Station';

            final image = station is Map
                ? station['image']?.toString() ?? ''
                : '';

            return SizedBox(
              width: 145,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: image.isNotEmpty
                            ? Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color: accentColor.withOpacity(0.12),
                                    child: Icon(
                                      Icons.radio_rounded,
                                      size: 42,
                                      color: accentColor,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: accentColor.withOpacity(0.12),
                                child: Icon(
                                  Icons.radio_rounded,
                                  size: 42,
                                  color: accentColor,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
Widget _buildPlaylistsSection(
String title,
List<SearchPlaylistResult> playlists,
Color accentColor,
) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
child: Text(
title,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textPrimary,
fontSize: 20,
fontWeight: FontWeight.w800,
letterSpacing: -0.4,
),
),
),
SizedBox(
height: 200,
child: ListView.separated(
padding: const EdgeInsets.symmetric(horizontal: 16),
scrollDirection: Axis.horizontal,
itemCount: playlists.length,
separatorBuilder: (_, __) => const SizedBox(width: 14),
itemBuilder: (context, index) {
final playlist = playlists[index];
return GestureDetector(
onTap: () async {
HapticFeedback.selectionClick();
final songs = await _repository.getPlaylistSongs(playlist.id);
if (!context.mounted) return;
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => PlaylistScreen(
playlistName: playlist.name,
subtitle: playlist.subtitle,
icon: Icons.playlist_play_rounded,
songs: songs,
),
),
);
},
child: SizedBox(
width: 140,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Square Artwork
ClipRRect(
borderRadius: BorderRadius.circular(8),
child: AspectRatio(
aspectRatio: 1,
child: playlist.image.isNotEmpty
? Image.network(
playlist.image,
fit: BoxFit.cover,
errorBuilder: (_, __, ___) => Container(
color: SpotifyColors.surfaceElevated,
child: const Icon(
Icons.album_rounded,
color: SpotifyColors.textSecondary,
size: 40,
),
),
)
    : Container(
color: SpotifyColors.surfaceElevated,
child: const Icon(
Icons.album_rounded,
color: SpotifyColors.textSecondary,
size: 40,
),
),
),
),
const SizedBox(height: 8),
Text(
decodeHtml(playlist.name),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textPrimary,
fontSize: 13,
fontWeight: FontWeight.w700,
),
),
const SizedBox(height: 2),
Text(
decodeHtml(playlist.subtitle.isNotEmpty
? playlist.subtitle
    : 'Playlist'),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textSecondary,
fontSize: 11,
fontWeight: FontWeight.w500,
),
),
],
),
),
);
},
),
),
const SizedBox(height: 16),
],
);
}

// ============================================================
// RECENTLY PLAYED HORIZONTAL LIST
// ============================================================
Widget _buildRecentlyPlayedSection(Color accentColor) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
child: Text(
'Recently Played',
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textPrimary,
fontSize: 20,
fontWeight: FontWeight.w800,
letterSpacing: -0.4,
),
),
),
SizedBox(
height: 180,
child: ListView.separated(
padding: const EdgeInsets.symmetric(horizontal: 16),
scrollDirection: Axis.horizontal,
itemCount: _recentlyPlayed.length,
separatorBuilder: (_, __) => const SizedBox(width: 14),
itemBuilder: (context, index) {
final song = _recentlyPlayed[index];
return GestureDetector(
onTap: () => _playSong(song, _recentlyPlayed, index: index),
child: SizedBox(
width: 125,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
ClipRRect(
borderRadius: BorderRadius.circular(8),
child: AspectRatio(
aspectRatio: 1,
child: song.thumbnail.isNotEmpty
? Image.network(
song.thumbnail,
fit: BoxFit.cover,
errorBuilder: (_, __, ___) => Container(
color: SpotifyColors.surfaceElevated,
child: const Icon(
Icons.music_note_rounded,
color: SpotifyColors.textSecondary,
),
),
)
    : Container(
color: SpotifyColors.surfaceElevated,
child: const Icon(
Icons.music_note_rounded,
color: SpotifyColors.textSecondary,
),
),
),
),
const SizedBox(height: 8),
Text(
decodeHtml(song.title),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textPrimary,
fontSize: 12,
fontWeight: FontWeight.w700,
),
),
Text(
decodeHtml(song.artist),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textSecondary,
fontSize: 11,
),
),
],
),
),
);
},
),
),
const SizedBox(height: 16),
],
);
}

// ============================================================
// ALBUMS SECTION
// ============================================================
Widget _buildAlbumsSection(
String title,
List<SearchAlbumResult> albums,
Color accentColor,
) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
child: Text(
title,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textPrimary,
fontSize: 20,
fontWeight: FontWeight.w800,
letterSpacing: -0.4,
),
),
),
SizedBox(
height: 190,
child: ListView.separated(
padding: const EdgeInsets.symmetric(horizontal: 16),
scrollDirection: Axis.horizontal,
itemCount: albums.length,
separatorBuilder: (_, __) => const SizedBox(width: 14),
itemBuilder: (context, index) {
final album = albums[index];
return GestureDetector(
onTap: () async {
HapticFeedback.selectionClick();
final songs = await _repository.getAlbumSongs(album.id);
if (!context.mounted) return;
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => PlaylistScreen(
playlistName: album.name,
subtitle: album.artist,
icon: Icons.album_rounded,
songs: songs,
),
),
);
},
child: SizedBox(
width: 130,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
ClipRRect(
borderRadius: BorderRadius.circular(8),
child: AspectRatio(
aspectRatio: 1,
child: album.image.isNotEmpty
? Image.network(
album.image,
fit: BoxFit.cover,
errorBuilder: (_, __, ___) => Container(
color: SpotifyColors.surfaceElevated,
child: const Icon(
Icons.album_rounded,
color: SpotifyColors.textSecondary,
),
),
)
    : Container(
color: SpotifyColors.surfaceElevated,
child: const Icon(
Icons.album_rounded,
color: SpotifyColors.textSecondary,
),
),
),
),
const SizedBox(height: 8),
Text(
decodeHtml(album.name),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textPrimary,
fontSize: 12,
fontWeight: FontWeight.w700,
),
),
Text(
decodeHtml(album.artist),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textSecondary,
fontSize: 11,
),
),
],
),
),
);
},
),
),
const SizedBox(height: 16),
],
);
}

// ============================================================
// TRACKLIST SECTION (VERTICAL TILES)
// ============================================================
Widget _buildTrackSection(
String sectionTitle,
List<Song> songs,
Color accentColor,
) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
child: Text(
sectionTitle,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textPrimary,
fontSize: 20,
fontWeight: FontWeight.w800,
letterSpacing: -0.4,
),
),
),
ListView.builder(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
itemCount: songs.length.clamp(0, 8),
itemBuilder: (context, index) {
final song = songs[index];
return ListTile(
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
leading: ClipRRect(
borderRadius: BorderRadius.circular(6),
child: SizedBox(
width: 48,
height: 48,
child: song.thumbnail.isNotEmpty
? Image.network(
song.thumbnail,
fit: BoxFit.cover,
errorBuilder: (_, __, ___) => Container(
color: SpotifyColors.surfaceElevated,
child: const Icon(
Icons.music_note_rounded,
color: SpotifyColors.textSecondary,
),
),
)
    : Container(
color: SpotifyColors.surfaceElevated,
child: const Icon(
Icons.music_note_rounded,
color: SpotifyColors.textSecondary,
),
),
),
),
title: Text(
decodeHtml(song.title),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textPrimary,
fontSize: 14,
fontWeight: FontWeight.w600,
),
),
subtitle: Text(
decodeHtml(song.artist),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.plusJakartaSans(
color: SpotifyColors.textSecondary,
fontSize: 12,
),
),
trailing: IconButton(
icon: const Icon(
Icons.more_vert_rounded,
color: SpotifyColors.textSecondary,
size: 20,
),
onPressed: () {
showModalBottomSheet(
context: context,
backgroundColor: SpotifyColors.surfaceElevated,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
),
builder: (_) => SongPlaylistPicker(song: song),
);
},
),
onTap: () => _playSong(song, songs, index: index),
);
},
),
const SizedBox(height: 16),
],
);
}
}






















