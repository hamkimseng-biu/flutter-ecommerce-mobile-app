# Flutter Firebase + Facebook Login Setup Guide

> Based on setting up `kh.edu.beltei.mad.e2` (Android) with Firebase project `beltei-b1b65` and Facebook App `1332833465649295`.

---

## 1. Firebase Setup

### 1.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **Add Project** → name it → disable Google Analytics (optional for dev)
3. Once created, go to **Project Settings**

### 1.2 Register Android App
1. In Firebase Console → **Project Settings** → **Add app** → **Android**
2. Enter your **Android package name** (must match `applicationId` in `android/app/build.gradle.kts`)
   ```
   kh.edu.beltei.mad.e2
   ```
3. Register app → download `google-services.json`
4. Place it in: `android/app/google-services.json`

### 1.3 Register iOS App (if needed)
1. **Add app** → **iOS**
2. Enter iOS Bundle ID (must match Xcode bundle identifier)
3. Download `GoogleService-Info.plist` → place in `ios/Runner/`

### 1.4 Run FlutterFire Configure
Generates `lib/firebase_options.dart` with all platform configs:

```bash
# Install CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure (run from project root)
export PATH="$PATH":"$HOME/.pub-cache/bin"
flutterfire configure --project=YOUR_PROJECT_ID --platforms=android,ios,web -y
```

### 1.5 Package Name Mismatch Warning
- `google-services.json` `package_name` **must match** `applicationId` in `build.gradle.kts`
- If they don't match → Firebase services will fail silently
- Re-run `flutterfire configure` after changing `applicationId`

---

## 2. Facebook Login Setup

### 2.1 Create Facebook App
1. Go to [Facebook Developers](https://developers.facebook.com)
2. **Create App** → choose **Consumer** type
3. Name your app → create

### 2.2 Configure Android Platform
1. In Facebook Developer Console → Your App → **Settings** → **Basic**
2. Scroll down → **+ Add Platform** → **Android**
3. Select **Google Play Store**
4. Fill in:

| Field | Value |
|-------|-------|
| **Google Play Package Name** | `kh.edu.beltei.mad.e2` |
| **Class Name** | `com.facebook.FacebookActivity` |
| **Key Hashes** | Generate using command below |

### 2.3 Generate Key Hash
```bash
keytool -exportcert -alias androiddebugkey \
  -keystore ~/.android/debug.keystore \
  -storepass android -keypass android 2>/dev/null \
  | openssl sha1 -binary | openssl base64
```
- **Debug** keystore: `~/.android/debug.keystore` (password: `android`)
- **Release** keystore: your own keystore file (different hash needed)

### 2.4 Add Facebook App Credentials to Project
Edit `android/app/src/main/res/values/strings.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="facebook_app_id">YOUR_APP_ID</string>
    <string name="facebook_client_token">YOUR_CLIENT_TOKEN</string>
</resources>
```
- **App ID**: From Facebook Dashboard (top of page)
- **Client Token**: Facebook Console → Settings → Advanced → Client Token (NOT the App Secret!)

### 2.5 Add Email Permission (Facebook Console)
1. Facebook Console → **App Review** → **Permissions and Features**
2. Find **email** → if missing, click **Add**
3. In Development mode, this is auto-granted for testers/admins

### 2.6 Add Test Users
1. Facebook Console → **App Roles** → **Roles**
2. **Add Testers** → enter their Facebook email/ID
3. Tester must accept invitation from Facebook notifications

---

## 3. Code Implementation

### 3.1 Dependencies (`pubspec.yaml`)
```yaml
dependencies:
  firebase_core: ^4.11.0
  firebase_auth: ^6.5.4
  flutter_facebook_auth: ^7.1.7
  shared_preferences: ^2.5.5
```

### 3.2 Initialize Firebase (`lib/main.dart`)
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const App());
}
```

### 3.3 Facebook Login with Email
```dart
Future<void> _facebookAuth() async {
  LoginResult result = await FacebookAuth.instance.login(
    permissions: ['public_profile', 'email'],  // MUST include email
  );
  if (result.status == LoginStatus.success) {
    OAuthCredential credential = FacebookAuthProvider.credential(
      result.accessToken!.tokenString,
    );
    final userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    // Get email (try Firebase first, then Facebook Graph API)
    String email = userCredential.user?.email ?? '';
    if (email.isEmpty) {
      final userData = await FacebookAuth.instance.getUserData(
        fields: 'email,name',
      );
      email = userData['email'] ?? '';
    }

    // Save to SharedPreferences
    final pref = await SharedPreferences.getInstance();
    await pref.setString('logged_in_email', email);
    await pref.setString('logged_in_name',
        userCredential.user?.displayName ?? 'Guest');

    Get.offAll(MainScreen());
  }
}
```

### 3.4 Logout
```dart
Future<void> logout() async {
  await FacebookAuth.instance.logOut();
  await FirebaseAuth.instance.signOut();
  await SharedPreferences.getInstance()
      .then((pref) => pref.clear());
  Get.offAll(StartupScreen());
}
```

---

## 4. Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| **App stuck on splash screen** | `firebase_options.dart` project ID doesn't match `google-services.json` | Run `flutterfire configure` |
| **"App not active: This app is not accessible right now"** | Facebook app in Development mode, user not a tester | Add user to App Roles → Testers |
| **"Given URL is not allowed by the Application configuration"** | Android platform not added to Facebook app | Add Android platform + package name + key hash |
| **"There was a problem verifying this package name"** | Facebook can't find package on Play Store | Just click **Save Changes** anyway — it works |
| **"Invalid Scopes: email"** | Email permission not configured in Facebook app | Add "email" under App Review → Permissions and Features |
| **Name shows "Guest" after login** | Name not saved to SharedPreferences during login | Save `displayName` to SharedPreferences on login success |
| **Email shows "Guest" / blank** | `email` permission not requested in Facebook login | Add `'email'` to `permissions` list |
| **SnackBar "Login success" but no navigation** | Navigation tied to SnackBar action button that auto-dismisses | Navigate directly after login, don't rely on SnackBar action |

---

## 5. Checklist for a New App

- [ ] Create Firebase project → add Android app → download `google-services.json`
- [ ] Place `google-services.json` in `android/app/`
- [ ] Run `flutterfire configure` to generate `firebase_options.dart`
- [ ] Create Facebook app → add Android platform
- [ ] Generate debug key hash → add to Facebook console
- [ ] Set `facebook_app_id` and `facebook_client_token` in `strings.xml`
- [ ] Add `email` permission in Facebook App Review settings
- [ ] Add yourself (and testers) to Facebook App Roles
- [ ] Request `['public_profile', 'email']` in Facebook login code
- [ ] Handle both login methods (email/password + Facebook) in account display
- [ ] Clear SharedPreferences on logout

---

## 6. Key Files Modified

```
android/app/
├── build.gradle.kts          # applicationId
├── google-services.json      # Firebase Android config
└── src/main/res/values/
    └── strings.xml           # Facebook App ID & Client Token

lib/
├── firebase_options.dart     # Auto-generated Firebase config
├── main.dart                 # Firebase.initializeApp()
├── screen/
│   ├── login_screen.dart     # Login + Facebook auth logic
│   ├── register_screen.dart  # Registration + name saving
│   └── account_screen.dart   # Display user name & email

ios/Runner/
└── GoogleService-Info.plist  # Firebase iOS config
```
