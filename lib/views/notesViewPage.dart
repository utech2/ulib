import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

class NotesViewPage extends StatefulWidget {
  final String noteId;

  const NotesViewPage({
    required this.noteId,
    Key? key,
  }) : super(key: key);

  @override
  State<NotesViewPage> createState() => _NotesViewPageState();
}

class _NotesViewPageState extends State<NotesViewPage> {
  Map<String, dynamic>? _noteData;
  bool _isLoading = true;

  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _fetchNoteDetails();
    _loadInterstitialAd();
    _loadBannerAd();
  }

  Future<void> _fetchNoteDetails() async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .doc(widget.noteId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          _noteData = docSnapshot.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note not found.')),
        );
      }
    } catch (e) {
      print('Error fetching note details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-8354235211065834/2518866487',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) =>
            print('Interstitial Ad Failed to Load: $error'),
      ),
    );
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-8354235211065834/9812044905',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => print('Banner Ad Loaded'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Banner Ad Failed to Load: $error');
        },
      ),
    )..load();
  }

  Future<void> _downloadNote() async {
    _interstitialAd?.show();

    final url = _noteData?['downloadUrl'];

    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid download URL.')),
      );
      return;
    }

    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open download link.')),
      );
    }
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _noteData == null
              ? const Center(
                  child: Text('Note not found.'),
                )
              : Column(
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color.fromARGB(255, 15, 11, 235), Color.fromARGB(255, 147, 161, 224)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _noteData!['fileName'] ?? 'Untitled Note',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    _buildDetailRow(Icons.book, 'Subject', _noteData!['subject'] ?? 'N/A'),
                                    const Divider(),
                                    _buildDetailRow(Icons.class_, 'Class', _noteData!['level'] ?? 'N/A'),
                                    const Divider(),
                                    _buildDetailRow(Icons.folder, 'File Size', _noteData!['fileSize'] ?? 'N/A'),
                                    const Divider(),
                                    _buildDetailRow(Icons.download, 'Download Count', '${_noteData!['downloadCount'] ?? 0}'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _downloadNote,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: const Icon(Icons.download),
                                label: const Text(
                                  'Download Note',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_bannerAd != null)
                      SizedBox(
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                  ],
                ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$title: $value',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
