import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this for launching URLs
import 'firebase_options.dart'; // Ensure Firebase options are configured
import 'views/home.dart'; // Import HomePage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Mobile Ads SDK
  MobileAds.instance.initialize(); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App with Ads',
      debugShowCheckedModeBanner: false, // Disable the debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(),
      ),
      home: const UpdateCheckPage(),
    );
  }
}

class UpdateCheckPage extends StatefulWidget {
  const UpdateCheckPage({Key? key}) : super(key: key);

  @override
  _UpdateCheckPageState createState() => _UpdateCheckPageState();
}

class _UpdateCheckPageState extends State<UpdateCheckPage> {
  String _currentVersion = '';
  String _latestVersion = '';
  bool _isLoading = true;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  // Function to get the current version of the app
  Future<void> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _currentVersion = packageInfo.version;
    });
  }

  // Function to get the latest version from Firestore
  Future<void> _getLatestVersionFromFirestore() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('app_version').doc('latest_version').get();
      if (snapshot.exists) {
        setState(() {
          _latestVersion = snapshot['version'];
        });
      } else {
        setState(() {
          _latestVersion = 'Unknown'; // In case the document doesn't exist
        });
      }
    } catch (e) {
      print("Error fetching latest version: $e");
      setState(() {
        _latestVersion = 'Error';
      });
    }
    // Once both versions are fetched, stop loading
    setState(() {
      _isLoading = false;
    });
  }

  // Function to load the banner ad
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-8354235211065834/4920661324',  // Replace with your own Ad Unit ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Failed to load banner ad: ${error.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    _getLatestVersionFromFirestore();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Widget _buildBannerAd() {
    if (_isBannerAdReady) {
      return Container(
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
      );
    } else {
      return const SizedBox();
    }
  }

  // Function to open Play Store link for update
  Future<void> _openPlayStore() async {
    const url = 'https://play.google.com/store/apps/details?id=com.eduflix.ug';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not open the Play Store';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildBannerAd(),  // Display the banner ad at the top
          Expanded(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator() // Show loading while checking versions
                  : _currentVersion != _latestVersion
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.update, color: Colors.blue, size: 50),
                            const SizedBox(height: 20),
                            Text(
                              'A new version is available!',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Current version: $_currentVersion\n'
                              'Latest version: $_latestVersion',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _openPlayStore, // Open Play Store for update
                              child: const Text('Update Now'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 50),
                            const SizedBox(height: 20),
                            Text(
                              'Your app is up to date!',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Current version: $_currentVersion',
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to the HomePage if up to date
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HomePage()),
                                );
                              },
                              child: const Text('Go to Home'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
