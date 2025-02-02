import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notesViewPage.dart';  // Import the NotesViewPage

class NotesSearchView extends StatefulWidget {
  @override
  _NotesSearchViewState createState() => _NotesSearchViewState();
}

class _NotesSearchViewState extends State<NotesSearchView> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchNotes(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .get();

      final List<Map<String, dynamic>> allNotes = querySnapshot.docs
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id, // Include document ID for navigation
              })
          .toList();

      setState(() {
        _searchResults = allNotes
            .where((note) =>
                (note['fileName'] as String).toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    } catch (e) {
      print('Error searching notes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Notes'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Input Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by file name',
                labelStyle: TextStyle(fontSize: 16.0, color: Colors.blueGrey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.blueAccent),
                  onPressed: () {
                    _searchController.clear();
                    _searchNotes('');
                  },
                ),
              ),
              onChanged: (value) {
                _searchNotes(value);
              },
            ),
            const SizedBox(height: 16.0),

            // Display Loading Indicator
            if (_isLoading) 
              Center(child: CircularProgressIndicator(color: Colors.blueAccent)),

            // Display Search Results
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        'No results found.',
                        style: TextStyle(fontSize: 16.0, color: Colors.blueGrey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final note = _searchResults[index];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 15,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotesViewPage(
                                      noteId: note['id'],
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              splashColor: Colors.deepPurple[100],
                              highlightColor: Colors.deepPurple[200],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note['fileName'] ?? 'Unnamed Note',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple[800],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    note['description'] ?? 'No description available',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Divider(
                                    color: Colors.grey[300],
                                    thickness: 1.5,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => NotesViewPage(
                                                noteId: note['id'],
                                              ),
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
                                        child: const Text('More Info', style: TextStyle(fontSize: 16, color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
