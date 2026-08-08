import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/features/search/search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      "Feel Good",
      "Relax",
      "Romance",
      "Workout",
      "Focus",
      "Party",
    ];

    final recentlyPlayed = [
      {
        "title": "Blinding Lights",
        "artist": "The Weeknd",
        "icon": Icons.nightlife_rounded,
      },
      {
        "title": "Starboy",
        "artist": "The Weeknd",
        "icon": Icons.album_rounded,
      },
      {
        "title": "Die For You",
        "artist": "The Weeknd",
        "icon": Icons.favorite_rounded,
      },
      {
        "title": "Save Your Tears",
        "artist": "The Weeknd",
        "icon": Icons.water_drop_rounded,
      },
      {
        "title": "After Hours",
        "artist": "The Weeknd",
        "icon": Icons.music_note_rounded,
      },
    ];

    final madeForYou = [
      {
        "title": "Midnight Vibes",
        "subtitle": "Late night essentials",
        "icon": Icons.nightlight_round,
      },
      {
        "title": "Chill Hits",
        "subtitle": "Relax and unwind",
        "icon": Icons.spa_rounded,
      },
      {
        "title": "Romantic",
        "subtitle": "Songs for your mood",
        "icon": Icons.favorite_rounded,
      },
      {
        "title": "Workout",
        "subtitle": "Power up your day",
        "icon": Icons.fitness_center_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xff070B0C),

      // =========================================================
      // BOTTOM NAVIGATION
      // =========================================================

      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          height: 68,

          decoration: BoxDecoration(
            color: const Color(0xff111718),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white10,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),

          child: Row(
            children: [
              Expanded(
                child: _bottomItem(
                  icon: Icons.home_rounded,
                  label: "Home",
                  active: true,
                  onTap: () {},
                ),
              ),

              Expanded(
                child: _bottomItem(
                  icon: Icons.library_music_rounded,
                  label: "Library",
                  active: false,
                  onTap: () {},
                ),
              ),

              Expanded(
                child: _bottomItem(
                  icon: Icons.search_rounded,
                  label: "Search",
                  active: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const SearchScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // =========================================================
      // BODY
      // =========================================================

      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            top: 14,
            bottom: 18,
          ),

          children: [
            // =====================================================
            // HEADER
            // =====================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),

              child: Row(
                children: [
                  // LOGO
                  Container(
                    width: 46,
                    height: 46,

                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xffA78BFA),
                          Color(0xff6D28D9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),

                      borderRadius:
                      BorderRadius.circular(15),

                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff8B5CF6)
                              .withOpacity(0.25),
                          blurRadius: 15,
                        ),
                      ],
                    ),

                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // RYVO
                  Text(
                    "RYVO",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const Spacer(),

                  // HISTORY
                  _headerIcon(
                    Icons.history_rounded,
                        () {},
                  ),

                  const SizedBox(width: 4),

                  // SETTINGS
                  _headerIcon(
                    Icons.settings_outlined,
                        () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =====================================================
            // GREETING
            // =====================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Text(
                    "Good evening",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    "What do you want to hear?",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =====================================================
            // SEARCH BAR
            // =====================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),

              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const SearchScreen(),
                    ),
                  );
                },

                child: Container(
                  height: 56,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xff111718),
                    borderRadius:
                    BorderRadius.circular(18),

                    border: Border.all(
                      color: Colors.white10,
                    ),
                  ),

                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Colors.white54,
                        size: 24,
                      ),

                      const SizedBox(width: 12),

                      Text(
                        "Search songs, artists...",
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),

                      const Spacer(),

                      const Icon(
                        Icons.mic_none_rounded,
                        color: Colors.white38,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // =====================================================
            // CATEGORY CHIPS
            // =====================================================

            SizedBox(
              height: 42,

              child: ListView.builder(
                scrollDirection: Axis.horizontal,

                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                itemCount: categories.length,

                itemBuilder: (context, index) {
                  final selected = index == 0;

                  return Container(
                    margin: const EdgeInsets.only(
                      right: 10,
                    ),

                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),

                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xff8B5CF6)
                          : const Color(0xff111718),

                      borderRadius:
                      BorderRadius.circular(15),

                      border: Border.all(
                        color: selected
                            ? const Color(0xff8B5CF6)
                            : Colors.white10,
                      ),
                    ),

                    alignment: Alignment.center,

                    child: Text(
                      categories[index],
                      style: GoogleFonts.poppins(
                        color: selected
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 26),

            // =====================================================
            // FEATURED
            // =====================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),

              child: Row(
                children: [
                  Text(
                    "Made for you",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    "See all",
                    style: GoogleFonts.poppins(
                      color: const Color(0xffA78BFA),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // =====================================================
            // FEATURED HORIZONTAL CARDS
            // =====================================================

            SizedBox(
              height: 255,

              child: ListView.builder(
                scrollDirection: Axis.horizontal,

                physics:
                const BouncingScrollPhysics(),

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                itemCount: madeForYou.length,

                itemBuilder: (context, index) {
                  final item =
                  madeForYou[index];

                  return Container(
                    width: 205,

                    margin: const EdgeInsets.only(
                      right: 14,
                    ),

                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(24),

                      gradient: LinearGradient(
                        colors: [
                          _cardColor(index),
                          const Color(0xff111718),
                        ],

                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),

                      border: Border.all(
                        color: Colors.white10,
                      ),
                    ),

                    clipBehavior: Clip.antiAlias,

                    child: Stack(
                      children: [
                        // BACKGROUND ICON

                        Positioned(
                          right: -18,
                          top: -18,

                          child: Icon(
                            item["icon"]
                            as IconData,
                            size: 150,

                            color: Colors.white
                                .withOpacity(0.06),
                          ),
                        ),

                        Padding(
                          padding:
                          const EdgeInsets.all(
                            18,
                          ),

                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                            children: [
                              Container(
                                width: 48,
                                height: 48,

                                decoration:
                                BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(
                                    0.10,
                                  ),
                                  shape:
                                  BoxShape.circle,
                                ),

                                child: Icon(
                                  item["icon"]
                                  as IconData,
                                  color: Colors.white,
                                  size: 23,
                                ),
                              ),

                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                                children: [
                                  Text(
                                    item["title"]
                                    as String,

                                    style:
                                    GoogleFonts
                                        .poppins(
                                      color:
                                      Colors.white,
                                      fontSize: 19,
                                      fontWeight:
                                      FontWeight.w700,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 3,
                                  ),

                                  Text(
                                    item["subtitle"]
                                    as String,

                                    style:
                                    GoogleFonts
                                        .poppins(
                                      color:
                                      Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 12,
                                  ),

                                  Container(
                                    width: 42,
                                    height: 42,

                                    decoration:
                                    const BoxDecoration(
                                      color:
                                      Colors.white,
                                      shape:
                                      BoxShape.circle,
                                    ),

                                    child: const Icon(
                                      Icons
                                          .play_arrow_rounded,
                                      color:
                                      Colors.black,
                                      size: 25,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // =====================================================
            // KEEP LISTENING
            // =====================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),

              child: Row(
                children: [
                  Text(
                    "Keep listening",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    "See all",
                    style: GoogleFonts.poppins(
                      color: const Color(0xffA78BFA),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // =====================================================
            // RECENTLY PLAYED
            // =====================================================

            SizedBox(
              height: 225,

              child: ListView.builder(
                scrollDirection: Axis.horizontal,

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                itemCount:
                recentlyPlayed.length,

                itemBuilder: (context, index) {
                  final song =
                  recentlyPlayed[index];

                  return Container(
                    width: 165,

                    margin: const EdgeInsets.only(
                      right: 14,
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        // ALBUM
                        Expanded(
                          child: Container(
                            width: double.infinity,

                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius
                                  .circular(20),

                              gradient:
                              LinearGradient(
                                colors: [
                                  _albumColor(index),
                                  const Color(
                                      0xff151A1B),
                                ],

                                begin:
                                Alignment.topLeft,

                                end: Alignment
                                    .bottomRight,
                              ),

                              border: Border.all(
                                color: Colors.white10,
                              ),
                            ),

                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    song["icon"]
                                    as IconData,

                                    size: 60,

                                    color: Colors.white
                                        .withOpacity(
                                      0.80,
                                    ),
                                  ),
                                ),

                                Positioned(
                                  right: 10,
                                  bottom: 10,

                                  child: Container(
                                    width: 38,
                                    height: 38,

                                    decoration:
                                    const BoxDecoration(
                                      color:
                                      Colors.white,
                                      shape:
                                      BoxShape.circle,
                                    ),

                                    child:
                                    const Icon(
                                      Icons
                                          .play_arrow_rounded,
                                      color:
                                      Colors.black,
                                      size: 23,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 9),

                        Text(
                          song["title"]
                          as String,

                          maxLines: 1,

                          overflow:
                          TextOverflow.ellipsis,

                          style:
                          GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          song["artist"]
                          as String,

                          maxLines: 1,

                          overflow:
                          TextOverflow.ellipsis,

                          style:
                          GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // =====================================================
            // QUICK MOODS
            // =====================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),

              child: Text(
                "Moods & moments",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),

              child: GridView.builder(
                shrinkWrap: true,

                physics:
                const NeverScrollableScrollPhysics(),

                itemCount: 6,

                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,

                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,

                  childAspectRatio: 2.6,
                ),

                itemBuilder: (context, index) {
                  final moods = [
                    "Chill",
                    "Commute",
                    "Energize",
                    "Focus",
                    "Gaming",
                    "Party",
                  ];

                  return Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),

                    alignment: Alignment.centerLeft,

                    decoration: BoxDecoration(
                      color:
                      const Color(0xff111718),

                      borderRadius:
                      BorderRadius.circular(16),

                      border: Border.all(
                        color: Colors.white10,
                      ),
                    ),

                    child: Text(
                      moods[index],

                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER ICON
  // ============================================================

  Widget _headerIcon(
      IconData icon,
      VoidCallback onTap,
      ) {
    return IconButton(
      onPressed: onTap,

      icon: Icon(
        icon,
        color: Colors.white60,
        size: 23,
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV ITEM
  // ============================================================

  Widget _bottomItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 200),

        margin: const EdgeInsets.all(6),

        decoration: BoxDecoration(
          color: active
              ? const Color(0xff8B5CF6)
              .withOpacity(0.18)
              : Colors.transparent,

          borderRadius:
          BorderRadius.circular(26),
        ),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            Icon(
              icon,

              color: active
                  ? const Color(0xffA78BFA)
                  : Colors.white54,

              size: 22,
            ),

            const SizedBox(height: 2),

            Text(
              label,

              style: GoogleFonts.poppins(
                color: active
                    ? Colors.white
                    : Colors.white54,

                fontSize: 10,

                fontWeight: active
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD COLORS
  // ============================================================

  Color _cardColor(int index) {
    const colors = [
      Color(0xff30205C),
      Color(0xff163B3A),
      Color(0xff42213B),
      Color(0xff202D4A),
    ];

    return colors[index % colors.length];
  }

  Color _albumColor(int index) {
    const colors = [
      Color(0xff35236A),
      Color(0xff173E45),
      Color(0xff552642),
      Color(0xff253A65),
      Color(0xff493B20),
    ];

    return colors[index % colors.length];
  }
}