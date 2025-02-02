/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {https} = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const axios = require("axios");
const cors = require("cors")({origin: true});

// Constants
const BASE_URL = {
  demo: "https://cybqa.pesapal.com/pesapalv3",
  live: "https://pay.pesapal.com/v3",
};

// Replace these with your consumer key and secret
const CONSUMER_KEY = "n8LiE9L+BnruoZ/u9eT0nxg6sUZHPs4z";
const CONSUMER_SECRET = "1Xo1Qqa8Z4EcYCSj41g+6uJJlKA=";
const API_ENV = "live"; // or "demo"

const API_URL = BASE_URL[API_ENV];

/**
 * Helper function to fetch an access token from Pesapal API.
 * @return {Promise<string>} The access token.
 */
async function getAccessToken() {
  const url = `${API_URL}/api/Auth/RequestToken`;
  const payload = {
    consumer_key: CONSUMER_KEY,
    consumer_secret: CONSUMER_SECRET,
  };
  const headers = {
    "Content-Type": "application/json",
    Accept: "text/plain",
  };

  try {
    const response = await axios.post(url, payload, {headers});
    return response.data.token;
  } catch (error) {
    logger.error("Error fetching access token:", error.message);
    throw error;
  }
}

/**
 * Firebase Function to Get Access Token
 */
exports.getAccessToken = https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      const token = await getAccessToken();
      res.status(200).json({token});
    } catch (error) {
      res.status(500).json({error: "Unable to fetch access token"});
    }
  });
});

/**
 * Firebase Function to Get Transaction Status
 */
exports.getTransactionStatus = https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    const {orderTrackingId} = req.query;

    if (!orderTrackingId) {
      res.status(400).json({error: "Missing orderTrackingId"});
      return;
    }

    try {
      const accessToken = await getAccessToken();
      const url = `${API_URL}/api/Transactions/GetTransactionStatus?orderTrackingId=${orderTrackingId}`;
      const headers = {
        "Content-Type": "application/json",
        Accept: "text/plain",
        Authorization: `Bearer ${accessToken}`,
      };

      const response = await axios.get(url, {headers});
      res.status(200).json(response.data);
    } catch (error) {
      logger.error("Error fetching transaction status:", error.message);
      res.status(500).json({error: "Unable to fetch transaction status"});
    }
  });
});
