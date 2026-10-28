# Nikah Blessing

Flutter matrimonial app for verified Muslim marriage profiles, messaging, profile moderation, and package-based access.

## App Store Audit

Audit date: May 17, 2026

Current status: `Not ready for App Store submission yet`

This repo now includes:

- Sign in with Apple added to the Flutter login flow for iOS.
- iOS Apple Sign-In entitlement file added.
- Missing iOS photo-library privacy strings added to `Info.plist`.
- A dedicated in-app Privacy Policy page added.
- Legal copy updated to remove Google Play-specific refund wording from the in-app terms page.

## What I Changed

- Added Apple sign-in service: `lib/Email_Authentication/apple_signin.dart`
- Added Apple sign-in button to the existing auth screen: `lib/Email_Authentication/EmailSignIn_Page.dart`
- Added in-app privacy policy screen: `lib/User_Home_Pages/AccountModule/PrivacyPolicyPage.dart`
- Linked privacy policy from onboarding and account settings
- Added Apple sign-in entitlement: `ios/Runner/Runner.entitlements`
- Added iOS privacy usage descriptions for Photos: `ios/Runner/Info.plist`
- Enabled entitlements in the iOS target: `ios/Runner.xcodeproj/project.pbxproj`

## Must-Fix Before App Store Submission

### 1. iOS payments are a major blocker

The app currently sells digital app features such as:

- package upgrades
- chat credits
- daily profile limits

But the iOS flow still uses external payment methods:

- card entry
- JazzCash
- EasyPaisa/manual payment
- payment proof upload

For App Store review, this is the biggest rejection risk. If these purchases unlock digital functionality inside the app, the iOS version should use StoreKit In-App Purchase instead of external payment flows, or the paid upgrade flow must be removed from the iOS build.

Relevant code:

- `lib/Packages_Module/allPackagesModule.dart`
- `lib/Payement_Module/PaymentPagesController.dart`
- `lib/Payement_Module/manualPayement_Page.dart`
- `lib/Payement_Module/CreditCardPaymentPage.dart`
- `lib/Payement_Module/JazzCashPaymentPage.dart`

### 2. Sign in with Apple still needs Apple-side setup and real-device testing

Code support is now added, but you still need to finish this on your Mac and Apple account:

- enable `Sign in with Apple` for the App ID in Apple Developer
- open the iOS project in Xcode and confirm the capability is enabled
- build and test on a real iPhone with a real Apple ID
- verify the Firebase `apple.com` provider is enabled

### 3. Account deletion exists, but Apple token revocation is still a follow-up task

The app already lets users delete accounts from account settings, which is good.  
However, once Sign in with Apple is supported, Apple recommends revoking Sign in with Apple tokens when the user deletes their account. That part is not implemented in this repo yet.

Relevant code:

- `lib/User_Home_Pages/AccountModule/UserDeletion.dart`

### 4. Privacy policy content still has placeholder business details

Your hosted privacy policy currently contains placeholder contact details such as:

- `+92 XXX XXXXXXX`
- `[Your Business Address]`

These should be replaced with your real support and legal contact information before submission.

Relevant files:

- `public/privacy-policy/index.html`
- `privacy_policy.html`

### 5. Some iOS release files could not be verified from this repo

I could not verify these from the current workspace:

- `GoogleService-Info.plist`
- `Podfile`
- privacy manifest file (`.xcprivacy`)

They may exist only on your Mac or in an uncommitted state. Before submission, confirm the final iOS archive contains everything required by Firebase, Google Sign-In, and your other SDKs.

## Good Signs From The Audit

- Account creation exists
- In-app account deletion exists and is discoverable from account settings
- Camera and microphone usage strings already existed
- Privacy policy is hosted publicly
- Terms and privacy acceptance exists during onboarding
- App has a real iOS target and app icons already present

## Submission Checklist

- Replace iOS digital purchases with StoreKit In-App Purchase, or remove purchase UI from the iOS build
- Enable `apple.com` in Firebase Authentication
- Enable `Sign in with Apple` capability in Apple Developer and Xcode
- Test Apple sign-in on a real iPhone
- Verify Google sign-in still works on iOS
- Replace placeholder privacy-policy contact details
- Fill App Store Connect privacy nutrition labels accurately
- Verify account deletion works for email, Google, and Apple login users
- Add review notes and a demo account for App Review
- Archive on a Mac and test the signed release build before upload

## Apple References

- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Account deletion requirement: https://developer.apple.com/support/offering-account-deletion-in-your-app
- Privacy manifest guidance: https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- Sign in with Apple token revocation note: https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple

## Practical Recommendation

If you want the fastest path to App Store approval, do this next:

1. Disable or hide all external paid package flows on iOS.
2. Submit a free or limited iOS version first, or replace package sales with StoreKit.
3. Finish Apple Sign-In setup on your Mac and test it on-device.

Until the iOS payment model is fixed, this app is still high-risk for App Store rejection even though the Apple sign-in gap is now addressed in code.






