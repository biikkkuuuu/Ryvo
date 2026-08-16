import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_app/features/playlist/playlist_screen.dart';
import 'package:music_app/features/welcome/welcome_screen.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/library_service.dart';
import 'package:music_app/app/theme_controller.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final LibraryService _library = LibraryService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _playlists = [];
  bool _loadingPlaylists = true;

  User? get _user => _auth.currentUser;

  // Google/Firebase user ko Guest nahi maana jayega.
  bool get _isGuest {
    final user = _user;

    if (user == null) {
      return true;
    }

    final isGoogleUser = user.providerData.any(
          (provider) => provider.providerId == 'google.com',
    );

    if (isGoogleUser) {
      return false;
    }

    return user.isAnonymous;
  }

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    await _library.init();

    final playlists = await _library.getPlaylistNames();

    if (!mounted) return;

    setState(() {
      _playlists = playlists;
      _loadingPlaylists = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    final displayName = _isGuest
        ? 'Guest User'
        : (user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'RYVO User');

    final email = _isGuest
        ? 'Listening as guest'
        : (user?.email?.trim().isNotEmpty == true
        ? user!.email!.trim()
        : 'RYVO music space');

    return AnimatedBuilder(
      animation: RyvoThemeController.instance,
      builder: (context, _) {
        final currentTheme = RyvoThemeController.themes[
        RyvoThemeController.instance.selectedTheme
        ];

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: const Color(0xff0A0614),
            extendBody: true,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 32,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Account',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          currentTheme.primaryDark.withValues(
                            alpha: 0.95,
                          ),
                          const Color(0xff3B1670),
                          const Color(0xff1B0E33),
                          const Color(0xff0A0614),
                        ],
                        stops: const [
                          0.0,
                          0.32,
                          0.68,
                          1.0,
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: -120,
                  left: -110,
                  child: _ambientLight(
                    size: 300,
                    color: currentTheme.primary,
                  ),
                ),

                Positioned(
                  top: 500,
                  right: -130,
                  child: _ambientLight(
                    size: 270,
                    color: currentTheme.primaryDark,
                  ),
                ),

                Positioned(
                  bottom: -100,
                  left: -100,
                  child: _ambientLight(
                    size: 250,
                    color: currentTheme.primary,
                  ),
                ),

                SafeArea(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      68,
                      18,
                      120,
                    ),
                    children: [
                      // ====================================================
                      // PROFILE
                      // ====================================================

                      _glass(
                        child: Row(
                          children: [
                            _profileAvatar(user),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    email,
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

                            _circleButton(
                              Icons.edit_rounded,
                              _showEditProfile,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ====================================================
                      // YOUR MUSIC
                      // ====================================================

                      _sectionTitle('Your Music'),

                      _menuTile(
                        Icons.queue_music_rounded,
                        'My Playlists',
                        _loadingPlaylists
                            ? 'Loading playlists...'
                            : _playlists.isEmpty
                            ? 'Create your first playlist'
                            : '${_playlists.length} playlist${_playlists.length == 1 ? '' : 's'}',
                        _openPlaylists,
                      ),

                      const SizedBox(height: 18),

                      // ====================================================
                      // PREFERENCES
                      // ====================================================

                      _sectionTitle('Preferences'),

                      _menuTile(
                        Icons.palette_rounded,
                        'Theme',
                        currentTheme.name,
                        _showThemeSheet,
                      ),

                      const SizedBox(height: 18),

                      // ====================================================
                      // APP
                      // ====================================================

                      _sectionTitle('App'),

                      _menuTile(
                        Icons.info_outline_rounded,
                        'About RYVO',
                        'Version, credits and information',
                        _showAbout,
                      ),

                      _menuTile(
                        Icons.privacy_tip_outlined,
                        'Privacy',
                        'How RYVO handles your app data',
                        _showPrivacy,
                      ),

                      _menuTile(
                        Icons.description_outlined,
                        'Terms & Conditions',
                        'RYVO app terms',
                        _showTerms,
                      ),

                      const SizedBox(height: 18),

                      // ====================================================
                      // LOGOUT
                      // ====================================================

                      _glass(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: _confirmLogout,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 17,
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
                                  _isGuest
                                      ? 'Exit Guest Mode'
                                      : 'Log out',
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

                      // ====================================================
                      // BRANDING
                      // ====================================================

                      Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: currentTheme.primaryLight,
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
                                  decoration: BoxDecoration(
                                    color: currentTheme.primaryLight,
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
                                color: Colors.white24,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
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
  // PROFILE
  // ============================================================

  Widget _profileAvatar(User? user) {
    final photoUrl = user?.photoURL;

    if (!_isGuest &&
        photoUrl != null &&
        photoUrl.trim().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: 62,
          height: 62,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return _fallbackAvatar();
          },
        ),
      );
    }

    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    final theme = RyvoThemeController.themes[
    RyvoThemeController.instance.selectedTheme
    ];

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.primaryLight,
            theme.primaryDark,
          ],
        ),
      ),
      child: Icon(
        _isGuest
            ? Icons.person_outline_rounded
            : Icons.person_rounded,
        color: Colors.white,
        size: 31,
      ),
    );
  }

  Future<void> _showEditProfile() async {
    final user = _user;

    if (_isGuest || user == null) {
      _showMessage(
        'Guest users cannot edit profile',
      );
      return;
    }

    final controller = TextEditingController(
      text: user.displayName ?? '',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff101516),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Update your display name',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  labelText: 'Display name',
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(
                    alpha: 0.05,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    final name = controller.text.trim();

                    if (name.isEmpty) {
                      _showMessage('Enter a name');
                      return;
                    }

                    try {
                      await user.updateDisplayName(name);

                      if (!mounted) return;

                      // Close the bottom sheet before rebuilding the Account
                      // screen. Calling user.reload() here can trigger an
                      // auth-state update while the modal is still mounted,
                      // which can cause a Flutter framework assertion.
                      Navigator.of(context).pop();

                      setState(() {});
                      _showMessage('Profile updated');
                    } on FirebaseAuthException catch (e) {
                      if (!mounted) return;

                      _showMessage(
                        e.message ?? 'Unable to update profile',
                      );
                    } catch (e) {
                      if (!mounted) return;

                      _showMessage(
                        'Unable to update profile',
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();
  }

  // ============================================================
  // PLAYLISTS
  // ============================================================

  Future<void> _openPlaylists() async {
    await _loadPlaylists();

    if (!mounted) return;

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
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            Future<void> refresh() async {
              final names =
              await _library.getPlaylistNames();

              if (!sheetContext.mounted) return;

              sheetSetState(() {
                _playlists = names;
              });

              if (mounted) {
                setState(() {});
              }
            }

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
                              'My Playlists',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Create playlist',
                            onPressed: () async {
                              await _createPlaylist();

                              if (sheetContext.mounted) {
                                await refresh();
                              }
                            },
                            icon: const Icon(
                              Icons.add_rounded,
                              color: Color(0xffA78BFA),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      color: Colors.white10,
                      height: 1,
                    ),
                    Expanded(
                      child: _playlists.isEmpty
                          ? _emptyPlaylistState(
                        onCreate: () async {
                          await _createPlaylist();

                          if (sheetContext.mounted) {
                            await refresh();
                          }
                        },
                      )
                          : ListView.builder(
                        physics:
                        const BouncingScrollPhysics(),
                        padding:
                        const EdgeInsets.all(16),
                        itemCount: _playlists.length,
                        itemBuilder:
                            (context, index) {
                          final name =
                          _playlists[index];

                          return _playlistTile(
                            context,
                            name,
                            refresh,
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

  Widget _playlistTile(
      BuildContext context,
      String name,
      Future<void> Function() refresh,
      ) {
    return FutureBuilder<List<Song>>(
      future: _library.getPlaylist(name),
      builder: (context, snapshot) {
        final songs = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _glass(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                Navigator.pop(context);

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaylistScreen(
                      playlistName: name,
                      subtitle: 'Your RYVO playlist',
                      icon: Icons.queue_music_rounded,
                      songs: songs,
                    ),
                  ),
                );

                if (mounted) {
                  _loadPlaylists();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xffA78BFA),
                            Color(0xff5B21B6),
                          ],
                        ),
                        borderRadius:
                        BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.queue_music_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${songs.length} song${songs.length == 1 ? '' : 's'}',
                            style: GoogleFonts.poppins(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      color: const Color(0xff17121F),
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white54,
                      ),
                      onSelected: (value) async {
                        if (value == 'rename') {
                          await _renamePlaylist(name);
                        } else if (value == 'delete') {
                          await _deletePlaylist(name);
                        }

                        await refresh();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text('Rename'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyPlaylistState({
    required VoidCallback onCreate,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.queue_music_rounded,
              color: Colors.white24,
              size: 55,
            ),
            const SizedBox(height: 14),
            Text(
              'No playlists yet',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Create a playlist and start adding songs.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Playlist'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff17121F),
          title: const Text(
            'Create Playlist',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Playlist name',
              hintStyle: TextStyle(
                color: Colors.white38,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) {
      return;
    }

    final created =
    await _library.createPlaylist(name.trim());

    if (!mounted) return;

    if (created) {
      await _loadPlaylists();
      _showMessage('Playlist created');
    } else {
      _showMessage(
        'Playlist already exists or name is invalid',
      );
    }
  }

  Future<void> _renamePlaylist(String oldName) async {
    final controller =
    TextEditingController(text: oldName);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff17121F),
          title: const Text(
            'Rename Playlist',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'New playlist name',
              hintStyle: TextStyle(
                color: Colors.white38,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName == null || newName.trim().isEmpty) {
      return;
    }

    if (newName.trim().toLowerCase() ==
        oldName.trim().toLowerCase()) {
      return;
    }

    final renamed = await _library.renamePlaylist(
      oldName,
      newName.trim(),
    );

    if (!mounted) return;

    if (renamed) {
      await _loadPlaylists();
      _showMessage('Playlist renamed');
    } else {
      _showMessage(
        'Unable to rename playlist',
      );
    }
  }

  Future<void> _deletePlaylist(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff17121F),
          title: const Text(
            'Delete Playlist?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Delete "$name"? The songs will only be removed from this playlist.',
            style: const TextStyle(
              color: Colors.white60,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                const Color(0xffB91C1C),
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final deleted =
    await _library.deletePlaylist(name);

    if (!mounted) return;

    if (deleted) {
      await _loadPlaylists();
      _showMessage('Playlist deleted');
    } else {
      _showMessage(
        'Unable to delete playlist',
      );
    }
  }

  // ============================================================
  // THEME
  // ============================================================

  void _showThemeSheet() {
    final controller =
        RyvoThemeController.instance;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff101516),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Theme',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Theme applies across RYVO',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(
                    RyvoThemeController.themes.length,
                        (index) {
                      final theme =
                      RyvoThemeController.themes[index];

                      final selected =
                          controller.selectedTheme ==
                              index;

                      return Padding(
                        padding:
                        const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: InkWell(
                          borderRadius:
                          BorderRadius.circular(18),
                          onTap: () async {
                            await controller
                                .setTheme(index);

                            if (!mounted) return;

                            setState(() {});
                          },
                          child: Container(
                            padding:
                            const EdgeInsets.all(12),
                            decoration:
                            BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  .withValues(
                                alpha: 0.08,
                              )
                                  : Colors.white
                                  .withValues(
                                alpha: 0.035,
                              ),
                              borderRadius:
                              BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? theme.primaryLight
                                    : Colors.white10,
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
                                    BorderRadius.circular(
                                      12,
                                    ),
                                    gradient:
                                    LinearGradient(
                                      colors: [
                                        theme.primaryLight,
                                        theme.primaryDark,
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(
                                        theme.name,
                                        style:
                                        GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        theme.subtitle,
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
                                if (selected)
                                  Icon(
                                    Icons
                                        .check_circle_rounded,
                                    color:
                                    theme.primaryLight,
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
  // ABOUT / PRIVACY / TERMS
  // ============================================================

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'RYVO',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.graphic_eq_rounded,
      ),
      children: const [
        Text(
          'A clean music player built for the RYVO project.',
        ),
      ],
    );
  }

  void _showPrivacy() {
    _showInformationSheet(
      title: 'Privacy',
      icon: Icons.privacy_tip_outlined,
      sections: const [
        _InfoSection(
          title: 'Account',
          text:
          'When you sign in with Google, RYVO uses Firebase Authentication to maintain your signed-in state.',
        ),
        _InfoSection(
          title: 'Local music data',
          text:
          'Your RYVO library data such as playlists, liked songs and recently played songs is stored locally by the app.',
        ),
        _InfoSection(
          title: 'Control',
          text:
          'You can sign out from the Account section whenever you choose.',
        ),
      ],
    );
  }

  void _showTerms() {
    _showInformationSheet(
      title: 'Terms & Conditions',
      icon: Icons.description_outlined,
      sections: const [
        _InfoSection(
          title: 'Use of RYVO',
          text:
          'RYVO is provided as a music playback application for personal use.',
        ),
        _InfoSection(
          title: 'Content',
          text:
          'Music availability depends on the services and sources used by the application. RYVO does not claim ownership of third-party music content.',
        ),
        _InfoSection(
          title: 'Changes',
          text:
          'Application features and functionality may change as RYVO is developed.',
        ),
      ],
    );
  }

  void _showInformationSheet({
    required String title,
    required IconData icon,
    required List<_InfoSection> sections,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff101516),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height:
            MediaQuery.of(sheetContext).size.height *
                0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    12,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 2),
                      Icon(
                        icon,
                        color: const Color(0xffA78BFA),
                      ),
                      const SizedBox(width: 10),
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
                    ],
                  ),
                ),
                const Divider(
                  color: Colors.white10,
                  height: 1,
                ),
                Expanded(
                  child: ListView(
                    physics:
                    const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      ...sections.map(
                            (section) => Padding(
                          padding:
                          const EdgeInsets.only(
                            bottom: 22,
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.title,
                                style:
                                GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight:
                                  FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                section.text,
                                style:
                                GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
  // LOGOUT
  // ============================================================

  Future<void> _confirmLogout() async {
    final isGuest = _isGuest;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff17121F),
          title: Text(
            isGuest ? 'Exit Guest Mode?' : 'Log out?',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          content: Text(
            isGuest
                ? 'You will return to the RYVO welcome screen.'
                : 'You will be signed out of your RYVO account.',
            style: const TextStyle(
              color: Colors.white60,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                const Color(0xffB91C1C),
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: Text(
                isGuest ? 'Exit' : 'Log out',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _auth.signOut();

      if (!mounted) return;

      // Account is displayed inside Home. Explicitly replace the root route
      // so logout always returns to the Welcome screen after Firebase signs
      // the user out.
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.message ?? 'Unable to log out',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to log out. Please try again.',
      );
    }
  }

  // ============================================================
  // UI HELPERS
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
            color: Colors.white.withValues(
              alpha: 0.055,
            ),
            borderRadius:
            BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

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
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
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

  Widget _iconBox(IconData icon) {
    final theme = RyvoThemeController.themes[
    RyvoThemeController.instance.selectedTheme
    ];

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: theme.primary.withValues(
          alpha: 0.14,
        ),
        borderRadius:
        BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: theme.primaryLight,
        size: 21,
      ),
    );
  }

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
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
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

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 12,
            ),
          ),
          behavior:
          SnackBarBehavior.floating,
          backgroundColor:
          const Color(0xff181D1E),
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            18,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(16),
          ),
        ),
      );
  }
}

class _InfoSection {
  final String title;
  final String text;

  const _InfoSection({
    required this.title,
    required this.text,
  });
}
