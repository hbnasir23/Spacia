# Spacia - Furniture & Interior Decor E-Commerce Platform

<div >
  <img src="assets/logo.png" alt="Spacia Logo" width="200"/>
  
  [![Flutter Version](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
</div>

## 📖 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Firebase Setup](#firebase-setup)
- [Google Sign-In Configuration](#google-sign-in-configuration)
- [Stripe Payment Setup](#stripe-payment-setup)
- [Project Structure](#project-structure)
- [User Roles](#user-roles)
- [Screenshots](#screenshots)
- [Contributing](#contributing)

---

## 🌟 Overview

**Spacia** is a comprehensive Flutter-based e-commerce platform for furniture and interior decor. The application supports three distinct user roles (Consumer, Business Owner, and Admin) with role-specific dashboards and features. It includes advanced features like AR/3D model viewing, real-time order tracking, integrated payment processing via Stripe, and Google Sign-In authentication.

---

## ✨ Features

### 🛍️ Consumer Features

#### Authentication & Profile
- **Email/Password Authentication** - Secure login and registration
- **Google Sign-In Integration** - Quick OAuth authentication
- **Profile Management** - Update personal information, profile picture
- **Location Services** - Set delivery address with Google Maps integration
- **Upload Profile Photo** - Store images in Firebase Storage (`user_profiles` folder)

#### Shopping Experience
- **Product Browsing** - View products with images, prices, and descriptions
- **Category Filtering** - Browse products by categories (fetched from Firestore)
- **Search Functionality** - Search products by name
- **Price Range Filters** - Filter products by minimum and maximum price
- **Product Details** - View full product information including:
  - High-resolution images
  - 3D model viewer (interactive AR models)
  - Stock availability
  - Business information
- **Stock Management** - Products show "Out of Stock" when quantity is 0

#### Shopping Cart & Checkout
- **Add to Cart** - Add multiple products with quantity selection
- **Cart Management** - Update quantities, remove items
- **Address Management** - Add/edit delivery addresses
- **Location Integration** - Set delivery location with latitude/longitude
- **Order Placement** - Cannot place order without valid address
- **Stripe Payment Integration** - Secure card payments (test mode)
- **10% Admin Commission** - Automatic commission calculation
- **Order Confirmation Email** - Receive order details via Gmail

#### Orders & Tracking
- **Order History** - View all past orders
- **Order Status Tracking** - Track order progress (Pending, Paid, Completed)
- **Order Details** - View itemized order information

#### Settings
- **About Us** - Company information
- **Help & Support** - Contact details
- **Privacy Policy** - Data protection information
- **Terms & Conditions** - Usage terms
- **Transaction History** - View payment records
- **Logout** - Secure sign-out with Google session cleanup

---

### 🏪 Business Owner Features

#### Dashboard
- **Statistics Overview** - View:
  - Total Sales
  - Total Orders
  - Revenue (Last 7 Days chart)
- **Recent Orders** - Quick view of latest orders
- **Your Products** - Preview of product inventory
- **Transaction Summary** - Total completed/pending transactions

#### Product Management
- **Add Products** - Create new product listings with:
  - Multiple images (2-3 photos)
  - Name, description, price
  - Category selection
  - Stock quantity
  - 3D model URL (optional)
- **Edit Products** - Update product information
- **View Products** - See all listed products
- **Delete Products** - Remove products from inventory
- **Stock Tracking** - Monitor available quantities

#### Order Management
- **All Orders** - View orders for your business
- **Order Details** - See customer information and items
- **Filter Orders** - By status (Paid, Completed, Pending)

#### Transactions
- **Transaction History** - View all completed transactions
- **Revenue Tracking** - Monitor earnings
- **Payment Status** - Track pending/completed payments

#### Profile
- **Business Information** - Edit business details
- **Address Management** - Update business location
- **Profile Settings** - Manage business profile

#### Navigation
- **Custom Navbar** - Brown-themed bottom navigation with:
  - Orders (leftmost)
  - Add Product
  - Dashboard (center, highlighted)
  - Products
  - Transactions (rightmost)
- **Custom Top Bar** - Branded header with business name

---

### 👑 Admin Features

#### Dashboard
- **Statistics Panel** - View:
  - Total Businesses (approved)
  - Total Products
  - Total Orders
  - Total Revenue
  - Admin Profit (10% commission)
- **Recent Orders** - Last 10 orders with quick access
- **Visual Analytics** - Clean, card-based statistics display

#### Business Management
- **Business Requests** - Review pending business registrations
- **Approve/Reject** - Control business account approvals
- **Business List** - View all approved businesses with:
  - Business name
  - Email
  - Revenue information
- **Business Details** - View comprehensive business information
- **Search Businesses** - Filter by name or email
- **Delete Businesses** - Remove business accounts (with confirmation)

#### Product Management
- **All Products** - View products from all businesses
- **Grid View Display** - Responsive product cards
- **Product Details** - View full product information including:
  - Large product images
  - 3D model viewer (toggle show/hide)
  - Stock levels
  - Business owner information
- **Search Products** - Filter by name or category
- **Price Filters** - Set min/max price range
- **Delete Products** - Remove products (with confirmation)

#### Order Management
- **All Orders** - Comprehensive order list
- **Filter Orders** - By status (All, Paid, Completed, Pending)
- **Order Details** - View complete order information
- **User Information** - See customer email and business name
- **Colored Status Chips**:
  - 🟢 Green for Paid
  - 🔵 Blue for Completed
  - 🟠 Orange for Pending
  - 🔴 Red for Cancelled

#### Notifications
- **Notification Center** - Two-tab interface:
  - **Orders Tab** - View recent orders (last 50)
  - **Businesses Tab** - View pending approval requests
- **Real-time Updates** - Firestore stream integration
- **Time Stamps** - "2h ago", "3d ago" format
- **Color-coded Icons** - Green for orders, Orange for businesses

#### Navigation & UI
- **Bottom Navbar** - Five icons with circular highlights:
  - Orders
  - Businesses
  - Dashboard (center)
  - Products
  - Business Requests
- **Top Bar** - Dark brown header with:
  - Page title
  - Notifications icon
  - Logout icon (with confirmation)
- **Light Brown Theme** - Consistent color scheme throughout

---

## 🛠️ Technology Stack

### Frontend
- **Flutter** (3.0+) - Cross-platform mobile framework
- **Dart** - Programming language
- **Material Design** - UI components

### Backend & Services
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - NoSQL database
- **Firebase Storage** - Image and file storage
- **Firebase Cloud Messaging** - Push notifications (optional)

### Third-Party Integrations
- **Google Sign-In** (`google_sign_in`) - OAuth authentication
- **Google Maps** (`google_maps_flutter_android`) - Location services
- **Stripe** (`flutter_stripe`) - Payment processing
- **Model Viewer Plus** (`model_viewer_plus`) - 3D model rendering

### Additional Packages
- `geolocator` - Location services
- `image_picker` - Image selection
- `file_picker` - File selection
- `http` - HTTP requests
- `intl` - Internationalization

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.0 or higher)
  ```bash
  flutter --version
  ```
- **Dart SDK** (2.17 or higher)
- **Android Studio** or **Xcode** (for mobile development)
- **Firebase Account** (free tier works)
- **Stripe Account** (for payment processing)
- **Git** (for version control)

### System Requirements
- **Operating System**: Windows, macOS, or Linux
- **RAM**: 8GB minimum (16GB recommended)
- **Storage**: 10GB free space
- **Internet Connection**: Required for Firebase and package downloads

---

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/spacia.git
cd spacia
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Verify Installation

```bash
flutter doctor
```

Resolve any issues shown by Flutter Doctor before proceeding.

---

## 🔥 Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Name your project "Spacia" (or your preferred name)
4. Disable Google Analytics (optional)
5. Click "Create Project"

### 2. Add Android App

1. In Firebase Console, click "Add App" → Android
2. Enter Android package name: `com.example.spacia`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

### 3. Add iOS App (if building for iOS)

1. Click "Add App" → iOS
2. Enter iOS bundle ID: `com.example.spacia`
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

### 4. Enable Firebase Services

#### Authentication
1. Go to **Authentication** → Sign-in method
2. Enable:
   - Email/Password
   - Google Sign-In

#### Firestore Database
1. Go to **Firestore Database**
2. Click "Create Database"
3. Start in **Test Mode** (for development)
4. Choose location (closest to your users)

#### Storage
1. Go to **Storage**
2. Click "Get Started"
3. Start in **Test Mode**

### 5. Firestore Security Rules

Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Businesses collection
    match /businesses/{businessId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null;
    }
    
    // Products collection
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    
    // Categories collection
    match /categories/{categoryId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 6. Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /user_profiles/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /product_images/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /business_images/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

---

## 🔐 Google Sign-In Configuration

### Android Setup

#### 1. Get SHA-1 Fingerprint

```bash
# For Debug
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# For Release
keytool -list -v -keystore path/to/your/keystore.jks -alias your_key_alias
```

#### 2. Add SHA-1 to Firebase

1. Go to Firebase Console → Project Settings
2. Scroll to "Your apps" → Android app
3. Click "Add fingerprint"
4. Paste your SHA-1 fingerprint
5. Download updated `google-services.json`
6. Replace the file in `android/app/`

#### 3. Update `android/build.gradle.kts`

Ensure you have:

```kotlin
dependencies {
    classpath("com.android.tools.build:gradle:8.1.0")
    classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.0")
    classpath("com.google.gms:google-services:4.3.15")
}
```

#### 4. Update `android/app/build.gradle.kts`

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
}
```

### iOS Setup (if applicable)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Add `GoogleService-Info.plist` to Runner target
3. Update `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

---

## 💳 Stripe Payment Setup

### 1. Create Stripe Account

1. Go to [Stripe](https://stripe.com/)
2. Sign up for an account
3. Get your API keys from Dashboard

### 2. Add Stripe Keys to Project

Update `lib/services/stripe_service.dart`:

```dart
class StripeService {
  static const String publishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY';
  static const String secretKey = 'sk_test_YOUR_SECRET_KEY';
  
  // Current keys in project (TEST MODE):
  // publishableKey: pk_test_51SUOpPEiM5oJLk5lcrkUY96KVNZb8yX2ueZrKMZ0KwpnJOa1A6fl0NTGuy9CfmgEiQFz7NgggLnMeL43O826aW3F00ATjMKG9g
  // secretKey: sk_test_51SUOpPEiM5oJLk5lQUcYSQs8tHoU0XmBj9Q2WrYdZGjdL6J0QNtX8YwjV6vTj35jVcO6AVv1DJ3bPtLj0VPmwSek0050aSA3dK
}
```

### 3. Initialize Stripe

In `main.dart`:

```dart
await Stripe.instance.applySettings();
```

### 4. Test Cards

For testing, use Stripe test cards:
- **Success**: `4242 4242 4242 4242`
- **Decline**: `4000 0000 0000 0002`
- Any future expiry date, any CVC

---

## 📁 Project Structure

```
spacia/
├── android/                    # Android native code
├── ios/                        # iOS native code
├── lib/
│   ├── admin/                  # Admin dashboard
│   │   ├── screens/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── products_screen.dart
│   │   │   ├── businesses_screen.dart
│   │   │   ├── orders_screen.dart
│   │   │   ├── requests_screen.dart
│   │   │   ├── notifications_screen.dart
│   │   │   ├── product_detail_screen.dart
│   │   │   └── order_detail_screen.dart
│   │   ├── widgets/
│   │   │   ├── admin_top_bar.dart
│   │   │   ├── admin_stat_card.dart
│   │   │   ├── admin_order_card.dart
│   │   │   └── admin_product_card.dart
│   │   └── admin_main_screen.dart
│   ├── business/               # Business dashboard
│   │   ├── screens/
│   │   │   ├── dashboard/
│   │   │   ├── orders/
│   │   │   ├── products/
│   │   │   ├── transactions/
│   │   │   └── profile/
│   │   ├── widgets/
│   │   │   ├── business_navbar.dart
│   │   │   └── business_top_bar.dart
│   │   └── business_main_screen.dart
│   ├── consumer/               # Consumer app
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── signup_user_screen.dart
│   │   │   │   └── signup_business_screen.dart
│   │   │   ├── home/
│   │   │   ├── products/
│   │   │   ├── cart/
│   │   │   ├── orders/
│   │   │   ├── profile/
│   │   │   └── settings/
│   │   └── main_navigation_screen.dart
│   ├── models/
│   │   ├── product_model.dart
│   │   ├── order_model.dart
│   │   └── user_model.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── stripe_service.dart
│   │   └── notification_service.dart
│   ├── widgets/
│   │   ├── custom_topbar.dart
│   │   └── custom_button.dart
│   ├── constants/
│   │   ├── app_colors.dart
│   │   └── app_sizes.dart
│   ├── firebase_options.dart
│   └── main.dart
├── assets/
│   ├── logo.jpg
│   ├── fonts/
│   └── images/
├── test/
├── pubspec.yaml
├── README.md
└── firebase.json
```

---

## 👥 User Roles

### 1. Consumer
- **Email**: Any valid email
- **Access**: Browse products, place orders, manage profile

### 2. Business Owner
- **Email**: Register via "Sign Up as Business Owner"
- **Access**: Product management, order fulfillment, analytics
- **Approval**: Requires admin approval before login

### 3. Admin
- **Email**: `admin@spacia.com`
- **Password**: `spacia.admin.123`
- **Access**: Full platform control, business approvals, analytics

---

## 🎨 Color Scheme

```dart
// Primary Colors
darkBrown: Color(0xFF6D4C41)
lightBrown: Color(0xFFF5E6D3)

// Status Colors
green: Colors.green.shade600      // Paid
blue: Colors.blue.shade600        // Completed
orange: Colors.orange.shade700    // Pending
red: Colors.red.shade600          // Cancelled
```

---

## 📱 Running the App

### Development Mode

```bash
# Run on connected device
flutter run

# Run on specific device
flutter devices
flutter run -d device_id

# Run with verbose logging
flutter run -v
```

### Build for Production

#### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

#### iOS
```bash
# Build for iOS
flutter build ios --release
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Google Sign-In Not Working
- **Solution**: Verify SHA-1 fingerprint is added to Firebase
- Re-download `google-services.json`
- Clean and rebuild project

#### 2. Firestore Permission Denied
- **Solution**: Update Firestore security rules
- Ensure user is authenticated

#### 3. Image Upload Fails
- **Solution**: Check Storage security rules
- Verify Firebase Storage is enabled
- Check internet connection

#### 4. Stripe Payment Fails
- **Solution**: Verify API keys are correct
- Use test card numbers for testing
- Check Stripe Dashboard for errors

#### 5. 3D Model Not Loading
- **Solution**: Verify model URL is valid
- Check internet connection
- Ensure `model_viewer_plus` is properly installed

### Clean Build

```bash
flutter clean
flutter pub get
flutter run
```

---

## 📊 Database Schema

### Collections

#### `users`
```javascript
{
  name: string,
  email: string,
  photoUrl: string,
  role: string,           // 'consumer' or 'admin'
  address: string,
  latitude: number,
  longitude: number,
  createdAt: timestamp
}
```

#### `businesses`
```javascript
{
  businessName: string,
  ownerName: string,
  email: string,
  address: string,
  businessAddress: string,
  businessPhone: string,
  password: string,
  approved: boolean,      // false until admin approves
  revenue: number,
  createdAt: timestamp
}
```

#### `products`
```javascript
{
  name: string,
  description: string,
  price: number,
  category: string,
  imageUrl: array,        // List of image URLs
  modelUrl: string,       // 3D model URL (optional)
  businessId: string,
  quantity: number,
  createdAt: timestamp
}
```

#### `orders`
```javascript
{
  userId: string,
  businessId: string,
  items: array,
  totalAmount: number,
  status: string,         // 'pending', 'paid', 'completed'
  deliveryAddress: string,
  latitude: number,
  longitude: number,
  createdAt: timestamp
}
```

#### `categories`
```javascript
{
  name: string,
  icon: string,
  createdAt: timestamp
}
```

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Coding Standards
- Follow Flutter/Dart style guide
- Use meaningful variable names
- Add comments for complex logic
- Write unit tests for new features

---

---

## 👨‍💻 Authors

- **Haris Bin Nasir** - *Initial work* - [YourGitHub](https://github.com/hbnasir23)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Stripe for payment processing
- Google Maps for location services
- All open-source contributors

---

## 📞 Support

For support, email hbansir23@gmail.com or create an issue in the GitHub repository.

---

## 🔮 Future Enhancements

- [ ] Real-time chat support
- [ ] Push notifications for order updates
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Wishlist functionality
- [ ] Product reviews and ratings
- [ ] Social media integration
- [ ] Inventory management alerts
- [ ] Automated email marketing

---

## 📈 Version History

- **v1.0.0** (Current)
  - Initial release
  - Three user roles (Consumer, Business, Admin)
  - Google Sign-In integration
  - Stripe payment processing
  - 3D model viewer
  - Order management
  - Product management

---

<div align="center">
  <p>Made with ❤️ using Flutter</p>
  <p>© 2025 Spacia. All rights reserved.</p>
</div>

