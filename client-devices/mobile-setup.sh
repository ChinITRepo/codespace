#!/bin/bash
# Mobile Device Setup Script
# This script generates configuration guides for mobile devices
# and prepares backend services to support mobile access.

set -e

# Default values
PLATFORM="android"
ACTION="guide"
OUTPUT_DIR="guides"
API_HOST=""
DASHBOARD_URL=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --platform)
      PLATFORM="$2"
      shift
      shift
      ;;
    --action)
      ACTION="$2"
      shift
      shift
      ;;
    --output)
      OUTPUT_DIR="$2"
      shift
      shift
      ;;
    --api-host)
      API_HOST="$2"
      shift
      shift
      ;;
    --dashboard-url)
      DASHBOARD_URL="$2"
      shift
      shift
      ;;
    --generate-guide)
      ACTION="guide"
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --platform PLATFORM      Platform type: android, ios, web (default: android)"
      echo "  --action ACTION          Action to perform: guide, config, token (default: guide)"
      echo "  --output DIR             Output directory for guides (default: guides)"
      echo "  --api-host HOST          API hostname for mobile access"
      echo "  --dashboard-url URL      Dashboard URL for mobile access"
      echo "  --generate-guide         Generate setup guide (same as --action guide)"
      echo "  --help                   Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to generate setup guide for Android
