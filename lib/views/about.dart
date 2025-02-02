import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  // Initialize the banner ad
  @override
  void initState() {
    super.initState();
    _initializeAdMob();
  }

  void _initializeAdMob() {
    // Initialize Google Mobile Ads SDK
    MobileAds.instance.initialize();

    // Create a BannerAd
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-8354235211065834/4920661324', 
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('Failed to load banner ad: $error');
        },
      ),
    );

    // Load the banner ad
    _bannerAd.load();
  }

  @override
  void dispose() {
    // Dispose the banner ad when the widget is disposed
    _bannerAd.dispose();
    super.dispose();
  }

  // Method to launch a URL (for WhatsApp or email)
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About Ulib"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the banner ad if it's ready
            if (_isBannerAdReady)
              Container(
                alignment: Alignment.center,
                child: SizedBox(
                  height: 50,
                  child: AdWidget(ad: _bannerAd),
                ),
              ),
            SizedBox(height: 20),

            // Title Section
            Text(
              'Welcome to Ulib',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Ulib is an app designed to help students and educators share educational resources like notes, past exams, and study materials with ease.',
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),

            // About Utech Software Company
            Text(
              'About Utech Software Company',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Utech Software Company is a leading software development company located in Kampala, Uganda. We specialize in creating high-quality, custom software solutions for a wide range of industries, including education, business, and government. With a dedicated team of developers, designers, and innovators, we strive to create impactful applications that solve real-world problems and empower individuals and organizations. Our passion for technology drives us to push boundaries and deliver innovative solutions that help our clients thrive in a rapidly evolving digital world. Founded with a mission to bridge the gap between technology and human potential, Utech focuses on building scalable, secure, and user-friendly applications. We believe in the power of digital transformation and the positive impact it can have on businesses, institutions, and communities. From mobile apps to enterprise-level software, we offer comprehensive services that meet the unique needs of our clients. Our expertise spans various domains, including mobile app development, web development, cloud computing, and IT consulting. We work closely with our clients to understand their vision, goals, and challenges, allowing us to deliver tailored solutions that exceed expectations. At Utech, we value collaboration, innovation, and long-term partnerships that help our clients succeed in the digital age. As a company committed to excellence, we continuously invest in research and development, ensuring that our products are built with the latest technologies and industry best practices. We aim to make technology accessible to everyone, empowering individuals and organizations to unlock their full potential.",
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10),

            // Contact Section
            Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.wechat, color: Colors.green, size: 40),
                  onPressed: () {
                    _launchURL('https://wa.me/+256740450812');
                  },
                ),
                Text(
                  '+256740450812',
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.email, color: Colors.red, size: 40),
                  onPressed: () {
                    _launchURL('mailto:kawalyaumar500@gmail.com');
                  },
                ),
                Text(
                  'kawalyaumar500@gmail.com',
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                ),
              ],
            ),
            SizedBox(height: 40),
            Center(
              child: Text(
                '© 2024 Utech Software Company. All Rights Reserved.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
