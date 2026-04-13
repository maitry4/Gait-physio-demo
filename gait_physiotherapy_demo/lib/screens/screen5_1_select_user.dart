import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/screens/screen6_1_1_session_list.dart';

enum SelectUserMode { newSession, viewSession }

class Screen51SelectUser extends StatefulWidget {
  final SelectUserMode mode;
  const Screen51SelectUser({super.key, required this.mode});

  @override
  State<Screen51SelectUser> createState() => _Screen51SelectUserState();
}

class _Screen51SelectUserState extends State<Screen51SelectUser> {
  String _search = '';
  int? _selectedIndex;

  final List<Map<String, dynamic>> _users = [
    {'name': 'User 1', 'id': 'PT-001', 'age': 34, 'sessions': 8, 'initials': 'U1'},
    {'name': 'Abc Usr', 'id': 'PT-002', 'age': 52, 'sessions': 3, 'initials': 'AU'},
    {'name': 'Usr5', 'id': 'PT-003', 'age': 28, 'sessions': 12, 'initials': 'U5'},
    {'name': 'John Doe', 'id': 'PT-004', 'age': 45, 'sessions': 5, 'initials': 'JD'},
    {'name': 'Sara Khan', 'id': 'PT-005', 'age': 61, 'sessions': 2, 'initials': 'SK'},
    {'name': 'Raj Mehta', 'id': 'PT-006', 'age': 38, 'sessions': 7, 'initials': 'RM'},
  ];

  List<Map<String, dynamic>> get _filtered => _users
      .where((u) =>
          u['name'].toString().toLowerCase().contains(_search.toLowerCase()) ||
          u['id'].toString().toLowerCase().contains(_search.toLowerCase()))
      .toList();

  final List<Color> _avatarColors = [
    const Color(0xFFFF4E6A),
    const Color(0xFF6C63FF),
    const Color(0xFF00C48C),
    const Color(0xFFFFBF00),
    const Color(0xFF00B4D8),
    const Color(0xFFFF6B35),
  ];

  @override
  Widget build(BuildContext context) {
    final isView = widget.mode == SelectUserMode.viewSession;
    final accentColor = isView ? const Color(0xFF6C63FF) : const Color(0xFFFF4E6A);

    return Scaffold(
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1D2E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      isView ? 'Select a User' : 'Select an Existing User',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 24,
                        fontWeight: FontWeight.w700, letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isView
                          ? 'Choose a patient to view their session history'
                          : 'Pick a patient to record a new session',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45), fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search by name or ID...',
                          hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3), fontSize: 14),
                          prefixIcon: Icon(Icons.search,
                              color: Colors.white.withOpacity(0.4), size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // ── User list ────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_filtered.length} patients registered',
                      style: TextStyle(
                          color: Colors.black.withOpacity(0.4), fontSize: 13)),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = _filtered[index];
                        final isSelected = _selectedIndex == index;
                        final avatarColor =
                            _avatarColors[index % _avatarColors.length];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedIndex = index);
                            if (isView) {
                              Future.delayed(
                                  const Duration(milliseconds: 200), () {
                                Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => Screen611SessionList(user: user),
  ),
);
                              }
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1A1D2E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? accentColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10, offset: const Offset(0, 3),
                              )],
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: avatarColor
                                        .withOpacity(isSelected ? 0.25 : 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(user['initials'],
                                        style: TextStyle(
                                          color: isSelected
                                              ? avatarColor
                                              : avatarColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        )),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user['name'],
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF1A1D2E),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          )),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(user['id'],
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                        .withOpacity(0.45)
                                                    : Colors.black
                                                        .withOpacity(0.35),
                                                fontSize: 12,
                                              )),
                                          Text('  ·  Age ${user['age']}',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                        .withOpacity(0.35)
                                                    : Colors.black
                                                        .withOpacity(0.25),
                                                fontSize: 12,
                                              )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Sessions badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: accentColor
                                        .withOpacity(isSelected ? 0.2 : 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('${user['sessions']} sessions',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ),
                              ],
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

          // ── Proceed button (new session mode) ────────────────────────
          if (!isView)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
              child: AnimatedOpacity(
                opacity: _selectedIndex != null ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 250),
                child: GestureDetector(
                  onTap: _selectedIndex != null
                      ? () {
                          // TODO: navigate to session recording screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Starting session for ${_filtered[_selectedIndex!]['name']}'),
                              backgroundColor: const Color(0xFFFF4E6A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4E6A),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFFFF4E6A).withOpacity(0.35),
                        blurRadius: 18, offset: const Offset(0, 7),
                      )],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text('Start Session',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}