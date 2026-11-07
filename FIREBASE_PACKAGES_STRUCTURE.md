# 🔥 Firebase Packages Structure

## iOS App Store subscriptions

The iOS paywall uses Firestore for package display names, daily profile limits, durations, and product mapping. Prices are fetched from the matching RevenueCat offering and are not stored in Firestore.

| Firestore document ID | Display name (`name`) | RevenueCat package (`revenuecat_package_id`) | App Store product (`ios_product_id`) | Daily profiles | Duration (`days`) |
|---|---|---|---|---:|---|
| `Noor Package` | `Noor Package` | `$rc_monthly` | `Nikahblessing_1month` | 50 | 30 |
| `Yearly Package` | `Rehmat Package` | `$rc_annual` | `Nikahblessing_1yearly` | 200 | 365 |
| `Qismat Pro` | `Qismat Pro` | `$rc_lifetime` | `Nikahblessing_lifetime` | 2010 | `LIFETIME` |

Each iOS document must include `isActive: true`, `ChatCredit: 0`, and optionally `description`. `isIosSubscription` may be present but is not required for iOS display or subscription synchronization. At runtime, the app reads `ios_product_id` from Firestore and matches it against `storeProduct.identifier` in RevenueCat's `default` offering. Documents with an empty `ios_product_id` are skipped. The RevenueCat package ID is logged for diagnostics but does not control product matching. These IDs are not hardcoded in the app. If product IDs change, update Firestore to match the App Store product. Do not add a `price` field for these documents. Set prices in App Store Connect; the app displays the localized RevenueCat price.

To create or replace these three Firestore documents, configure the Firebase app in `firebase_packages_upload.html` and run its upload action. Existing package collections are not automatically migrated by the admin panel. iOS subscription documents are excluded from the non-iOS package list.

## Other package documents

The remaining examples in this document describe non-iOS service packages, including physical services purchased through the existing payment flow.

## 🗂️ Firebase Collection Structure

### Collection: `packages`

Each document represents a service package that users can purchase.

---

## 📦 Non-iOS Package Document Structure

### **Free Package**
```json
{
  "name": "Free",
  "price": 0,
  "description": "Basic matchmaking service",
  "isActive": true,
  "order": 4,
  "createdAt": "2025-01-01T00:00:00.000Z",
  "updatedAt": "2025-01-01T00:00:00.000Z"
}
```

### **Consultation Package** 💼
```json
{
  "name": "Consultation",
  "price": 5000,
  "description": "Professional matchmaking consultation service",
  "isActive": true,
  "order": 2,
  "consultationHours": 1,
  "includesFollowUp": true,
  "followUpDays": 30,
  "createdAt": "2025-01-01T00:00:00.000Z",
  "updatedAt": "2025-01-01T00:00:00.000Z"
}
```

### **Premium Support Package** 🎧
```json
{
  "name": "Premium Support",
  "price": 3000,
  "description": "24/7 dedicated support and guidance",
  "isActive": true,
  "order": 3,
  "supportHours": 30,
  "priorityAccess": true,
  "expertHotline": true,
  "emergencySupport": true,
  "createdAt": "2025-01-01T00:00:00.000Z",
  "updatedAt": "2025-01-01T00:00:00.000Z"
}
```

### **Priority Service Package** ⭐
```json
{
  "name": "Priority Service",
  "price": 10000,
  "description": "Priority access to premium matches and services",
  "isActive": true,
  "order": 1,
  "priorityMatches": 10,
  "expressReview": true,
  "reviewHours": 24,
  "exclusiveEvents": true,
  "verifiedOnly": true,
  "createdAt": "2025-01-01T00:00:00.000Z",
  "updatedAt": "2025-01-01T00:00:00.000Z"
}
```

---

