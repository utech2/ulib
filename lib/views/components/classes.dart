import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../viewClass.dart';

class Classes extends StatefulWidget {
  const Classes({super.key});

  @override
  State<Classes> createState() => _ClassesState();
}

class _ClassesState extends State<Classes> {
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 7;
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  List<DocumentSnapshot> _documents = [];

  // Fetch data with pagination
  Future<void> _fetchData() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    Query query = FirebaseFirestore.instance
        .collection('classes')
        .orderBy('class')
        .limit(_pageSize);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();
    List<DocumentSnapshot> documents = querySnapshot.docs;

    setState(() {
      _isLoading = false;
      _hasMore = documents.length == _pageSize;
      if (_hasMore) {
        _lastDocument = documents.last;
      } else {
        _lastDocument = null;
      }
      _documents.addAll(documents);
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _fetchData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal, // Horizontal list
          itemCount: _documents.length + 1,
          itemBuilder: (context, index) {
            if (index == _documents.length) {
              return _isLoading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple[600]!),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            }

            Map<String, dynamic> data = _documents[index].data() as Map<String, dynamic>;
            return AnimatedClassCard(data: data);
          },
        ),
      ),
    );
  }
}

class AnimatedClassCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const AnimatedClassCard({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(16.0),
      width: 160, // Slightly larger card for better content visibility
      height: 180, // Increased height to fit all elements nicely
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), // Rounded corners for modern design
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('Class tapped: ${data['class']}');
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.deepPurple[100],
          highlightColor: Colors.deepPurple[200],
          child: Stack(
            children: [
              // Main content of the class card
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Class Name
                  Text(
                    data['class'] ?? 'No class name',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[800],
                    ),
                  ),
                  const SizedBox(height: 10), // Increased space between elements

                  // Teacher and Students Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        color: Colors.deepPurple[600],
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Level: ${data['level'] ?? 'N/A'}', // Example: Displaying the level
                        style: TextStyle(fontSize: 14, color: Colors.deepPurple[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Divider
                  Divider(
                    color: Colors.grey[300],
                    thickness: 1.0,
                  ),
                  const SizedBox(height: 10),

                  // Action Buttons
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassSearchView(classid: data['class']),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('View Class', style: TextStyle(fontSize: 14, color: Colors.white)),
                  ),
                ],
              ),

              // Banner widget (top left corner)
              Positioned(
                top: 0,
                left: 0,
                child: Banner(
                  message: 'Featured', // Example text for the banner
                  location: BannerLocation.topStart,
                  color: Colors.orange, // Banner color to stand out
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
