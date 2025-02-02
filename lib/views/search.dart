import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'customSearch.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Controllers for text fields (if necessary)
  final TextEditingController _subjectController = TextEditingController();
  
  // Variables for dropdown selections
  String? _selectedClass;
  String? _selectedSubject;
  String? _selectedType;

  // Lists to hold dropdown data
  List<String> _classes = [];
  List<String> _subjects = [];
  List<String> _types = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();  // Load data for dropdowns
  }

  // Fetch the dropdown data from Firestore
  Future<void> _loadDropdownData() async {
    try {
      // Fetch classes from the 'classes' collection
      QuerySnapshot classSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .get();
      setState(() {
        _classes = classSnapshot.docs
            .map((doc) => doc['class'] as String)
            .toList();
      });

      // Fetch subjects from the 'subjects' collection
      QuerySnapshot subjectSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .get();
      setState(() {
        _subjects = subjectSnapshot.docs
            .map((doc) => doc['subject'] as String)
            .toList();
      });

      // Fetch types from the 'type' collection
      QuerySnapshot typeSnapshot = await FirebaseFirestore.instance
          .collection('docTypes')
          .get();
      setState(() {
        _types = typeSnapshot.docs
            .map((doc) => doc['docTypeName'] as String)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading dropdown data: $e');
    }
  }

  // Method to execute search based on selected criteria
  Future<void> _search() async {
    // Use the selected values as they are, without changing case
    String classQuery = _selectedClass ?? '';
    String subjectQuery = _selectedSubject ?? '';
    String typeQuery = _selectedType ?? '';

    // Perform a Firestore query with selected filters
    Query query = FirebaseFirestore.instance.collection('notes');

    // Apply filters based on the selected values
    if (classQuery.isNotEmpty) {
      query = query.where('class', isEqualTo: classQuery);
    }
    if (subjectQuery.isNotEmpty) {
      query = query.where('subject', isEqualTo: subjectQuery);
    }
    if (typeQuery.isNotEmpty) {
      query = query.where('docType', isEqualTo: typeQuery);
    }

    // Get the query snapshot (a Future<QuerySnapshot>)
    Future<QuerySnapshot> querySnapshot = query.get();

    // Navigate to CustomSearchView with the query result
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomSearchView(
          queri: querySnapshot, // Pass the Future<QuerySnapshot> here
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Notes'),
        backgroundColor: Colors.blueAccent,
        elevation: 5,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Implement search logic if needed in the AppBar
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Class Dropdown with custom decoration
                    _buildCustomDropdown(
                      hint: 'Select Class',
                      value: _selectedClass,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedClass = newValue;
                        });
                      },
                      items: _classes,
                    ),
                    const SizedBox(height: 16.0),

                    // Subject Dropdown with custom decoration
                    _buildCustomDropdown(
                      hint: 'Select Subject',
                      value: _selectedSubject,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedSubject = newValue;
                        });
                      },
                      items: _subjects,
                    ),
                    const SizedBox(height: 16.0),

                    // Type Dropdown with custom decoration
                    _buildCustomDropdown(
                      hint: 'Select Type',
                      value: _selectedType,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedType = newValue;
                        });
                      },
                      items: _types,
                    ),
                    const SizedBox(height: 32.0),

                    // Search Button with gradient effect
                    ElevatedButton(
                      onPressed: _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Custom widget to build dropdown with decoration
  Widget _buildCustomDropdown({
    required String hint,
    required String? value,
    required Function(String?) onChanged,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButton<String>(
        hint: Text(hint),
        value: value,
        onChanged: onChanged,
        isExpanded: true,
        underline: SizedBox(),
        items: items.map<DropdownMenuItem<String>>((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: TextStyle(fontSize: 16)),
          );
        }).toList(),
      ),
    );
  }
}
