# Sarf Flutter App — Setup Guide

## 1. Initialize the Flutter Project

Since this is a pre-built source, run inside C:\Users\rahma\Desktop\exchange:

```bash
# If you created this folder manually, first scaffold:
flutter create . --org com.sarf --platforms android,ios

# Then restore dependencies:
flutter pub get
```

## 2. API Base URL

Edit `lib/core/constants/app_constants.dart`:

| Environment | URL |
|---|---|
| Android Emulator | `http://10.0.2.2:4500` ✅ (default) |
| iOS Simulator | `http://localhost:4500` |
| Physical Device | `http://<YOUR_LOCAL_IP>:4500` |
| Production | `https://your-domain.com` |

## 3. Google Sign-In Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create OAuth 2.0 Client IDs for Android & iOS
3. Add `google-services.json` to `android/app/`
4. Add `GoogleService-Info.plist` to `ios/Runner/`

## 4. Run the App

```bash
flutter run
```

## 5. Project Structure

```
lib/
├── main.dart                        # Entry point + splash screen
├── core/
│   ├── constants/app_constants.dart # API URLs & keys
│   └── theme/app_theme.dart         # Colors, theme, gradients
├── data/
│   ├── models/auth_models.dart      # Request/response models
│   └── services/auth_service.dart   # All API calls + token storage
└── presentation/
    ├── auth/
    │   ├── login_page.dart          # Login with phone + Google
    │   ├── register_page.dart       # Registration form
    │   ├── otp_page.dart            # OTP verification
    │   └── widgets/
    │       ├── gradient_button.dart # Animated gold button
    │       └── glass_input.dart     # Styled text field
    └── home/
        └── home_page.dart           # Dashboard (post-login)
```

## 6. Auth Flow

```
App Launch → Splash (check token)
    ├── Token found → Home Page
    └── No token → Login Page
                      ├── Phone + Password → POST /api/auth/login
                      ├── Google → POST /api/auth/google
                      └── Create Account → Register Page
                                            ├── Fill form → POST /api/auth/request-otp
                                            └── OTP Page → POST /api/auth/register → Home Page
```
