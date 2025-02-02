import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'notesViewPage.dart';

class SeriesDetailsPage extends StatefulWidget {
  final String seriesId; // Pass series docId
  final Map<String, dynamic> seriesData; // Series details data

  const SeriesDetailsPage({
    required this.seriesId,
    required this.seriesData,
    Key? key,
  }) : super(key: key);

  @override
  State<SeriesDetailsPage> createState() => _SeriesDetailsPageState();
}

class _SeriesDetailsPageState extends State<SeriesDetailsPage> {
  List<DocumentSnapshot> _notes = [];
  bool _isLoading = true;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  // Fetch notes filtered by seriesId (using series docId)
  Future<void> _fetchNotes() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .where('seriesId', isEqualTo: widget.seriesId)
          .get();

      setState(() {
        _notes = querySnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching notes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load Banner Ad
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-8354235211065834/9812044905', // Test ID for banner ads
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();
  }

  // Load Interstitial Ad
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-8354235211065834/2518866487', // Test ID for interstitial ads
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => print('Interstitial Ad Failed to Load: $error'),
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 241, 240, 243), Color.fromARGB(255, 235, 235, 235)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Banner
                _buildSeriesHeader(),

                // Notes Section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Available Notes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 46, 32, 231),
                    ),
                  ),
                ),
                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    : _notes.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No notes available.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _notes.length,
                            itemBuilder: (context, index) {
                              Map<String, dynamic> noteData =
                                  _notes[index].data() as Map<String, dynamic>;
                              String noteId = _notes[index].id; // Get the document ID
                              return _buildNoteCard(noteData, noteId);
                            },
                          ),

                // Display Banner Ad
                if (_bannerAd != null)
                  Container(
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Series Header Section
  Widget _buildSeriesHeader() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Text(
              widget.seriesData['seriesName'] ?? 'Unknown Series',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.seriesData['description'] ?? 'No description available.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // Note Card Widget
  Widget _buildNoteCard(Map<String, dynamic> noteData, String noteId) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple[100],
          child: Icon(Icons.note, color: Colors.deepPurple[600]),
        ),
        title: Text(
          noteData['fileName'] ?? 'Unknown Note',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Size: ${noteData['fileSize'] ?? 'N/A'}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: Icon(Icons.download_rounded, color: Colors.deepPurple[600]),
          onPressed: () {
            // Navigate to NotesViewPage with the noteId
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotesViewPage(
                  noteId: noteId, // Pass the noteId to NotesViewPage
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
