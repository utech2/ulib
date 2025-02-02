import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../notesViewPage.dart';

class Data extends StatefulWidget {
  const Data({super.key});

  @override
  State<Data> createState() => _DataState();
}

class _DataState extends State<Data> {
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 10;
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
        .collection('notes')
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

      // Log fetched documents
      documents.forEach((doc) {
        print("Document ID: ${doc.id}");
        print("Document Data: ${doc.data()}");
      });

      // Attach document ID to the data map
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
      body: ListView.builder(
        controller: _scrollController,
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

          // Attach the document ID explicitly
          data['id'] = _documents[index].id;

          return AnimatedClassCard(data: data);
        },
      ),
    );
  }
}

class AnimatedClassCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const AnimatedClassCard({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    // Log the data for debugging
    print("Data received in AnimatedClassCard: ${data}");

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4), // Shadow position
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Implement navigation or interaction
            print('Class tapped: ${data['class']}');
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.deepPurple[100],
          highlightColor: Colors.deepPurple[200],
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // fileName
                Text(
                  data['fileName'] ?? 'No FILES',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple[800],
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  data['fileSize'] ?? 'No size',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: Colors.deepPurple[600],
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${data['subject'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.group_rounded,
                          color: Colors.green[600],
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${data['class']?.toString() ?? '0'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Divider between sections
                Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                ),
                const SizedBox(height: 8),

                // Optional Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotesViewPage(
                              noteId: data['id'], // Pass the Firestore document ID
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('View Class', style: TextStyle(fontSize: 14)),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple[600],
                        side: BorderSide(color: Colors.deepPurple[600]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('More Info', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
