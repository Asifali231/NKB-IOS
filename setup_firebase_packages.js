// Firebase Packages Setup Script
// Run this in your browser's console at Firebase Console or use Firebase CLI

const packages = [
  {
    name: "Priority Service",
    price: 10000,
    description: "Priority access to premium matches and services",
    isActive: true,
    order: 1,
    priorityMatches: 10,
    expressReview: true,
    reviewHours: 24,
    exclusiveEvents: true,
    verifiedOnly: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: "Consultation",
    price: 5000,
    description: "Professional matchmaking consultation service",
    isActive: true,
    order: 2,
    consultationHours: 1,
    includesFollowUp: true,
    followUpDays: 30,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: "Premium Support",
    price: 3000,
    description: "24/7 dedicated support and guidance",
    isActive: true,
    order: 3,
    supportHours: 30,
    priorityAccess: true,
    expertHotline: true,
    emergencySupport: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: "Free",
    price: 0,
    description: "Basic matchmaking service",
    isActive: true,
    order: 4,
    createdAt: new Date(),
    updatedAt: new Date()
  }
];

// Function to add packages to Firebase
async function setupPackages() {
  try {
    const db = firebase.firestore();

    for (const package of packages) {
      await db.collection('packages').doc(package.name.toLowerCase().replace(' ', '_')).set(package);
      console.log(`✅ Added package: ${package.name}`);
    }

    console.log('🎉 All packages added successfully!');
  } catch (error) {
    console.error('❌ Error adding packages:', error);
  }
}

// Usage:
// 1. Open Firebase Console -> Firestore Database
// 2. Open browser console
// 3. Run: setupPackages()

// Alternative: Use Firebase CLI
// firebase firestore:delete --all-collections (CAUTION: deletes all data)
// Then run this script or manually add documents
