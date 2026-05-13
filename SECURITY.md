# Security Guidelines

## Frontend Security

### ✅ What's Safe in Frontend

1. **Cloudinary Cloud Name** (`CLOUDINARY_CLOUD_NAME`)
   - Public-facing identifier
   - Appears in all Cloudinary URLs
   - Safe to expose

2. **Cloudinary Upload Preset** (`CLOUDINARY_UPLOAD_PRESET`)
   - Required for unsigned uploads
   - Configured in Cloudinary dashboard with restrictions
   - Safe for unsigned upload flow

### ❌ What Should NEVER Be in Frontend

1. **API Keys** - Should only be in backend/Firebase Functions
2. **API Secrets** - Should only be in backend/Firebase Functions
3. **Private Keys** - Should only be in backend
4. **Database Credentials** - Should only be in backend
5. **Service Account Keys** - Should only be in backend

## Current Upload Architecture

### Unsigned Uploads (Current Implementation)

**Pros:**
- No Firebase Functions required (no Blaze plan cost)
- Simple implementation
- Fast uploads

**Cons:**
- Anyone who discovers your upload preset can upload files
- Rate limiting is client-side only (can be bypassed)
- Less control over uploads

**Mitigations:**
- Set upload preset restrictions in Cloudinary dashboard:
  - Max file size: 20 MB
  - Allowed formats: pdf, jpg, png, doc, docx
  - Folder: `phoenix_guru/materials`
  - Rate limits
- Client-side validation (can be bypassed but adds friction)
- Monitor Cloudinary usage regularly

### Signed Uploads (Recommended for Production)

**Pros:**
- Full security - API credentials never exposed
- Server-side validation and rate limiting
- Complete control over uploads
- Can add custom business logic

**Cons:**
- Requires Firebase Functions (Blaze plan)
- More complex implementation
- Slightly slower (extra backend call)

**Implementation:**
1. Create Firebase Function to generate signed upload URLs
2. Frontend requests signed URL from backend
3. Frontend uploads directly to Cloudinary with signed URL
4. Backend validates user permissions before signing

## Firebase Security

### Firestore Rules
- All rules are server-side enforced
- Users can only access their own data
- Teachers can only modify their own classes
- Students can only join classes with valid codes

### Authentication
- Firebase Authentication handles all auth
- No passwords stored in app
- Google Sign-In for secure authentication

## Best Practices

1. **Never commit `.env` file** - Already in `.gitignore`
2. **Use `.env.example` as template** - Safe to commit
3. **Rotate credentials regularly** - Especially if exposed
4. **Monitor usage** - Check Cloudinary and Firebase dashboards
5. **Set up alerts** - For unusual activity
6. **Review security rules** - Regularly audit Firestore rules

## Reporting Security Issues

If you discover a security vulnerability, please email: [your-email@example.com]

Do NOT create a public GitHub issue for security vulnerabilities.
