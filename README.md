# Easy Winget Manager

**Easy Winget Manager** is a high-performance, secure, and modern GUI for the Windows Package Manager (`winget`). Built with **Flutter** and **Rust**, it provides a seamless experience for managing your applications with enterprise-grade security and speed.

## 🚀 Features

*   **⚡ High Performance**: Core logic implemented in Rust for lightning-fast package parsing and system interaction.
*   **🛡️ Trusted Filter**: Toggleable security layer that highlights packages from verified publishers (Microsoft, Google, GitHub, etc.).
*   **🔒 Secure Transfer**: Export and import your package lists using AES-256-GCM encrypted `.ewm` files.
*   **🔄 Modern UI/UX**: A clean, responsive dashboard with sidebar navigation and real-time status updates.
*   **📦 Comprehensive Management**: 
    *   List and uninstall installed applications.
    *   Scan and batch-upgrade available updates.
    *   Search and install new software from the official Winget repository.
*   **🛰️ Privacy First**: Zero telemetry, no tracking, and no external logging. Your data stays on your machine.

## 🛠️ Tech Stack

*   **Frontend**: [Flutter](https://flutter.dev) (Material 3)
*   **Backend**: [Rust](https://www.rust-lang.org)
*   **Bridge**: [flutter_rust_bridge v2](https://github.com/fzyzcjy/flutter_rust_bridge)
*   **Encryption**: AES-256-GCM (Rust `aes-gcm` crate)
*   **State Management**: Provider

## 📋 Prerequisites

*   **Windows 10/11**
*   **Flutter SDK** (Latest stable)
*   **Rust Toolchain** (Latest stable)
*   **LLVM/Clang** (Required for bridge generation)

## 🔨 Development & Build

1.  **Clone the Repository**
    ```powershell
    git clone https://github.com/mrerduran/EasyWingetManager.git
    cd EasyWingetManager
    ```

2.  **Install Dependencies**
    ```powershell
    flutter pub get
    ```

3.  **Generate Bridge Code** (If changes are made to Rust API)
    ```powershell
    flutter_rust_bridge_codegen generate
    ```

4.  **Run the Application**
    ```powershell
    flutter run -d windows
    ```

## 🔒 Security

This application implements several security best practices:
- **AES-256-GCM**: Industry-standard encryption for exported package lists.
- **Dynamic Parsing**: Robust parsing of Winget output to prevent injection or corruption.
- **Trusted Publisher Verification**: Built-in filtering for well-known software vendors.

## 📄 License

This project is licensed under the **Apache License 2.0**. See the [LICENSE](LICENSE) file for details.

## ✍️ Author

**Ogulcan Erduran**  
🌐 [https://ogulcan.me](https://ogulcan.me)
