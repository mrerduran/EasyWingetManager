# Easy Winget Manager

**Easy Winget Manager** is a lightweight, privacy-focused, open-source GUI for the Windows Package Manager (`winget`). Built with Electron, it allows you to easily manage your installed applications, check for updates, and discover new verified packages—all from a clean, modern interface.

## Features

*   **🛡️ Verified Sources Only**: Strictly interacts with the official `winget` repository to ensure safety.
*   **✅ Verified Publishers**: Filters out unverified or unknown packages; only displays software with valid Publisher IDs (e.g., `Microsoft.VisualStudioCode`).
*   **🔄 One-Click Updates**: Automatically scans for updates and lets you upgrade packages individually.
*   **📦 Package Management**: View all installed `winget` packages and uninstall them with ease.
*   **🔍 Search**: Find and install new software from verified publishers.
*   **🚀 Auto-Loading**: Data loads automatically when you switch tabs—no manual refresh needed.
*   **🔒 Privacy Focused**: Zero telemetry, no logging, and no tracking. Your data stays on your machine.

## Prerequisites

*   **Windows 11** (or Windows 10 with App Installer)
*   **Node.js** (v14 or higher)
*   **npm** (usually comes with Node.js)

## Installation & Running Locally

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/mrerduran/EasyWingetManager.git
    cd easy-winget-manager
    ```

2.  **Install Dependencies**
    ```bash
    npm install
    ```

3.  **Start the Application**
    ```bash
    npm start
    ```

## Author

**Ogulcan Erduran**  
🌐 [https://ogulcan.me](https://ogulcan.me)

## License

This project is licensed under the **Apache License 2.0**. See the [LICENSE](LICENSE) file for details.
