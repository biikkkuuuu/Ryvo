import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/services/audio_service.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String artist;
  final String image;
  final String songId;

  const PlayerScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.image,
  required this.songId,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
final AudioService audioService = AudioService();

bool isPlaying = false;
Duration currentPosition = Duration.zero;
Duration totalDuration = Duration.zero;

@override
void initState() {
  super.initState();

  print("Player Screen Opened");

  audioService.playSong(widget.songId);

  isPlaying = true;

  audioService.positionStream.listen((position) {
    if (!mounted) return;

    setState(() {
      currentPosition = position;
    });
  });

  audioService.durationStream.listen((duration) {
    if (!mounted) return;

    setState(() {
      totalDuration = duration ?? Duration.zero;
    });
  });
}

@override
void dispose() {
audioService.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.black,

appBar: AppBar(
backgroundColor: Colors.black,
elevation: 0,
centerTitle: true,
title: Text(
"Now Playing",
style: GoogleFonts.poppins(
color: Colors.white,
fontWeight: FontWeight.w600,
),
),
),

body: SafeArea(
child: SingleChildScrollView(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
children: [
const SizedBox(height: 20),

  SizedBox(
    width: MediaQuery.of(context).size.width * 0.75,
    height: MediaQuery.of(context).size.width * 0.75,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Image.network(
        widget.image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            color: const Color(0xff181818),
            child: const Icon(
              Icons.music_note,
              color: Colors.white,
              size: 80,
            ),
          );
        },
      ),
    ),
  ),

const SizedBox(height: 30),

Text(
widget.title,
textAlign: TextAlign.center,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: GoogleFonts.poppins(
color: Colors.white,
fontSize: 24,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 10),

Text(
widget.artist,
style: GoogleFonts.poppins(
color: Colors.white54,
fontSize: 18,
),
),

const SizedBox(height: 40),

  Slider(
    value: currentPosition.inSeconds
        .toDouble()
        .clamp(
      0,
      totalDuration.inSeconds == 0
          ? 1
          : totalDuration.inSeconds.toDouble(),
    ),
    min: 0,
    max: totalDuration.inSeconds == 0
        ? 1
        : totalDuration.inSeconds.toDouble(),
    activeColor: const Color(0xff8B5CF6),
    inactiveColor: Colors.white24,
    onChanged: (value) async {
      await audioService.seek(
        Duration(seconds: value.toInt()),
      );
    },
  ),

  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        "${currentPosition.inMinutes}:${(currentPosition.inSeconds % 60).toString().padLeft(2, '0')}",
        style: GoogleFonts.poppins(
          color: Colors.white54,
        ),
      ),
      Text(
        "${totalDuration.inMinutes}:${(totalDuration.inSeconds % 60).toString().padLeft(2, '0')}",
        style: GoogleFonts.poppins(
          color: Colors.white54,
        ),
      ),
    ],
  ),

const SizedBox(height: 30),                Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [

      IconButton(
        onPressed: () {},
        icon: const Icon(
          Icons.skip_previous_rounded,
          color: Colors.white,
          size: 42,
        ),
      ),

      Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: Color(0xff8B5CF6),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: () async {
            if (isPlaying) {
              await audioService.pause();

              setState(() {
                isPlaying = false;
              });
            } else {
              await audioService.resume();

              setState(() {
                isPlaying = true;
              });
            }
          },
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
        onPressed: () {},
        icon: const Icon(
          Icons.skip_next_rounded,
          color: Colors.white,
          size: 42,
        ),
      ),
    ],
  ),

  const SizedBox(height: 35),

  Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: const [

      Icon(
        Icons.shuffle_rounded,
        color: Colors.white54,
        size: 28,
      ),

      Icon(
        Icons.favorite_border_rounded,
        color: Colors.white54,
        size: 28,
      ),

      Icon(
        Icons.repeat_rounded,
        color: Colors.white54,
        size: 28,
      ),
    ],
  ),

  const SizedBox(height: 30),
],
),
),
),
),
);
}
}