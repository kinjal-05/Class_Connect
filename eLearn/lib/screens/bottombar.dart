import 'package:flutter/material.dart';


class BottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isTeacher;

  BottomBar({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.indigo,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: isTeacher ? _buildTeacherItems() : _buildStudentItems(),
        ),
      ),
    );
  }

  // Bottom bar items for teachers
  List<Widget> _buildTeacherItems() {
    return [
      _buildBottomBarItem(
        icon: Icons.home,
        label: 'Home',
        index: 0,
        isActive: selectedIndex == 0,
        onTap: () => onItemSelected(0),
      ),
      _buildBottomBarItem(
        icon: Icons.book,
        label: 'Courses',
        index: 1,
        isActive: selectedIndex == 1,
        onTap: () => onItemSelected(1),
      ),
      _buildBottomBarItem(
        icon: Icons.add_circle_outline_outlined,
        label: 'Add',
        index: 2,
        isActive: selectedIndex == 2,
        onTap: () => onItemSelected(2),
      ),
      _buildBottomBarItem(
        icon: Icons.people_rounded,
        label: 'Students',
        index: 3,
        isActive: selectedIndex == 3,
        onTap: () => onItemSelected(3),
      ),
      _buildBottomBarItem(
        icon: Icons.person,
        label: 'Profile',
        index: 4,
        isActive: selectedIndex == 4,
        onTap: () => onItemSelected(4),
      ),
    ];
  }

  // Bottom bar items for students
  List<Widget> _buildStudentItems() {
    return [
      _buildBottomBarItem(
        icon: Icons.home,
        label: 'Home',
        index: 0,
        isActive: selectedIndex == 0,
        onTap: () => onItemSelected(0),
      ),
      _buildBottomBarItem(
        icon: Icons.search,
        label: 'Search',
        index: 1,
        isActive: selectedIndex == 1,
        onTap: () => onItemSelected(1),
      ),
      _buildBottomBarItem(
        icon: Icons.person,
        label: 'Profile',
        index: 2,
        isActive: selectedIndex == 2,
        onTap: () => onItemSelected(2),
      ),

    ];
  }

  Widget _buildBottomBarItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Flexible(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: isActive ? Colors.white : Colors.white70,
              shadows: isActive
                  ? [
                Shadow(
                  offset: Offset(5, 2),
                  blurRadius: 4.0,
                  color: Colors.black,
                ),
              ]
                  : [],
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                shadows: isActive
                    ? [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 4.0,
                    color: Colors.black,
                  ),
                ]
                    : [],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
