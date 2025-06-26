import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey.shade500,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.content_cut),
          label: 'Chỉnh sửa',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.view_column), label: 'Mẫu'),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_open),
          label: 'Thư viện',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tôi'),
      ],
    );
  }
}
