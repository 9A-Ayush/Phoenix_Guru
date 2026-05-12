# Cloudinary Integration Setup Guide

## Prerequisites
- Cloudinary free account (25 GB storage)
- Firebase project with Functions enabled (Blaze plan required for Functions)
- Node.js 18+ installed

---

## Step 1: Create Cloudinary Account

1. Go to [cloudinary.com](https://cloudinary.com) and sign up (free, no credit card)
2. After login, go to **Dashboard** and note:
   - `Cloud Name`
   - `API Key`
   - `API Secret`

3. Go to **Settings → Upload → Upload Presets**
4. Click **Add upload preset**
5. Configure:
   - **Preset name**: `phoenix_guru_materials`
   - **Signing mode**: Unsigned (we'll use signed uploads via Functions)
   - **Folder**: `phoenix_guru/materials`
   - **Allowed formats**: `pdf,doc,docx,ppt,pptx,jpg,jpeg,png,webp`
   - **Max file size**: 20 MB
6. Save the preset

---

## Step 2: Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

---

## Step 3: Initialize Firebase Functions

```bash
cd phoenix_guru
firebase init functions

# Select:
# - Use existing project → select your Firebase project
# - Language: JavaScript
# - ESLint: No
# - Install dependencies: Yes
```

---

## Step 4: Install Function Dependencies

```bash
cd functions
npm install firebase-admin firebase-functions
cd ..
```

---

## Step 5: Configure Cloudinary Credentials

**IMPORTANT:** Never commit API secrets to git!

```bash
firebase functions:config:set \
  cloudinary.cloud_name="YOUR_CLOUD_NAME" \
  cloudinary.api_key="YOUR_API_KEY" \
  cloudinary.api_secret="YOUR_API_SECRET" \
  cloudinary.upload_preset="phoenix_guru_materials"
```

Verify:
```bash
firebase functions:config:get
```

---

## Step 6: Update Firebase Function URL

1. Deploy functions first to get the URL:
```bash
firebase deploy --only functions
```

2. After deployment, you'll see:
```
✔  functions[getCloudinarySignature(us-central1)] Successful create operation.
Function URL: https://us-central1-YOUR_PROJECT.cloudfunctions.net/getCloudinarySignature
```

3. Copy the base URL (without `/getCloudinarySignature`)

4. Update `lib/core/services/cloudinary_service.dart`:
```dart
static const _functionsBaseUrl = 'https://us-central1-YOUR_PROJECT.cloudfunctions.net';
```

---

## Step 7: Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

---

## Step 8: Test the Integration

1. Run the app:
```bash
flutter run
```

2. Login as a teacher

3. Go to a class → Material tab → Upload Material

4. Select a file (< 20 MB)

5. Check:
   - Upload progress bar works
   - File appears in Cloudinary dashboard
   - Material appears in Firestore `classes/{classId}/materials`
   - Daily tracker updates in `users/{teacherId}/uploadTracker/daily`

---

## Quota Limits

| Limit | Value | Enforcement |
|---|---|---|
| Total storage | 25 GB | Client + Server |
| Daily upload per teacher | 500 MB | Server-side |
| Max file size | 20 MB | Client + Server |
| Allowed formats | PDF, DOC, DOCX, PPT, PPTX, JPG, JPEG, PNG, WEBP | Cloudinary preset |

---

## Security Features

✅ **Signed uploads** — API secret never exposed to client  
✅ **Firebase Auth** — All uploads require valid auth token  
✅ **Server-side validation** — Daily + total limits checked before signature  
✅ **Firestore rules** — Only class teacher can upload/delete materials  
✅ **Rate limiting** — 500 MB/day per teacher  

---

## Troubleshooting

### Error: "Failed to get upload signature"
- Check Firebase Functions logs: `firebase functions:log`
- Verify Cloudinary config: `firebase functions:config:get`
- Ensure Functions are deployed: `firebase deploy --only functions`

### Error: "Daily upload limit reached"
- Check `users/{teacherId}/uploadTracker/daily` in Firestore
- Limit resets automatically at midnight (UTC)

### Error: "Storage quota exceeded"
- Check total materials size across all classes
- Delete old materials to free up space

### Upload stuck at 0%
- Check network connection
- Verify file size < 20 MB
- Check browser console for errors

---

## Cost Estimate

| Service | Free Tier | Cost if Exceeded |
|---|---|---|
| Cloudinary | 25 GB storage, 25 GB bandwidth/month | $0.10/GB storage, $0.10/GB bandwidth |
| Firebase Functions | 2M invocations/month, 400K GB-sec | $0.40/M invocations, $0.0000025/GB-sec |
| Firestore | 50K reads, 20K writes/day | $0.06/100K reads, $0.18/100K writes |

**Estimated monthly cost for 100 teachers:**
- Cloudinary: Free (if < 25 GB total)
- Firebase Functions: Free (if < 2M uploads/month)
- Firestore: ~$5-10/month

---

## Monitoring

### Cloudinary Dashboard
- Go to **Media Library** → `phoenix_guru/materials` folder
- View total storage used
- See all uploaded files

### Firebase Console
- **Functions → Logs** — View upload requests and errors
- **Firestore → Data** — Check `materials` and `uploadTracker` collections
- **Authentication** — Verify teacher accounts

### App UI
- Material tab shows storage quota bar (X GB / 25 GB)
- Daily usage indicator (X MB / 500 MB used today)
- Upload button disabled when limits hit

---

## Future Enhancements

- [ ] Cloudinary signed delete (currently files remain after Firestore delete)
- [ ] Bulk upload (multiple files at once)
- [ ] In-app PDF viewer
- [ ] Video upload support
- [ ] Admin dashboard for storage analytics
- [ ] Automatic cleanup of old materials (> 1 year)

---

## Support

For issues:
1. Check Firebase Functions logs
2. Check Cloudinary dashboard
3. Verify Firestore rules are deployed
4. Test with small file first (< 1 MB)