## 🔧 Required Fields for Non-iOS Packages

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | ✅ | Package name (Free, Consultation, Premium Support, Priority Service) |
| `price` | Number | ✅ | Price in PKR (0 for free) |
| `description` | String | ✅ | Brief description of the service |
| `isActive` | Boolean | ✅ | Whether package is available for purchase |
| `order` | Number | ✅ | Display order (1 = highest priority) |
| `createdAt` | Timestamp | ✅ | Creation date |
| `updatedAt` | Timestamp | ✅ | Last update date |

---

## 🎯 Service-Specific Fields

### Consultation Package Fields
| Field | Type | Description |
|-------|------|-------------|
| `consultationHours` | Number | Hours of consultation provided (default: 1) |
| `includesFollowUp` | Boolean | Whether follow-up support is included |
| `followUpDays` | Number | Days of follow-up support (default: 30) |

### Premium Support Package Fields
| Field | Type | Description |
|-------|------|-------------|
| `supportHours` | Number | Days of premium support (default: 30) |
| `priorityAccess` | Boolean | Priority support queue access |
| `expertHotline` | Boolean | Direct access to relationship experts |
| `emergencySupport` | Boolean | Emergency assistance availability |

### Priority Service Package Fields
| Field | Type | Description |
|-------|------|-------------|
| `priorityMatches` | Number | Number of priority matches (default: 10) |
| `expressReview` | Boolean | Express profile review service |
| `reviewHours` | Number | Hours for express review (default: 24) |
| `exclusiveEvents` | Boolean | Access to exclusive matchmaking events |
| `verifiedOnly` | Boolean | Only show verified premium profiles |

---

## ⚙️ Setup Instructions

### 1. Create Collection in Firebase Console
1. Go to **Firestore Database** in Firebase Console
2. Create collection named **`packages`**
3. Add documents with the structure above

### 2. Enable Firebase Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to packages for all users
    match /packages/{packageId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
  }
}
```

### 3. Test the Configuration
After adding packages to Firebase:
1. Restart your app
2. Navigate to the packages page
3. Verify all packages display correctly
4. Test purchasing flow with each service type

---

## 🔄 Dynamic Package Management

### Adding New Service Types
1. Add new document to `packages` collection
2. Update the switch statement in `_getPackageFeatures()` method in `allPackagesModule.dart`
3. Add corresponding icons and colors in helper methods

### Modifying Existing Services
1. Update the document in Firebase
2. Changes will reflect immediately in the app (real-time updates)

### Disabling Services
1. Set `isActive: false` in Firebase
2. Service will no longer appear in the packages list

---

## 📱 User Experience

### What Users See:
- **Service Names**: "Consultation", "Premium Support", "Priority Service"
- **Physical Service Language**: "Professional consultation", "Dedicated assistance"
- **Tangible Benefits**: Hours of service, days of support, number of matches

### Payment Flow:
- Users purchase **physical services** (not digital subscriptions)
- Payment goes through **JazzCash** (third-party gateway)
- Services are delivered as **consultations, support, priority access**

---

## ✅ Google Play Store Compliance

✅ **Third-party Payment Gateway**: JazzCash allowed for physical services
✅ **No Auto-renewal**: Services are one-time purchases
✅ **Physical Goods Language**: Consultation calls, support services
✅ **Clear Service Description**: Hours, days, specific deliverables

---

## 🚨 Important Notes

1. **Prices in PKR**: Non-iOS service prices must be in Pakistani Rupees. iOS prices come from RevenueCat.
2. **Service Delivery**: Ensure you can actually deliver the promised services
3. **Customer Support**: Provide clear contact information for service inquiries
4. **Refund Policy**: Update terms to reflect physical service purchases

---

## 🎯 Example Package Setup

Here's a complete example of how to set up all packages in Firebase:

```bash
# Create packages collection and documents via Firebase Console
# or use Firebase CLI/Batch write operations
```

**Your app is now configured to sell physical matchmaking services instead of digital subscriptions, making it compliant with Google Play Store policies for third-party payment gateways!** 🎉
