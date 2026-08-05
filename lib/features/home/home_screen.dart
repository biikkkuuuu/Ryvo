import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/features/search/search_screen.dart';

class HomeScreen extends StatelessWidget {
const HomeScreen({super.key});

@override
Widget build(BuildContext context) {
final songs = [
"Blinding Lights",
"Starboy",
"Die For You",
"Save Your Tears",
"After Hours",
];

return Scaffold(
backgroundColor: Colors.black,

bottomNavigationBar: BottomNavigationBar(
backgroundColor: const Color(0xff111111),
selectedItemColor: const Color(0xff8B5CF6),
unselectedItemColor: Colors.white54,
type: BottomNavigationBarType.fixed,
currentIndex: 0,
items: const [
BottomNavigationBarItem(
icon: Icon(Icons.home_rounded),
label: "Home",
),
BottomNavigationBarItem(
icon: Icon(Icons.search_rounded),
label: "Search",
),
BottomNavigationBarItem(
icon: Icon(Icons.favorite_rounded),
label: "Library",
),
BottomNavigationBarItem(
icon: Icon(Icons.person_rounded),
label: "Profile",
),
],
),

body: SafeArea(
child: ListView(
padding: const EdgeInsets.all(20),
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
"Good Evening 👋",
style: GoogleFonts.poppins(
color: Colors.white60,
fontSize: 16,
),
),
const SizedBox(height: 4),
Text(
"Rana",
style: GoogleFonts.poppins(
color: Colors.white,
fontWeight: FontWeight.bold,
fontSize: 32,
),
),
],
),
const CircleAvatar(
radius: 24,
backgroundColor: Color(0xff8B5CF6),
child: Icon(Icons.person, color: Colors.white),
),
],
),

const SizedBox(height: 30),

InkWell(
borderRadius: BorderRadius.circular(18),
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const SearchScreen(),
),
);
},
child: Container(
height: 58,
decoration: BoxDecoration(
color: const Color(0xff111111),
borderRadius: BorderRadius.circular(18),
),
padding: const EdgeInsets.symmetric(horizontal: 18),
child: const Row(
children: [
Icon(Icons.search, color: Colors.white54),
SizedBox(width: 12),
Text(
"Search songs, artists...",
style: TextStyle(
color: Colors.white38,
fontSize: 16,
),
),
],
),
),
),

const SizedBox(height: 28),

Container(
height: 210,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(24),
gradient: const LinearGradient(
colors: [
Color(0xff8B5CF6),
Color(0xff5B21B6),
],
),
),
child: Padding(
padding: const EdgeInsets.all(22),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
children: [
Text(
"Featured Playlist",
style: GoogleFonts.poppins(
color: Colors.white70,
),
),
Text(
"Midnight\nVibes",
style: GoogleFonts.poppins(
color: Colors.white,
fontWeight: FontWeight.bold,
fontSize: 30,
),
),
SizedBox(
height: 42,
child: ElevatedButton.icon(
onPressed: () {},
icon: const Icon(Icons.play_arrow),
label: const Text("Play Now"),
),
),
],
),
),
),

const SizedBox(height: 30),

Text(
"Recently Played",
style: GoogleFonts.poppins(
color: Colors.white,
fontSize: 22,
fontWeight: FontWeight.w600,
),
),

const SizedBox(height: 18),            SizedBox(
    height: 220,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: songs.length,
      itemBuilder: (context, index) {
        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: const Color(0xff111111),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.album,
                      size: 70,
                      color: Colors.deepPurple.shade300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                songs[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "The Weeknd",
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    ),
  ),

  const SizedBox(height: 30),
],
),
),
);
}
}