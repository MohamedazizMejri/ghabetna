import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {

  final Function(int) onMenuSelected;

  const Sidebar({super.key, required this.onMenuSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.green.shade700,
      child: Column(
        children: [

          const SizedBox(height: 40),

          const Text(
            "Admin Panel",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold
            ),
          ),

          const SizedBox(height: 40),

          menuItem("Dashboard", 0),
          menuItem("Users", 1),
          menuItem("Forests", 2),
          menuItem("Assign supervisor", 3),
          menuItem("Partitions", 4),
          menuItem("Assign Agent", 5),
        ],
      ),
    );
  }

  Widget menuItem(String title, int index) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () => onMenuSelected(index),
    );
  }
}