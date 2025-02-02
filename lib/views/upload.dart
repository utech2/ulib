import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class MultiFileUploadScreen extends StatefulWidget {
  @override
  _MultiFileUploadScreenState createState() => _MultiFileUploadScreenState();
}

class _MultiFileUploadScreenState extends State<MultiFileUploadScreen> {
  List<UploadItem> uploadItems = [];
  bool isUploading = false;

  // Function to pick and add files to the upload list
  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true, // Ensure bytes are included for web
    );

    if (result != null) {
      setState(() {
        uploadItems = result.files.map((file) {
          return UploadItem(
            file: file,
            fileName: file.name,
            fileSize: '${(file.size / 1024).toStringAsFixed(2)} KB',
            fileExtension: file.name.split('.').last,
            progress: 0.0,
            isUploaded: false,
          );
        }).toList();
      });
    }
  }

  // Function to upload files
  Future<void> uploadFiles() async {
    setState(() {
      isUploading = true;
    });

    for (UploadItem item in uploadItems) {
      try {
        String filePath = 'uploads/${item.fileName}';
        Reference storageRef = FirebaseStorage.instance.ref().child(filePath);

        // Upload file bytes (works on web and other platforms)
        UploadTask uploadTask = storageRef.putData(item.file.bytes!);

        // Track upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          setState(() {
            item.progress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        });

        // Wait for the upload to complete
        TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Save metadata to Firestore
        await FirebaseFirestore.instance.collection('notes').add({
          'class': 'NA',
          'docType': 'NA',
          'downloadCount': 25,
          'downloadUrl': downloadUrl,
          'fileExtension': item.fileExtension,
          'fileName': item.fileName,
          'filePath': filePath,
          'fileSize': item.fileSize,
          'level': 'NA',
          'seriesId': 'NA',
          'subject': 'SCIENCE',
          'verified': false, // Newly added field
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          item.isUploaded = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload ${item.fileName}: $e')),
        );
      }
    }

    setState(() {
      isUploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All files uploaded successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Multiple Files')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isUploading ? null : pickFiles,
            child: Text('Pick Files'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: uploadItems.length,
              itemBuilder: (context, index) {
                UploadItem item = uploadItems[index];
                return ListTile(
                  title: Text(item.fileName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Size: ${item.fileSize}'),
                      LinearProgressIndicator(
                        value: item.progress,
                        backgroundColor: Colors.grey[300],
                        color: item.isUploaded ? Colors.green : Colors.blue,
                      ),
                    ],
                  ),
                  trailing: item.isUploaded
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.upload, color: Colors.grey),
                );
              },
            ),
          ),
          if (isUploading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          if (!isUploading && uploadItems.isNotEmpty)
            ElevatedButton(
              onPressed: uploadFiles,
              child: Text('Upload All Files'),
            ),
        ],
      ),
    );
  }
}

// Model class for upload item
class UploadItem {
  final PlatformFile file; // Updated for compatibility with web
  final String fileName;
  final String fileSize;
  final String fileExtension;
  double progress;
  bool isUploaded;

  UploadItem({
    required this.file,
    required this.fileName,
    required this.fileSize,
    required this.fileExtension,
    this.progress = 0.0,
    this.isUploaded = false,
  });
}
