import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(MaterialApp(
    home: PaymentScreen(),
  ));
}

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late String accessToken;
  late String notificationId;
  bool isLoading = false;

  // Initialize payment
  Future<void> _initializePayment() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Step 1: Get Access Token
      accessToken = await getAccessToken(
        'n8LiE9L+BnruoZ/u9eT0nxg6sUZHPs4z', // PesaPal Consumer Key
        '1Xo1Qqa8Z4EcYCSj41g+6uJJlKA=', // PesaPal Consumer Secret
      );

      // Step 2: Register IPN
      notificationId = await registerIPN(accessToken, 'https://eonnnt0f46is1hn.m.pipedream.net');

      // Step 3: Prepare Payment Details
      final paymentDetails = {
        'id': 'order123',  // Your unique merchant order reference (max 50 characters)
        'currency': 'UGX',  // Currency code (ISO 4217 format)
        'amount': 1000.0,  // Amount to be processed (float)
        'description': 'Test Order',  // Order description (max 100 characters)
        'redirect_mode': 'TOP_WINDOW',  // Optional: defines where the callback URL will be loaded
        'callback_url': 'https://yourwebsite.com/callback',  // URL to redirect after successful payment
        'cancellation_url': 'https://yourwebsite.com/cancel',  // Optional: cancellation URL
        'notification_id': notificationId,  // Notification ID from IPN registration
        'billing_address': {
          'phone_number': '256740450812',  // Customer phone number
          'email_address': 'kawalyaumar500@gmail.com',  // Customer email address
          'country_code': 'US',  // Country code (ISO 3166-1)
          'first_name': 'John',  // Customer first name
          'middle_name': 'Doe',  // Customer middle name (optional)
          'last_name': 'Smith',  // Customer last name
          'line_1': '123 Main Street',  // Street address line 1
          'line_2': '',  // Street address line 2 (optional)
          'city': 'New York',  // City
          'state': 'NY',  // State
          'postal_code': '10001',  // Postal code (must be valid)
          'zip_code': '10001',  // Zip code (if needed)
        },
      };

      // Step 4: Create Payment Order
      final paymentUrl = await createPaymentOrder(accessToken, paymentDetails);

      // Step 5: Redirect to Payment Page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebView(paymentUrl: paymentUrl),
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pesapal Payment')),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _initializePayment,
                child: Text('Start Payment'),
              ),
      ),
    );
  }
}

// Fetch access token
Future<String> getAccessToken(String consumerKey, String consumerSecret) async {
  final url = 'https://pay.pesapal.com/v3/api/Auth/RequestToken';
  try {
    final requestBody = json.encode({
      'consumer_key': consumerKey,
      'consumer_secret': consumerSecret,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: requestBody,
    );

    print("Access Token Response: ${response.body}");

    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      if (responseJson.containsKey('token')) {
        return responseJson['token'];
      } else {
        throw Exception('Token not found in the response');
      }
    } else {
      throw Exception(
          'Failed to get access token: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    throw Exception('Error getting access token: $e');
  }
}

// Register IPN
Future<String> registerIPN(String accessToken, String callbackUrl) async {
  final url = 'https://pay.pesapal.com/v3/api/URLSetup/RegisterIPN';
  try {
    final requestBody = json.encode({
      'ipn_notification_type': 'GET',
      'url': callbackUrl,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: requestBody,
    );

    print("Register IPN Response: ${response.body}");

    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      if (responseJson.containsKey('ipn_id')) {
        return responseJson['ipn_id'];  // Return the IPN ID
      } else {
        throw Exception('IPN ID not found in the response');
      }
    } else {
      throw Exception(
          'Failed to register IPN: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    throw Exception('Error registering IPN: $e');
  }
}

// Create payment order
Future<String> createPaymentOrder(
    String accessToken, Map<String, dynamic> paymentDetails) async {
  final url = 'https://pay.pesapal.com/v3/api/Transactions/SubmitOrderRequest';
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(paymentDetails),
    );

    print("Create Order Response: ${response.body}");

    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      if (responseJson.containsKey('redirect_url')) {
        return responseJson['redirect_url'];
      } else {
        throw Exception('Redirect URL not found in the response: ${response.body}');
      }
    } else {
      throw Exception(
          'Failed to create payment order: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    throw Exception('Error creating payment order: $e');
  }
}

// Payment webview
class PaymentWebView extends StatelessWidget {
  final String paymentUrl;

  PaymentWebView({required this.paymentUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesapal Payment'),
      ),
      body: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(paymentUrl)),
      ),
    );
  }
}
