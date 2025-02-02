import 'package:flutter/material.dart';
import 'components/classes.dart';
import 'components/hotdeals.dart';
import 'components/nan.dart';
import 'components/topbar.dart';



class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Topbar(),
            SizedBox(height: 20),
            _buildSectionTitle('Hot Deals', Icons.local_offer, Colors.deepPurple),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(66, 173, 162, 162),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: HotDeals(),
            ), SizedBox(height: 20),
            _buildSectionTitle('Select class', Icons.local_offer, const Color.fromARGB(255, 61, 218, 13)),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(66, 173, 162, 162),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Classes(),
            ),
            SizedBox(height: 20),

            _buildSectionTitle('Recently Uploaded', Icons.access_time, Colors.orange),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6)),
                ],
              ),
              child: Data(),
            ),
            SizedBox(height: 20),
            
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
