import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditUploadedFilesScreen extends StatefulWidget {
  @override
  _EditUploadedFilesScreenState createState() =>
      _EditUploadedFilesScreenState();
}

class _EditUploadedFilesScreenState extends State<EditUploadedFilesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> classOptions = [];
  List<String> subjectOptions = [];
  List<String> docTypeOptions = [];

  String? selectedClass;
  String? selectedSubject;
  String? selectedDocType;

  bool isLoading = false;
  bool hasMoreData = true;
  DocumentSnapshot? lastDocument;
  List<Map<String, dynamic>> files = [];
  int totalFilesCount = 0;
  final ScrollController _scrollController = ScrollController();

  Future<void> fetchUnverifiedFiles({bool loadMore = false}) async {
    if (isLoading || !hasMoreData) return;

    setState(() {
      isLoading = true;
    });

    Query query = _firestore.collection('notes')
      .where('verified', isEqualTo: false)
      .limit(10);

    if (loadMore && lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();

    if (querySnapshot.docs.isEmpty) {
      setState(() {
        hasMoreData = false;
      });
    } else {
      lastDocument = querySnapshot.docs.last;
      files.addAll(querySnapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList());
    }

    setState(() {
      isLoading = false;
    });
  }
Future<void> fetchTotalFilesCount() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('notes')
        .where('verified', isEqualTo: false)
        .get();
    setState(() {
      totalFilesCount = querySnapshot.size;
    });
  }
  Future<void> fetchDropdownOptions() async {
    // Fetch Class options
    QuerySnapshot classSnapshot = await _firestore.collection('classes').get();
    classOptions = classSnapshot.docs
        .map((doc) => doc['class'] as String)
        .toSet()
        .toList();

    // Fetch Subject options
    QuerySnapshot subjectSnapshot = await _firestore.collection('subjects').get();
    subjectOptions = subjectSnapshot.docs
        .map((doc) => doc['subject'] as String)
        .toSet()
        .toList();

    // Fetch DocType options
    QuerySnapshot docTypeSnapshot = await _firestore.collection('docTypes').get();
    docTypeOptions = docTypeSnapshot.docs
        .map((doc) => doc['docTypeName'] as String)
        .toSet()
        .toList();

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fetchDropdownOptions();
    fetchUnverifiedFiles();
    fetchTotalFilesCount();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        fetchUnverifiedFiles(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
Future<void> deleteFile(String docId) async {
    await _firestore.collection('notes').doc(docId).delete();
    files.removeWhere((file) => file['id'] == docId);
    setState(() {
      totalFilesCount--;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File deleted successfully!')),
    );
  }
  Future<void> _showAddDialog(BuildContext context) async {
    final TextEditingController classController = TextEditingController();
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController docTypeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Options'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: classController,
                  decoration: InputDecoration(labelText: 'Class'),
                ),
                SizedBox(height: 10.0),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(labelText: 'Subject'),
                ),
                SizedBox(height: 10.0),
                TextField(
                  controller: docTypeController,
                  decoration: InputDecoration(labelText: 'Document Type'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (classController.text.isNotEmpty) {
                  await _firestore.collection('classes').add({
                    'class': classController.text,
                  });
                }
                if (subjectController.text.isNotEmpty) {
                  await _firestore.collection('subjects').add({
                    'subject': subjectController.text,
                  });
                }
                if (docTypeController.text.isNotEmpty) {
                  await _firestore.collection('docTypes').add({
                    'docTypeName': docTypeController.text,
                  });
                }

                // After adding, refresh the dropdown options
                fetchDropdownOptions();

                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Uploaded Files ($totalFilesCount)'),
      ),
      body: files.isEmpty && isLoading
          ? Center(child: CircularProgressIndicator())
          : files.isEmpty
              ? Center(child: Text('No unverified files available.'))
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16.0),
                  itemCount: files.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == files.length) {
                      return Center(child: CircularProgressIndicator());
                    }

                    Map<String, dynamic> file = files[index];
                    TextEditingController classController =
                        TextEditingController(text: file['class']);
                    TextEditingController subjectController =
                        TextEditingController(text: file['subject']);
                    TextEditingController docTypeController =
                        TextEditingController(text: file['docType']);
                    bool isUpdating = false;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file['fileName'] ?? 'Unknown File',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10.0),
                            Text(
                              'File Path: ${file['filePath']}',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 10.0),
                            Divider(),
                            SizedBox(height: 10.0),
                            // Class Dropdown
                            DropdownButtonFormField<String>(
                              value: classOptions.isNotEmpty && classOptions.contains(file['class'])
                                  ? file['class']
                                  : null,
                              onChanged: (value) {
                                setState(() {
                                  selectedClass = value;
                                });
                              },
                              items: classOptions.map((className) {
                                return DropdownMenuItem(
                                  value: className,
                                  child: Text(className),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                labelText: 'Class',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 10.0),
                            // Subject Dropdown
                            DropdownButtonFormField<String>(
                              value: subjectOptions.isNotEmpty && subjectOptions.contains(file['subject'])
                                  ? file['subject']
                                  : null,
                              onChanged: (value) {
                                setState(() {
                                  selectedSubject = value;
                                });
                              },
                              items: subjectOptions.map((subjectName) {
                                return DropdownMenuItem(
                                  value: subjectName,
                                  child: Text(subjectName),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                labelText: 'Subject',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 10.0),
                            // Document Type Dropdown
                            DropdownButtonFormField<String>(
                              value: docTypeOptions.isNotEmpty && docTypeOptions.contains(file['docType'])
                                  ? file['docType']
                                  : null,
                              onChanged: (value) {
                                setState(() {
                                  selectedDocType = value;
                                });
                              },
                              items: docTypeOptions.map((docTypeName) {
                                return DropdownMenuItem(
                                  value: docTypeName,
                                  child: Text(docTypeName),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                labelText: 'Document Type',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 20.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: isUpdating
                                      ? null
                                      : () async {
                                          await deleteFile(file['id']);
                                        },
                                  icon: Icon(Icons.delete_forever),
                                  label: Text('Delete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    if (selectedClass != null ||
                                        selectedSubject != null ||
                                        selectedDocType != null) {
                                      Map<String, dynamic> updatedData = {
                                        'class': selectedClass ?? file['class'],
                                        'subject': selectedSubject ?? file['subject'],
                                        'docType': selectedDocType ?? file['docType'],
                                      };
                                      await updateFile(file['id'], updatedData);
                                    }
                                    await _firestore
                                        .collection('notes')
                                        .doc(file['id'])
                                        .update({'verified': true});
                                    setState(() {});
                                  },
                                  icon: Icon(Icons.check),
                                  label: Text('Mark Verified'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog(context);
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> updateFile(String docId, Map<String, dynamic> updatedData) async {
    await _firestore.collection('notes').doc(docId).update(updatedData);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File details updated successfully!')),
    );
  }
}
