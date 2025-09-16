# Google AdMob Integration Guide for TunePlay

This comprehensive guide will walk you through setting up Google AdMob for your TunePlay iOS app to enable monetization through banner advertisements.

## Prerequisites

- Apple Developer Account (required for App Store submission)
- Xcode 15.0 or later
- iOS 16.0+ deployment target
- Valid bundle identifier for your app

## Step 1: Create Google AdMob Account

1. **Visit AdMob Console**: Go to https://admob.google.com
2. **Sign in** with your Google account (create one if needed)
3. **Accept Terms**: Review and accept the AdMob Terms & Conditions
4. **Select Country**: Choose your country/territory for payments
5. **Complete Account Setup**: Provide tax information and payment details

## Step 2: Create Your App in AdMob

1. **Navigate to Apps**: In the AdMob console, click "Apps" in the left sidebar
2. **Add App**: Click the "Add app" button
3. **Select Platform**: Choose "iOS"
4. **App Store Status**: Select "No" (since the app isn't published yet)
5. **App Details**:
   - **App name**: Enter "TunePlay"
   - **Bundle ID**: Use your chosen bundle identifier (e.g., `com.yourcompany.tuneplay`)
   - **App category**: Select "Music & Audio"
6. **Click "Add"** to create your app

## Step 3: Create Ad Units

1. **Select Your App**: Click on your newly created TunePlay app
2. **Add Ad Unit**: Click "Add ad unit"
3. **Select Ad Format**: Choose "Banner"
4. **Ad Unit Settings**:
   - **Ad unit name**: "TunePlay Banner"
   - **Ad size**: Banner (320x50)
5. **Click "Create ad unit"**
6. **Copy Ad Unit ID**: Save the generated ad unit ID (format: `ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY`)

## Step 4: Update Your App Configuration

### 4.1 Update Bundle Identifier

1. Open `TunePlayApp.xcodeproj` in Xcode
2. Select the project in the navigator
3. Under "Targets" → "TunePlayApp" → "General"
4. Update **Bundle Identifier** to match what you used in AdMob (e.g., `com.yourcompany.tuneplay`)

### 4.2 Update AdMob Configuration

1. **Update Info.plist**: Replace the test App ID in `TunePlayApp/Info.plist`:
   ```xml
   <key>GADApplicationIdentifier</key>
   <string>ca-app-pub-XXXXXXXXXXXXXXXX~ZZZZZZZZZZ</string>
   ```
   Replace `ca-app-pub-XXXXXXXXXXXXXXXX~ZZZZZZZZZZ` with your actual AdMob App ID from Step 2.

2. **Update Ad Unit ID**: In `TunePlay/Sources/TunePlay/UI/AdBannerView.swift`, replace the test ad unit ID:
   ```swift
   init(adUnitID: String = "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY") {
   ```
   Replace `ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY` with your actual ad unit ID from Step 3.

## Step 5: Test Your Integration

### 5.1 Build and Run
1. Build your project in Xcode
2. Run on iOS Simulator or device
3. Verify that ads load correctly at the bottom of the screen

### 5.2 Test Ad Loading
- **Test Ads**: During development, the current code uses test ad unit IDs
- **Real Ads**: Only use production ad unit IDs when submitting to App Store
- **Ad Loading**: Ads should appear at the bottom of the tuner interface

## Step 6: App Store Preparation

### 6.1 Privacy Policy (Required)
Create a privacy policy that includes:
- Data collection practices
- Use of advertising identifiers
- Third-party ad networks (Google AdMob)
- User rights and contact information

Example privacy policy template:
```
TunePlay Privacy Policy

Data Collection:
- We collect anonymous usage data to improve app performance
- We use Google AdMob to display advertisements
- AdMob may collect device identifiers for ad personalization

Advertising:
- We display banner advertisements through Google AdMob
- You can opt out of personalized ads in your device settings
- No personal information is shared with advertisers

Contact: [Your email address]
```

### 6.2 App Store Connect Setup
1. **Create App**: In App Store Connect, create a new app
2. **Bundle ID**: Use the same bundle identifier from your Xcode project
3. **App Information**:
   - **Name**: TunePlay
   - **Category**: Music
   - **Content Rights**: Choose appropriate rating
4. **Privacy Policy URL**: Add your privacy policy URL
5. **App Description**: Use the description from README.md

### 6.3 Required App Store Assets
Create the following assets:
- **App Icon**: 1024x1024 PNG (no transparency, no rounded corners)
- **Screenshots**: 
  - iPhone: 6.7" display (1290x2796) - at least 3 screenshots
  - iPad: 12.9" display (2048x2732) - at least 3 screenshots
- **App Preview** (optional): 30-second video showing app functionality

## Step 7: Revenue and Payments

### 7.1 Payment Setup
1. **AdMob Console**: Go to "Payments" section
2. **Add Payment Method**: Add bank account or other payment method
3. **Tax Information**: Complete tax forms (W-9 for US, W-8 for international)
4. **Payment Threshold**: Minimum $100 for payment

### 7.2 Revenue Optimization
- **Ad Placement**: Banner ads are placed at bottom to not interfere with tuning
- **Ad Refresh**: Ads refresh automatically based on user interaction
- **Performance**: Monitor fill rates and eCPM in AdMob console

## Step 8: Launch Checklist

### Pre-Launch Testing
- [ ] App builds without errors
- [ ] Ads load correctly on device
- [ ] Microphone permission works
- [ ] All tuning features function properly
- [ ] App works on various iOS devices and screen sizes
- [ ] Privacy policy is accessible and complete

### App Store Submission
- [ ] Bundle identifier matches AdMob configuration
- [ ] Production ad unit IDs are configured
- [ ] App icons and screenshots are uploaded
- [ ] Privacy policy URL is set
- [ ] App description is compelling and accurate
- [ ] Age rating is appropriate
- [ ] All required metadata is complete

### Post-Launch Monitoring
- [ ] Monitor AdMob revenue in console
- [ ] Track app performance and user feedback
- [ ] Update app based on user reviews
- [ ] Optimize ad placement based on performance data

## Troubleshooting

### Common Issues

**Ads Not Loading**:
- Verify internet connection
- Check AdMob console for app approval status
- Ensure ad unit IDs are correct
- Test with different devices/simulators

**Build Errors**:
- Clean build folder (Product → Clean Build Folder)
- Update to latest Xcode version
- Verify all dependencies are properly linked

**Revenue Issues**:
- Check payment method in AdMob console
- Verify tax information is complete
- Monitor fill rates and ad performance

### Support Resources
- **AdMob Help Center**: https://support.google.com/admob
- **iOS Integration Guide**: https://developers.google.com/admob/ios
- **AdMob Community**: https://groups.google.com/forum/#!forum/google-admob-ads-sdk

## Security Notes

- **Never commit production ad unit IDs** to public repositories
- **Use test ad unit IDs** during development
- **Rotate ad unit IDs** if they become compromised
- **Monitor unusual traffic** in AdMob console

## Next Steps After Launch

1. **Monitor Performance**: Check AdMob console daily for revenue and performance metrics
2. **User Feedback**: Respond to App Store reviews and implement improvements
3. **Updates**: Regular app updates to maintain compatibility and add features
4. **Marketing**: Promote your app through social media and music communities
5. **Analytics**: Consider adding analytics to track user behavior and app usage

---

**Important**: Replace all placeholder values (XXXXXXXXXXXXXXXX, YYYYYYYYYY, etc.) with your actual AdMob IDs before submitting to the App Store.
