# Firebase Blaze Plan Upgrade Required

## Why Blaze Plan is Needed

Firebase Functions (Cloud Functions) require the **Blaze (pay-as-you-go) plan**. The free Spark plan doesn't support Cloud Functions.

---

## Cost Breakdown

### Firebase Functions Free Tier (on Blaze Plan)

| Resource | Free Tier | Cost if Exceeded |
|---|---|---|
| Invocations | 2,000,000/month | $0.40 per million |
| Compute time | 400,000 GB-seconds/month | $0.0000025 per GB-second |
| Outbound networking | 5 GB/month | $0.12 per GB |

### Estimated Monthly Cost for Phoenix Guru

**Scenario: 100 teachers, 500 students**
- Upload requests: ~3,000/month (30 uploads/teacher)
- Compute time: ~1,000 GB-seconds (0.3s per request)
- Networking: ~1 GB

**Total: $0/month** (well within free tier)

**Scenario: 1,000 teachers, 5,000 students**
- Upload requests: ~30,000/month
- Compute time: ~10,000 GB-seconds
- Networking: ~10 GB

**Total: ~$0.60/month** (minimal overage)

---

## How to Upgrade

### Step 1: Add Payment Method

1. Go to [Firebase Console](https://console.firebase.google.com/project/pheonix-guru/usage/details)
2. Click **"Upgrade to Blaze"**
3. Add a credit/debit card
4. Set a **spending limit** (recommended: $5/month to prevent surprises)

### Step 2: Enable Required APIs

After upgrading, Firebase will automatically enable:
- Cloud Functions API
- Cloud Build API
- Artifact Registry API

### Step 3: Deploy Functions

```bash
cd c:\Users\ayush\OneDrive\Desktop\phoenix_guru
firebase deploy --only functions
```

---

## Setting a Spending Limit

**Highly Recommended:** Set a monthly budget to avoid unexpected charges.

1. Go to [Google Cloud Console](https://console.cloud.google.com/billing)
2. Select your project: **pheonix-guru**
3. Click **Budgets & alerts**
4. Create budget:
   - Name: "Firebase Monthly Limit"
   - Amount: $5/month
   - Alert at: 50%, 90%, 100%

This will send you email alerts if costs approach the limit.

---

## Alternative: Use Firebase Emulator (Local Testing)

If you want to test without upgrading, use the Firebase Emulator:

```bash
cd functions
npm install
cd ..
firebase emulators:start --only functions
```

Then update `cloudinary_service.dart`:
```dart
static const _functionsBaseUrl = 'http://localhost:5001/pheonix-guru/us-central1';
```

**Note:** This only works for local testing. Production requires Blaze plan.

---

## What Happens After Upgrade?

✅ **Free tier still applies** — You only pay if you exceed free limits  
✅ **No minimum charge** — $0/month if usage stays within free tier  
✅ **Spending alerts** — Get notified before hitting your budget  
✅ **Cancel anytime** — Downgrade back to Spark plan (but Functions will stop working)

---

## Security: Prevent Unexpected Charges

1. **Set spending limit** ($5/month recommended)
2. **Monitor usage** in Firebase Console → Usage tab
3. **Rate limiting** already implemented (500 MB/day per teacher)
4. **Firestore rules** prevent unauthorized access
5. **Server-side validation** prevents abuse

---

## FAQ

**Q: Will I be charged immediately after upgrading?**  
A: No. You're only charged if you exceed the free tier limits.

**Q: What if I forget to set a spending limit?**  
A: Firebase will charge your card for any overage. Always set a budget!

**Q: Can I downgrade back to Spark plan?**  
A: Yes, but Cloud Functions will stop working.

**Q: Is there a minimum monthly charge?**  
A: No. If you stay within free tier, it's $0/month.

**Q: What if my card is declined?**  
A: Firebase will disable Functions until payment is resolved.

---

## Next Steps

1. ✅ Upgrade to Blaze plan
2. ✅ Set $5/month spending limit
3. ✅ Deploy functions: `firebase deploy --only functions`
4. ✅ Update `cloudinary_service.dart` with function URL
5. ✅ Test upload in the app

---

## Support

If you have concerns about costs:
- Start with a $5/month limit
- Monitor usage for the first month
- Adjust limit based on actual usage
- Expected cost: $0-2/month for moderate usage
