import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/features/player/player_screen.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/library_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int selectedTheme = 0;

  bool notifications = true;
  bool wifiOnly = false;
  bool gaplessPlayback = true;

  final List<_ThemeOption> themes = const [
    _ThemeOption(
      name: 'Aurora',
      subtitle: 'RYVO Purple',
      colors: [
        Color(0xffA78BFA),
        Color(0xff5B21B6),
      ],
    ),
    _ThemeOption(
      name: 'Ocean',
      subtitle: 'Cool Blue',
      colors: [
        Color(0xff38BDF8),
        Color(0xff0369A1),
      ],
    ),
    _ThemeOption(
      name: 'Sunset',
      subtitle: 'Warm Orange',
      colors: [
        Color(0xffFB923C),
        Color(0xffC2410C),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff070B0C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Account',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 35),
        children: [
          // =====================================================
          // PROFILE
          // =====================================================

          _glass(
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xffA78BFA),
                        Color(0xff5B21B6),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RYVO User',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Your music space',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _circleButton(
                  Icons.edit_rounded,
                      () {
                    _showMessage(
                      'Profile editing coming next',
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // =====================================================
          // YOUR MUSIC
          // =====================================================

          _sectionTitle('Your Music'),

          _menuTile(
            Icons.favorite_rounded,
            'Liked Songs',
            'Songs you love',
                () {
              _openLikedSongs();
            },
          ),

          _menuTile(
            Icons.history_rounded,
            'Recently Played',
            'Your latest 20 songs',
                () {
              _openRecentlyPlayed();
            },
          ),

          _menuTile(
            Icons.queue_music_rounded,
            'My Playlists',
            'Manage your playlists',
                () {
              _showMessage(
                'Playlist manager',
              );
            },
          ),

          _menuTile(
            Icons.download_rounded,
            'Downloads',
            'Your offline music',
                () {
              _showMessage(
                'Downloads section',
              );
            },
          ),

          const SizedBox(height: 18),

          // =====================================================
          // PREFERENCES
          // =====================================================

          _sectionTitle('Preferences'),

          _menuTile(
            Icons.palette_rounded,
            'Theme',
            themes[selectedTheme].name,
            _showThemeSheet,
          ),

          _switchTile(
            Icons.notifications_active_rounded,
            'Notifications',
            'New music and app updates',
            notifications,
                (value) {
              setState(() {
                notifications = value;
              });
            },
          ),

          _switchTile(
            Icons.wifi_rounded,
            'Wi-Fi Only Downloads',
            'Avoid mobile data for downloads',
            wifiOnly,
                (value) {
              setState(() {
                wifiOnly = value;
              });
            },
          ),

          _switchTile(
            Icons.all_inclusive_rounded,
            'Gapless Playback',
            'Smooth transition between songs',
            gaplessPlayback,
                (value) {
              setState(() {
                gaplessPlayback = value;
              });
            },
          ),

          const SizedBox(height: 18),

          // =====================================================
          // APP
          // =====================================================

          _sectionTitle('App'),

          _menuTile(
            Icons.storage_rounded,
            'Storage & Cache',
            'Manage downloaded music and cache',
            _showStorageSheet,
          ),

          _menuTile(
            Icons.info_outline_rounded,
            'About RYVO',
            'Version, credits and information',
            _showAbout,
          ),

          _menuTile(
            Icons.privacy_tip_outlined,
            'Privacy',
            'Privacy information',
                () {
              _showMessage(
                'Privacy page',
              );
            },
          ),

          _menuTile(
            Icons.description_outlined,
            'Terms & Conditions',
            'App terms and conditions',
                () {
              _showMessage(
                'Terms & Conditions',
              );
            },
          ),

          const SizedBox(height: 14),

          // =====================================================
          // LOGOUT
          // =====================================================

          _glass(
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                _showMessage(
                  'Logout can be connected when authentication is added',
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: Color(0xffff7777),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'Log out',
                      style: GoogleFonts.poppins(
                        color: const Color(0xffff7777),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // =====================================================
          // RYVO BRANDING
          // =====================================================

          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xffA78BFA),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'RYVO',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xffA78BFA),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Text(
                  'CRAFTED BY RANA',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Made with music & code',
                  style: GoogleFonts.poppins(
                    color: Colors.white24,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Version 1.0.0',
                  style: GoogleFonts.poppins(
                    color: Colors.white12,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // LIKED SONGS
  // ============================================================

  Future<void> _openLikedSongs() async {
    final songs =
    await LibraryService.instance.getLikedSongs();

    if (!mounted) return;

    _showSongList(
      title: 'Liked Songs',
      songs: songs,
      emptyText: 'No liked songs yet',
      canClear: true,
      clearAction: () async {
        await LibraryService.instance.clearLikedSongs();
      },
    );
  }

  // ============================================================
  // RECENTLY PLAYED
  // ============================================================

  Future<void> _openRecentlyPlayed() async {
    final songs =
    await LibraryService.instance.getRecentlyPlayed();

    if (!mounted) return;

    _showSongList(
      title: 'Recently Played',
      songs: songs,
      emptyText: 'No recently played songs',
      canClear: true,
      clearAction: () async {
        await LibraryService.instance.clearRecentlyPlayed();
      },
    );
  }

  // ============================================================
  // SONG LIST
  // ============================================================

  void _showSongList({
    required String title,
    required List<Song> songs,
    required String emptyText,
    bool canClear = false,
    Future<void> Function()? clearAction,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff0B1011),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height:
            MediaQuery.of(context).size.height * 0.78,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    12,
                    10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (canClear)
                        IconButton(
                          tooltip: 'Clear',
                          onPressed:
                          songs.isEmpty ||
                              clearAction == null
                              ? null
                              : () async {
                            await clearAction();

                            if (sheetContext
                                .mounted) {
                              Navigator.pop(
                                sheetContext,
                              );
                            }

                            if (mounted) {
                              setState(() {});
                            }
                          },
                          icon: const Icon(
                            Icons.delete_sweep_rounded,
                            color: Colors.white60,
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: songs.isEmpty
                      ? _emptySongState(
                    title,
                    emptyText,
                  )
                      : ListView.builder(
                    physics:
                    const BouncingScrollPhysics(),
                    itemCount: songs.length,
                    itemBuilder:
                        (context, index) {
                      final song =
                      songs[index];

                      return ListTile(
                        contentPadding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 18,
                          vertical: 4,
                        ),
                        leading: ClipRRect(
                          borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                          child: Image.network(
                            song.thumbnail,
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                                context,
                                error,
                                stackTrace,
                                ) {
                              return Container(
                                width: 54,
                                height: 54,
                                color:
                                Colors.white10,
                                child:
                                const Icon(
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
                          _decodeSongText(
                            song.title,
                          ),
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          GoogleFonts.poppins(
                            color:
                            Colors.white,
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _decodeSongText(
                            song.artist,
                          ),
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          GoogleFonts.poppins(
                            color:
                            Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                        trailing:
                        const Icon(
                          Icons
                              .play_circle_fill_rounded,
                          color:
                          Color(0xffA78BFA),
                          size: 29,
                        ),
                        onTap: () {
                          Navigator.pop(
                            sheetContext,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlayerScreen(
                                    title:
                                    song.title,
                                    artist:
                                    song.artist,
                                    image:
                                    song.thumbnail,
                                    songId:
                                    song.id,
                                    playlist:
                                    songs,
                                    currentIndex:
                                    index,
                                  ),
                            ),
                          );
                        },
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
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptySongState(
      String title,
      String emptyText,
      ) {
    final isLiked =
        title == 'Liked Songs';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLiked
                ? Icons.favorite_border_rounded
                : Icons.history_rounded,
            color: Colors.white24,
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            emptyText,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HTML DECODE
  // ============================================================

  String _decodeSongText(String text) {
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
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        4,
        0,
        4,
        8,
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // GLASS
  // ============================================================

  Widget _glass({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color:
            Colors.white.withValues(
              alpha: 0.055,
            ),
            borderRadius:
            BorderRadius.circular(22),
            border: Border.all(
              color:
              Colors.white.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // MENU TILE
  // ============================================================

  Widget _menuTile(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: _glass(
        child: InkWell(
          onTap: onTap,
          borderRadius:
          BorderRadius.circular(18),
          child: Row(
            children: [
              _iconBox(icon),
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
                        color: Colors.white
                            .withValues(
                          alpha: 0.45,
                        ),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SWITCH TILE
  // ============================================================

  Widget _switchTile(
      IconData icon,
      String title,
      String subtitle,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: _glass(
        child: Row(
          children: [
            _iconBox(icon),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white
                          .withValues(
                        alpha: 0.45,
                      ),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor:
              const Color(0xffA78BFA),
              activeTrackColor:
              const Color(0xff5B21B6),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ICON BOX
  // ============================================================

  Widget _iconBox(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xff8B5CF6)
            .withValues(alpha: 0.14),
        borderRadius:
        BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: const Color(0xffC4B5FD),
        size: 21,
      ),
    );
  }

  // ============================================================
  // PROFILE BUTTON
  // ============================================================

  Widget _circleButton(
      IconData icon,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(22),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white
              .withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white70,
          size: 19,
        ),
      ),
    );
  }

  // ============================================================
  // THEME
  // ============================================================

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
      const Color(0xff101516),
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, sheetSetState) {
            return Padding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                28,
              ),
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Theme',
                    style:
                    GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Pick a built-in RYVO look',
                    style:
                    GoogleFonts.poppins(
                      color: Colors.white
                          .withValues(
                        alpha: 0.45,
                      ),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(
                    themes.length,
                        (index) {
                      final theme =
                      themes[index];

                      final selected =
                          selectedTheme ==
                              index;

                      return Padding(
                        padding:
                        const EdgeInsets
                            .only(
                          bottom: 10,
                        ),
                        child: InkWell(
                          borderRadius:
                          BorderRadius
                              .circular(
                            18,
                          ),
                          onTap: () {
                            setState(() {
                              selectedTheme =
                                  index;
                            });

                            sheetSetState(
                                  () {},
                            );
                          },
                          child: Container(
                            padding:
                            const EdgeInsets
                                .all(
                              12,
                            ),
                            decoration:
                            BoxDecoration(
                              color: selected
                                  ? Colors
                                  .white
                                  .withValues(
                                alpha:
                                0.08,
                              )
                                  : Colors
                                  .white
                                  .withValues(
                                alpha:
                                0.035,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                18,
                              ),
                              border:
                              Border.all(
                                color: selected
                                    ? theme
                                    .colors
                                    .first
                                    : Colors
                                    .white10,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 38,
                                  decoration:
                                  BoxDecoration(
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      12,
                                    ),
                                    gradient:
                                    LinearGradient(
                                      colors:
                                      theme
                                          .colors,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Expanded(
                                  child:
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(
                                        theme
                                            .name,
                                        style:
                                        GoogleFonts
                                            .poppins(
                                          color:
                                          Colors
                                              .white,
                                          fontWeight:
                                          FontWeight
                                              .w600,
                                        ),
                                      ),
                                      Text(
                                        theme
                                            .subtitle,
                                        style:
                                        GoogleFonts
                                            .poppins(
                                          color: Colors
                                              .white
                                              .withValues(
                                            alpha:
                                            0.45,
                                          ),
                                          fontSize:
                                          10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons
                                        .check_circle_rounded,
                                    color:
                                    Color(
                                      0xffA78BFA,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // STORAGE
  // ============================================================

  void _showStorageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
      const Color(0xff101516),
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.storage_rounded,
                color:
                Color(0xffA78BFA),
                size: 38,
              ),
              const SizedBox(height: 10),
              Text(
                'Storage & Cache',
                style:
                GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Cache management can be connected to local storage next.',
                textAlign:
                TextAlign.center,
                style:
                GoogleFonts.poppins(
                  color: Colors.white
                      .withValues(
                    alpha: 0.45,
                  ),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child:
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );

                    _showMessage(
                      'Cache cleared',
                    );
                  },
                  icon: const Icon(
                    Icons
                        .delete_sweep_rounded,
                  ),
                  label: const Text(
                    'Clear Cache',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // ABOUT
  // ============================================================

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'RYVO',
      applicationVersion: '1.0.0',
      applicationIcon:
      const Icon(
        Icons.graphic_eq_rounded,
      ),
      children: const [
        Text(
          'A clean music player built for the RYVO project.',
        ),
      ],
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
          SnackBarBehavior.floating,
          backgroundColor:
          const Color(0xff181D1E),
        ),
      );
  }
}

// ================================================================
// THEME MODEL
// ================================================================

class _ThemeOption {
  final String name;
  final String subtitle;
  final List<Color> colors;

  const _ThemeOption({
    required this.name,
    required this.subtitle,
    required this.colors,
  });
}