# Client Device Setup

This directory contains scripts and configurations for setting up laptops, tablets, and mobile devices to interact with the infrastructure automation tools and environments.

## Overview

Infrastructure engineers and administrators need properly configured client devices to effectively manage cloud infrastructure. These scripts automate the setup process for different operating systems and device types, ensuring consistency and reducing the time needed to get started.

## Supported Devices

### Laptops/Desktops
- **Windows**: Full environment setup for Windows machines
- **macOS**: Complete development environment for macOS
- **Linux**: Command-line tools and basic configurations

### Mobile Devices
- **Android**: Limited management capabilities via terminal apps
- **iOS/iPadOS**: Monitoring and emergency maintenance access

## Setup Scripts

### Windows Setup
The Windows setup script (`windows-laptop-setup.ps1`) configures a Windows machine for infrastructure development and management.

**Features:**
- Installs essential development tools using Chocolatey
- Configures SSH for secure authentication
- Sets up Git with best practices
- Installs and configures AWS CLI
- Creates organized directory structure
- Installs VSCode with recommended extensions

**Usage:**
```powershell
# Run as Administrator
.\windows-laptop-setup.ps1

# Skip certain components
.\windows-laptop-setup.ps1 -SkipAWS -SkipGit

# Use custom installation path
.\windows-laptop-setup.ps1 -CustomInstallPath "D:\DevTools"
```

### macOS Setup
The macOS setup script (`macos-setup.sh`) prepares macOS systems for infrastructure management.

**Features:**
- Installs developer tools using Homebrew
- Configures Terminal and iTerm2
- Sets up SSH keys and agent
- Installs cloud CLI tools (AWS, Azure, GCP)
- Configures Git and global gitignore
- Installs VSCode with recommended extensions
- Applies recommended macOS settings

**Usage:**
```bash
# Make the script executable
chmod +x macos-setup.sh

# Run the script
./macos-setup.sh
```

### Mobile Device Setup
The mobile device setup script (`mobile-setup.sh`) helps configure mobile devices for infrastructure monitoring and management.

**Features:**
- Creates setup guides for different mobile platforms
- Configures backend services for mobile access
- Generates mobile access tokens
- Provides recommendations for secure mobile access

**Usage:**
```bash
# Generate Android setup guide
./mobile-setup.sh --platform android --action guide

# Generate iOS setup guide
./mobile-setup.sh --platform ios --action guide

# Configure backend for mobile access
./mobile-setup.sh --platform android --action config --api-host api.example.com

# Generate mobile access token
./mobile-setup.sh --platform ios --action token --api-host api.example.com
```

## Mobile-Friendly Services

These services are designed to work well on mobile devices:

1. **Monitoring Dashboard**: Responsive web interface for viewing infrastructure status
2. **Status Alerts**: Push notifications for critical infrastructure events
3. **SSH Terminal Access**: Emergency access via mobile SSH clients
4. **Infrastructure Controls**: Basic start/stop/restart operations via API
5. **Authentication**: Support for MFA and biometric authentication

## Security Considerations

When setting up mobile access to infrastructure:

1. **Enforce MFA**: Always require multi-factor authentication for mobile access
2. **Limited Permissions**: Grant mobile devices minimal required permissions
3. **Encrypted Connections**: Use VPN or encrypted connections for all mobile access
4. **Device Management**: Consider implementing MDM solutions for company devices
5. **Remote Wipe**: Enable remote wipe capabilities for lost devices
6. **Activity Logging**: Log all operations performed from mobile devices
7. **Session Timeouts**: Configure short session timeouts for mobile interfaces

## Best Practices

1. **Regular Updates**: Keep client devices and tools updated
2. **Configuration as Code**: Store device configurations in version control
3. **Standardization**: Use these scripts to ensure consistent environments
4. **Documentation**: Document any customizations made to the standard setup
5. **Backup**: Ensure key configuration files are backed up
6. **Testing**: Test scripts in a safe environment before using them widely

## Limitations

### Mobile Device Limitations

Mobile devices have significant limitations for infrastructure management:

- **Limited Computing Power**: Cannot run resource-intensive operations
- **Battery Constraints**: May not be reliable for long running tasks
- **Screen Size**: Difficult to view complex dashboards or logs
- **Connectivity Issues**: Mobile networks can be unreliable
- **OS Restrictions**: Mobile OS may restrict certain operations

For critical operations, always use properly configured laptops or workstations.

## Troubleshooting

Common issues and solutions for the setup scripts:

### Windows Setup Issues
- **PowerShell Permissions**: Ensure you're running as Administrator
- **Execution Policy**: You may need to set `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process`
- **Chocolatey Installation**: If Chocolatey fails to install, check network connection and try again

### macOS Setup Issues
- **Homebrew Permissions**: Fix with `sudo chown -R $(whoami) /usr/local/lib/pkgconfig`
- **Xcode Command Line Tools**: Install manually with `xcode-select --install` if needed
- **SSH Issues**: Ensure SSH agent is running with `eval $(ssh-agent -s)`

### Mobile Setup Issues
- **SSH Connection Problems**: Check network and verify keys are properly configured
- **App Permissions**: Ensure terminal apps have proper permissions on the device
- **Push Notifications**: Mobile OS may block notifications from web applications

## Contributing

To contribute improvements to these setup scripts:

1. Test your changes thoroughly on the target OS/device
2. Ensure scripts remain idempotent (can be run multiple times safely)
3. Document any new parameters or features
4. Update this README with new troubleshooting tips if applicable

## License

These scripts are provided under the same license as the main infrastructure automation repository. 