generate_android_guide() {
  cat > "$OUTPUT_DIR/android-setup-guide.md" << EOL
# Android Setup Guide for Infrastructure Automation

This guide will help you set up your Android device for infrastructure monitoring and management.

## Requirements

- Android 8.0 or higher
- Google Play Store access
- Reliable internet connection
- Device with biometric or strong authentication

## Step 1: Install Required Apps

1. **Termux** - For terminal access
   - Install from [F-Droid](https://f-droid.org/en/packages/com.termux/) (recommended) or [Google Play](https://play.google.com/store/apps/details?id=com.termux)
   - After installation, open Termux and run:
   \`\`\`bash
   pkg update
   pkg install openssh git
   \`\`\`

2. **JuiceSSH** or **Connectbot** - For SSH connections
   - [JuiceSSH on Google Play](https://play.google.com/store/apps/details?id=com.sonelli.juicessh)
   - [ConnectBot on Google Play](https://play.google.com/store/apps/details?id=org.connectbot)

3. **Authy** or **Google Authenticator** - For MFA
   - [Authy on Google Play](https://play.google.com/store/apps/details?id=com.authy.authy)
   - [Google Authenticator on Google Play](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2)

## Step 2: Configure SSH Keys

1. Generate SSH keys (if not already done):
   \`\`\`bash
   # In Termux
   ssh-keygen -t ed25519 -C "android-device"
   cat ~/.ssh/id_ed25519.pub
   \`\`\`

2. Add your public key to the infrastructure's authorized keys

3. Test SSH connection:
   \`\`\`bash
   ssh username@${API_HOST:-your-bastion-host.example.com}
   \`\`\`

## Step 3: Access Web Dashboard

1. Open your browser and navigate to:
   ${DASHBOARD_URL:-https://dashboard.example.com}

2. Save the dashboard as a home screen shortcut:
   - Tap menu (three dots)
   - Select "Add to Home screen"

## Step 4: Configure Notifications

1. Install and configure the infrastructure monitoring app
2. Enable notifications in Android settings
3. Test that alerts are coming through properly

## Security Recommendations

1. Enable device encryption
2. Use biometric authentication or strong PIN/password
3. Enable remote wipe capabilities
4. Keep all apps updated
5. Use a VPN when accessing infrastructure remotely
6. Set up automatic screen lock (1-2 minutes)
7. Don't store infrastructure credentials in cloud backups

## Limitations

Remember that mobile devices have limitations when managing infrastructure:

- Limited ability to run complex scripts or tools
- Mobile connections can be unstable
- Battery life considerations
- Screen size constraints
- OS restrictions on background processes

For critical infrastructure tasks, always use a laptop or workstation when possible.
EOL

  echo "Generated Android setup guide: $OUTPUT_DIR/android-setup-guide.md"
}

# Function to generate setup guide for iOS
generate_ios_guide() {
  cat > "$OUTPUT_DIR/ios-setup-guide.md" << EOL
# iOS/iPadOS Setup Guide for Infrastructure Automation

This guide will help you set up your iOS device for infrastructure monitoring and management.

## Requirements

- iOS 14.0 or higher (iOS 15+ recommended)
- App Store access
- Reliable internet connection
- Device with biometric or strong authentication

## Step 1: Install Required Apps

1. **Blink Shell** - For terminal and SSH access
   - Install from [App Store](https://apps.apple.com/us/app/blink-shell-mosh-ssh-client/id1156707581)
   - Alternative: [Termius](https://apps.apple.com/us/app/termius-ssh-client/id549039908)

2. **Working Copy** - Git client for iOS
   - Install from [App Store](https://apps.apple.com/us/app/working-copy-git-client/id896694807)

3. **Authy** or **Google Authenticator** - For MFA
   - [Authy on App Store](https://apps.apple.com/us/app/authy/id494168017)
   - [Google Authenticator on App Store](https://apps.apple.com/us/app/google-authenticator/id388497605)

## Step 2: Configure SSH Keys

1. In Blink Shell, generate SSH keys:
   \`\`\`bash
   ssh-keygen -t ed25519 -C "ios-device"
   cat ~/.ssh/id_ed25519.pub
   \`\`\`

2. Add your public key to the infrastructure's authorized keys

3. Configure host in Blink:
   - Go to Settings > Hosts
   - Add new host with your bastion server details
   - Use the generated key

## Step 3: Set Up Shortcuts

1. Install the [Shortcuts app](https://apps.apple.com/us/app/shortcuts/id915249334) if not already included
2. Import the infrastructure management shortcuts:
   - Open Safari and visit: ${DASHBOARD_URL:-https://dashboard.example.com}/shortcuts
   - Follow the prompts to add the shortcuts

## Step 4: Access Web Dashboard

1. Open Safari and navigate to:
   ${DASHBOARD_URL:-https://dashboard.example.com}

2. Add to Home Screen:
   - Tap the Share button
   - Select "Add to Home Screen"
   - Name it "Infrastructure Dashboard"

## Step 5: Configure Notifications

1. Enable notifications for the dashboard in Safari:
   - Settings > Safari > Advanced > Website Data
   - Find your dashboard site and enable notifications

2. Enable Critical Alerts if available

## Security Recommendations

1. Enable device encryption (on by default in iOS)
2. Use Face ID/Touch ID or strong passcode
3. Enable "Find My" for remote wipe capabilities
4. Keep iOS and all apps updated
5. Use a VPN when accessing infrastructure remotely
6. Set auto-lock to 1 minute or less
7. Don't store infrastructure credentials in iCloud

## Limitations

Remember that iOS devices have limitations when managing infrastructure:

- Limited ability to run background processes
- App Store restrictions on certain types of tools
- iOS sandbox limitations
- Battery life considerations
- Limited multitasking capabilities

For critical infrastructure tasks, always use a laptop or workstation when possible.
EOL

  echo "Generated iOS setup guide: $OUTPUT_DIR/ios-setup-guide.md"
}

# Function to generate API access tokens for mobile devices
generate_access_token() {
  if [ -z "$API_HOST" ]; then
    echo "Error: --api-host is required for token generation"
    exit 1
  fi
  
  # In a real implementation, this would call your API to generate a token
  # For this example, we'll just create a placeholder
  
  TOKEN_FILE="$OUTPUT_DIR/mobile-access-token.txt"
  DEVICE_ID=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1)
  TIMESTAMP=$(date +%s)
  PLACEHOLDER_TOKEN="mobile_${PLATFORM}_${DEVICE_ID}_${TIMESTAMP}"
  
  echo "$PLACEHOLDER_TOKEN" > "$TOKEN_FILE"
  echo "IMPORTANT: In a real implementation, this would call your authentication API."
  echo "Generated placeholder access token: $TOKEN_FILE"
}

# Function to configure backend for mobile access
configure_backend() {
  if [ -z "$API_HOST" ]; then
    echo "Error: --api-host is required for backend configuration"
    exit 1
  fi
  
  echo "Configuring backend services for mobile access..."
  echo "NOTE: In a real implementation, this would:"
  echo "  1. Create mobile-specific API endpoints"
  echo "  2. Configure CORS for mobile browsers"
  echo "  3. Set up push notification services"
  echo "  4. Update API rate limits for mobile clients"
  echo "  5. Configure monitoring for mobile client connections"
  
  # Create a configuration file with the settings
  cat > "$OUTPUT_DIR/mobile-backend-config.json" << EOL
{
  "api_host": "${API_HOST}",
  "dashboard_url": "${DASHBOARD_URL:-https://dashboard.example.com}",
  "platform": "${PLATFORM}",
  "allowed_endpoints": [
    "/api/v1/status",
    "/api/v1/alerts",
    "/api/v1/services/control",
    "/api/v1/auth"
  ],
  "rate_limits": {
    "requests_per_minute": 60,
    "burst": 10
  },
  "push_notifications": {
    "enabled": true,
    "providers": ["fcm", "apns"]
  }
}
EOL

  echo "Generated mobile backend configuration: $OUTPUT_DIR/mobile-backend-config.json"
}

# Main logic
echo "Mobile Device Setup - Platform: $PLATFORM, Action: $ACTION"

case "$ACTION" in
  "guide")
    echo "Generating setup guide for $PLATFORM..."
    if [ "$PLATFORM" == "android" ]; then
      generate_android_guide
    elif [ "$PLATFORM" == "ios" ]; then
      generate_ios_guide
    else
      echo "Unsupported platform: $PLATFORM. Valid options are: android, ios"
      exit 1
    fi
    ;;
  "token")
    echo "Generating access token for $PLATFORM device..."
    generate_access_token
    ;;
  "config")
    echo "Configuring backend for $PLATFORM access..."
    configure_backend
    ;;
  *)
    echo "Unknown action: $ACTION. Valid options are: guide, token, config"
    exit 1
    ;;
esac

echo "Mobile setup complete!" 