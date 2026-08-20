import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/library_service.dart';
import 'package:music_app/theme/app_theme.dart';

class SongPlaylistPicker extends StatefulWidget {
  final Song song;
  const SongPlaylistPicker({super.key, required this.song});

  static Future<void> show(BuildContext context, Song song) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: SpotifyColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SongPlaylistPicker(song: song),
    );
  }

  @override
  State<SongPlaylistPicker> createState() => _SongPlaylistPickerState();
}

class _SongPlaylistPickerState extends State<SongPlaylistPicker> {
  List<String> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    await LibraryService.instance.init();
    final names = await LibraryService.instance.getPlaylistNames();
    if (!mounted) return;
    setState(() {
      _playlists = names;
      _loading = false;
    });
  }

  Future<void> _createNewPlaylist() async {
    String playlistName = '';
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: SpotifyColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'New Playlist',
            style: GoogleFonts.plusJakartaSans(
              color: SpotifyColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: SpotifyColors.textPrimary),
            onChanged: (val) => playlistName = val,
            decoration: const InputDecoration(
              hintText: 'Playlist name',
              hintStyle: TextStyle(color: SpotifyColors.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: SpotifyColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, playlistName.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: SpotifyColors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Create', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
      await LibraryService.instance.createPlaylist(name);
      await _addToPlaylist(name);
    }
  }

  Future<void> _addToPlaylist(String playlistName) async {
    final added = await LibraryService.instance.addSongToPlaylist(playlistName, widget.song);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(added ? 'Added to $playlistName' : 'Song already in $playlistName'),
        backgroundColor: SpotifyColors.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add to playlist',
              style: GoogleFonts.plusJakartaSans(
                color: SpotifyColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SpotifyColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add_rounded, color: SpotifyColors.green),
              ),
              title: Text(
                'New playlist',
                style: GoogleFonts.plusJakartaSans(
                  color: SpotifyColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              onTap: _createNewPlaylist,
            ),
            const Divider(color: Colors.white10, height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: SpotifyColors.green))
            else if (_playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No playlists yet. Create your first playlist!',
                  style: GoogleFonts.plusJakartaSans(color: SpotifyColors.textSecondary, fontSize: 13),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final name = _playlists[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: SpotifyColors.surfaceHighlight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.music_note_rounded, color: SpotifyColors.textSecondary),
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          color: SpotifyColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () => _addToPlaylist(name),
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
