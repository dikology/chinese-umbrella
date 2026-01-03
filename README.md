# Chinese Umbrella

A Chinese learning app built with SwiftUI that helps users learn Chinese characters through OCR and interactive reading.

## Setup

### Prerequisites

- Xcode 15.0+
- Ruby 3.1+ (for fastlane)
- iOS 17.0+ device/simulator

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/dikology/chinese-umbrella.git
   cd chinese-umbrella
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Open the project in Xcode:
   ```bash
   open umbrella/umbrella.xcodeproj
   ```

## Fastlane Setup

This project uses fastlane for automated testing and deployment to TestFlight.

### Local Development

1. Install Ruby dependencies:
   ```bash
   bundle install
   ```

2. Run tests:
   ```bash
   bundle exec fastlane test
   ```

3. Build locally (development export):
   ```bash
   bundle exec fastlane build_local
   ```

### Code Signing Setup

This project uses [match](https://docs.fastlane.tools/actions/match/) for code signing. To set up code signing:

1. Create a private certificates repository (or use existing one)
2. Set up the following environment variables:
   - `MATCH_GIT_URL`: URL to your certificates repository
   - `MATCH_PASSWORD`: Password for encrypted certificates
   - `MATCH_GIT_BRANCH`: Branch in certificates repo (default: main)

3. For local development, you can also set:
   - `EXPORT_METHOD`: Set to "development" for dev builds

### TestFlight Deployment

#### Manual Deployment

1. Ensure you have the required environment variables set
2. Run the beta lane:
   ```bash
   bundle exec fastlane beta
   ```

#### CI/CD Deployment

The project includes a GitHub Actions workflow that automatically deploys to TestFlight when:

- A commit message contains `[deploy]` and is pushed to main branch, OR
- The workflow is manually triggered

### Required Secrets for CI/CD

Add these secrets to your GitHub repository:

#### App Store Connect API Key (Recommended)
- `APP_STORE_CONNECT_API_KEY_ID`: Your API key ID
- `APP_STORE_CONNECT_ISSUER_ID`: Your issuer ID
- `APP_STORE_CONNECT_API_KEY_CONTENT`: The full content of your .p8 file

#### Match (Code Signing)
- `MATCH_GIT_TOKEN`: GitHub personal access token for certificates repo
- `MATCH_PASSWORD`: Password for encrypted certificates
- `MATCH_GIT_BRANCH`: Branch in certificates repo (optional, defaults to master)

#### Keychain (for CI)
- `MATCH_KEYCHAIN_PASSWORD`: Password for temporary CI keychain

#### Fallback (Username/Password - less secure)
- `FASTLANE_USER`: Your Apple ID email
- `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`: App-specific password

### Available Fastlane Lanes

- `test`: Run the test suite
- `build`: Build and archive for TestFlight (app-store export)
- `build_local`: Build and archive for development (development export)
- `beta`: Build and upload to TestFlight
- `screenshots`: Capture App Store screenshots
- `upload_screenshots`: Upload screenshots to App Store Connect
- `ci`: Run tests and deploy to TestFlight if conditions met

### Troubleshooting

#### Common Issues

1. **Certificate not found**: Ensure your certificates repository is set up correctly and `MATCH_GIT_URL` points to it.

2. **API Key issues**: Verify that your App Store Connect API key has the correct permissions and the content is properly formatted.

3. **Provisioning profile issues**: Make sure the bundle identifier `com.dikology.umbrella` is registered in your Apple Developer account.

4. **Keychain issues in CI**: The CI workflow creates a temporary keychain for code signing.

#### Getting Help

- Check fastlane output for detailed error messages
- Use `FASTLANE_VERBOSE=true` for more detailed logging
- Ensure Xcode Command Line Tools are installed: `xcode-select --install`

## Project Structure

- `umbrella/`: Main iOS application
  - `umbrella/`: Source code
    - `Data/`: Data layer (Core Data models, repositories)
    - `Domain/`: Business logic (entities, use cases)
    - `Infrastructure/`: External services and utilities
    - `Presentation/`: SwiftUI views and view models
    - `Resources/`: Static assets and data files
  - `umbrellaTests/`: Unit tests
  - `umbrellaUITests/`: UI tests
- `fastlane/`: Fastlane configuration
- `.github/workflows/`: GitHub Actions CI/CD

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `bundle exec fastlane test`
5. Submit a pull request

## License

See LICENSE file for details.