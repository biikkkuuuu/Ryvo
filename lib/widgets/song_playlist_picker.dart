import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_app/models/song.dart';
import 'package:music_app/services/library_service.dart';

class SongPlaylistPicker {
  static Future<void> show(
      BuildContext context,
      Song song,
      ) async {
    await LibraryService.instance.init();

    final playlists =
    await LibraryService.instance.getPlaylistNames();

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: const Color(0xff111416),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Add to Playlist',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: const Color(0xffA78BFA)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        Navigator.pop(sheetContext);

                        final createdName =
                        await _createPlaylist(context);

                        if (createdName == null ||
                            !context.mounted) {
                          return;
                        }

                        final added =
                        await LibraryService.instance
                            .addSongToPlaylist(
                          createdName,
                          song,
                        );

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              added
                                  ? 'Added to $createdName'
                                  : 'Song is already in $createdName',
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xffA78BFA)
                                    .withValues(alpha: 0.13),
                                borderRadius:
                                BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Color(0xffA78BFA),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Create New Playlist',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                if (playlists.isNotEmpty) ...[
                  const SizedBox(height: 12),

                  ...playlists.map(
                        (playlistName) {
                      return Padding(
                        padding:
                        const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.white.withValues(
                            alpha: 0.035,
                          ),
                          borderRadius:
                          BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius:
                            BorderRadius.circular(16),
                            onTap: () async {
                              Navigator.pop(sheetContext);

                              final added =
                              await LibraryService
                                  .instance
                                  .addSongToPlaylist(
                                playlistName,
                                song,
                              );

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    added
                                        ? 'Added to $playlistName'
                                        : 'Song is already in $playlistName',
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding:
                              const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.queue_music_rounded,
                                    color:
                                    Color(0xffA78BFA),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      playlistName,
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      style:
                                      GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight:
                                        FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons
                                        .chevron_right_rounded,
                                    color: Colors.white24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 4),

                TextButton(
                  onPressed: () =>
                      Navigator.pop(sheetContext),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<String?> _createPlaylist(
      BuildContext context,
      ) async {
    String name = '';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff111416),
          title: Text(
            'Create Playlist',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              name = value;
            },
            decoration: const InputDecoration(
              hintText: 'Playlist name',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () async {
                final cleanName = name.trim();

                if (cleanName.isEmpty) return;

                final created =
                await LibraryService.instance
                    .createPlaylist(cleanName);

                if (!dialogContext.mounted) return;

                if (!created) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Playlist already exists.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  cleanName,
                );
              },
              child: const Text(
                'Create',
                style: TextStyle(
                  color: Color(0xffA78BFA),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}