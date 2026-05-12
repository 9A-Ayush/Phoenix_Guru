/**
 * Firebase Functions for Phoenix Guru
 * 
 * Deploy with: firebase deploy --only functions
 * 
 * Environment variables (set in functions/.env file):
 * CLOUDINARY_CLOUD_NAME=your_cloud_name
 * CLOUDINARY_API_KEY=your_api_key
 * CLOUDINARY_API_SECRET=your_api_secret
 * CLOUDINARY_UPLOAD_PRESET=your_preset
 */

// Load environment variables from .env file
require('dotenv').config();

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();

const DAILY_LIMIT_BYTES = 500 * 1024 * 1024; // 500 MB
const TOTAL_LIMIT_BYTES = 25 * 1024 * 1024 * 1024; // 25 GB

// Get Cloudinary config from environment variables
const getCloudinaryConfig = () => {
  return {
    cloudName: process.env.CLOUDINARY_CLOUD_NAME,
    apiKey: process.env.CLOUDINARY_API_KEY,
    apiSecret: process.env.CLOUDINARY_API_SECRET,
    uploadPreset: process.env.CLOUDINARY_UPLOAD_PRESET,
  };
};

/**
 * Generate signed Cloudinary upload parameters
 * 
 * Security:
 * - Validates Firebase Auth token
 * - Checks daily upload limit (500 MB/day)
 * - Checks total storage quota (25 GB)
 * - Returns signed upload URL (prevents unauthorized uploads)
 */
exports.getCloudinarySignature = functions.https.onRequest(async (req, res) => {
  // CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    // 1. Verify Firebase Auth token
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: { message: 'Unauthorized' } });
      return;
    }

    const token = authHeader.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    const teacherId = decodedToken.uid;

    // 2. Get request body
    const { fileBytes } = req.body;
    if (!fileBytes || typeof fileBytes !== 'number') {
      res.status(400).json({ error: { message: 'Invalid fileBytes' } });
      return;
    }

    // 3. Check daily limit
    const today = new Date().toISOString().substring(0, 10);
    const trackerRef = admin.firestore()
      .collection('users').doc(teacherId)
      .collection('uploadTracker').doc('daily');

    const trackerSnap = await trackerRef.get();
    const trackerData = trackerSnap.data();

    let usedToday = 0;
    if (trackerData && trackerData.date === today) {
      usedToday = trackerData.bytesUsed || 0;
    }

    if (usedToday + fileBytes > DAILY_LIMIT_BYTES) {
      const remainingMB = Math.floor((DAILY_LIMIT_BYTES - usedToday) / (1024 * 1024));
      res.status(429).json({
        error: {
          message: `Daily upload limit reached. ${remainingMB} MB remaining today.`
        }
      });
      return;
    }

    // 4. Check total storage quota
    const classesSnap = await admin.firestore()
      .collection('classes')
      .where('teacherId', '==', teacherId)
      .get();

    let totalUsed = 0;
    for (const classDoc of classesSnap.docs) {
      const materialsSnap = await admin.firestore()
        .collection('classes').doc(classDoc.id)
        .collection('materials')
        .get();

      for (const materialDoc of materialsSnap.docs) {
        totalUsed += materialDoc.data().sizeBytes || 0;
      }
    }

    if (totalUsed + fileBytes > TOTAL_LIMIT_BYTES) {
      const remainingGB = ((TOTAL_LIMIT_BYTES - totalUsed) / (1024 * 1024 * 1024)).toFixed(1);
      res.status(429).json({
        error: {
          message: `Storage quota exceeded. ${remainingGB} GB remaining.`
        }
      });
      return;
    }

    // 5. Generate Cloudinary signature
    const config = getCloudinaryConfig();
    
    if (!config.cloudName || !config.apiKey || !config.apiSecret || !config.uploadPreset) {
      res.status(500).json({
        error: {
          message: 'Cloudinary configuration missing. Check functions/.env file.'
        }
      });
      return;
    }

    const timestamp = Math.floor(Date.now() / 1000);
    const folder = 'phoenix_guru/materials';

    const paramsToSign = {
      timestamp: timestamp,
      folder: folder,
      upload_preset: config.uploadPreset,
    };

    // Create signature string
    const signatureString = Object.keys(paramsToSign)
      .sort()
      .map(key => `${key}=${paramsToSign[key]}`)
      .join('&');

    const signature = crypto
      .createHash('sha256')
      .update(signatureString + config.apiSecret)
      .digest('hex');

    // 6. Return signed upload parameters
    res.status(200).json({
      upload_url: `https://api.cloudinary.com/v1_1/${config.cloudName}/auto/upload`,
      fields: {
        timestamp: timestamp,
        folder: folder,
        upload_preset: config.uploadPreset,
        signature: signature,
        api_key: config.apiKey,
      }
    });

  } catch (error) {
    console.error('Error generating Cloudinary signature:', error);
    res.status(500).json({
      error: {
        message: error.message || 'Internal server error'
      }
    });
  }
});