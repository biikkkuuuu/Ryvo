import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/audio_service.dart';
import 'package:music_app/services/library_service.dart';
import 'package:music_app/theme/app_theme.dart';

class SongPlaylistPicker extends StatefulWidget {
  final Song song;
  final String? currentPlaylistName;
  final VoidCallback? onActionCompleted;

  const SongPlaylistPicker({
    super.key,
    required this.song,
    this.currentPlaylistName,
    this.onActionCompleted,
  });

  @override
  State<SongPlaylistPicker> createState() => _SongPlaylistPickerState();
}

class _SongPlaylistPickerState extends State<SongPlaylistPicker> {
  bool _isLiked = false;
  
  bool _showingPlaylists = false;
  List<String> _playlistNames = [];
  bool _isLoadingPlaylists = false;

  @override
  void initState() {
    super.initState();
    _isLiked = LibraryService.instance.isLiked(widget.song.id);
  }

  void _toggleLike() async {
    HapticFeedback.lightImpact();
    final result = await LibraryService.instance.toggleLike(widget.song);
    setState(() => _isLiked = result);
    if (mounted) Navigator.pop(context);
    _showSnackBar(result ? 'Added to Liked Songs' : 'Removed from Liked Songs');
    if (widget.onActionCompleted != null) widget.onActionCompleted!();
  }

  void _addToQueue() {
    HapticFeedback.lightImpact();
    AudioService().addToQueue(widget.song);
    Navigator.pop(context);
    _showSnackBar('Added to Queue');
  }

  void _playNext() {
    HapticFeedback.lightImpact();
    AudioService().addToQueueNext(widget.song);
    Navigator.pop(context);
    _showSnackBar('Playing Next');
  }

  void _removeFromPlaylist() async {
    HapticFeedback.heavyImpact();
    if (widget.currentPlaylistName == null) return;
    await LibraryService.instance.removeSongFromPlaylist(widget.currentPlaylistName!, widget.song.id);
    if (mounted) Navigator.pop(context);
    _showSnackBar('Removed from ${widget.currentPlaylistName}');
    if (widget.onActionCompleted != null) widget.onActionCompleted!();
  }

  void _loadAndShowPlaylists() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoadingPlaylists = true);
    final names = await LibraryService.instance.getPlaylistNames();
    if (!mounted) return;
    setState(() {
      _playlistNames = names;
      _showingPlaylists = true;
      _isLoadingPlaylists = false;
    });
  }

  void _addToSpecificPlaylist(String name) async {
    HapticFeedback.selectionClick();
    await LibraryService.instance.addSongToPlaylist(name, widget.song);
    if (!mounted) return;
    Navigator.pop(context); 
    _showSnackBar('Added to $name');
  }

  // FIX: Premium Floating SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF1DB954), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message, 
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, // Pure white text
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                )
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2A2A2A), // Solid dark grey 
        behavior: SnackBarBehavior.floating,      // Float above bottom navigation
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        elevation: 8,
      )
    );
  }

  String decodeHtml(String text) {
    return text.replaceAll('&quot;', '"').replaceAll('&#34;', '"').replaceAll('&amp;', '&').replaceAll('&#38;', '&');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: _showingPlaylists ? _buildPlaylistView() : _buildMainMenuView(),
      ),
    );
  }

  Widget _buildMainMenuView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 48, height: 48,
              child: widget.song.thumbnail.isNotEmpty ? Image.network(widget.song.thumbnail, fit: BoxFit.cover) : Container(color: Colors.grey),
            ),
          ),
          title: Text(decodeHtml(widget.song.title), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(decodeHtml(widget.song.artist), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(color: Colors.white54)),
        ),
        const Divider(color: Colors.white24, height: 30),

        _buildActionItem(
          icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: _isLiked ? const Color(0xFF1DB954) : Colors.white,
          text: _isLiked ? 'Remove from Liked Songs' : 'Add to Liked Songs',
          onTap: _toggleLike,
        ),
        _buildActionItem(
          icon: Icons.playlist_add_rounded,
          color: Colors.white,
          text: 'Add to Playlist',
          onTap: _loadAndShowPlaylists,
          isLoading: _isLoadingPlaylists,
        ),
        _buildActionItem(
          icon: Icons.queue_music_rounded,
          color: Colors.white,
          text: 'Add to Queue',
          onTap: _addToQueue,
        ),
        _buildActionItem(
          icon: Icons.skip_next_rounded,
          color: Colors.white,
          text: 'Play Next',
          onTap: _playNext,
        ),
        
        if (widget.currentPlaylistName != null)
          _buildActionItem(
            icon: Icons.remove_circle_outline_rounded,
            color: Colors.redAccent,
            text: 'Remove from this Playlist',
            onTap: _removeFromPlaylist,
          ),
      ],
    );
  }

  Widget _buildPlaylistView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => setState(() => _showingPlaylists = false),
            ),
            Expanded(
              child: Text(
                'Add to Playlist',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_playlistNames.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('No playlists created yet.', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 15)),
          )
        else
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: _playlistNames.length,
                itemBuilder: (c, i) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.music_note_rounded, color: Colors.white70),
                  ),
                  title: Text(_playlistNames[i], style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  onTap: () => _addToSpecificPlaylist(_playlistNames[i]),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionItem({required IconData icon, required Color color, required String text, required VoidCallback onTap, bool isLoading = false}) {
    return ListTile(
      leading: isLoading 
          ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Icon(icon, color: color, size: 28),
      title: Text(text, style: GoogleFonts.plusJakartaSans(color: color, fontSize: 16, fontWeight: FontWeight.w600)),
      onTap: isLoading ? null : onTap,
    );
  }
}