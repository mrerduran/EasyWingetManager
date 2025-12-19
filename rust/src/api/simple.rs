use std::process::Command;
use anyhow::Result;
use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce
};

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct WingetPackage {
    pub name: String,
    pub id: String,
    pub version: String,
    pub available_version: Option<String>,
    pub source: Option<String>,
}

async fn run_winget_command(args: &[&str]) -> Result<Vec<WingetPackage>> {
    // Force UTF-8 output for winget if possible by setting console code page
    #[cfg(windows)]
    let _ = Command::new("cmd").args(["/c", "chcp 65001"]).output();

    let output = Command::new("winget")
        .args(args)
        .output();

    match output {
        Ok(out) => {
            let stdout = String::from_utf8_lossy(&out.stdout);
            if !out.status.success() {
                let stderr = String::from_utf8_lossy(&out.stderr);
                if !stdout.is_empty() {
                    return Ok(parse_winget_output(&stdout));
                }
                return Err(anyhow::anyhow!("Winget command failed: {} {}", stdout, stderr));
            }
            Ok(parse_winget_output(&stdout))
        }
        Err(e) => Err(anyhow::anyhow!("Failed to execute winget: {}", e)),
    }
}

pub async fn list_packages() -> Result<Vec<WingetPackage>> {
    run_winget_command(&["list", "--source", "winget", "--accept-source-agreements"]).await
}

pub async fn list_updatable_packages() -> Result<Vec<WingetPackage>> {
    run_winget_command(&["upgrade", "--source", "winget", "--accept-source-agreements"]).await
}

pub async fn search_packages(query: String) -> Result<Vec<WingetPackage>> {
    run_winget_command(&["search", &query, "--source", "winget", "--accept-source-agreements"]).await
}

pub async fn install_package(id: String) -> bool {
    let mut retries = 0;
    const MAX_RETRIES: u32 = 2;

    while retries <= MAX_RETRIES {
        let status = Command::new("winget")
            .args(["install", "--id", &id, "--silent", "--accept-package-agreements", "--accept-source-agreements"])
            .status();

        match status {
            Ok(s) if s.success() => return true,
            _ => {
                retries += 1;
                if retries <= MAX_RETRIES {
                    tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
                }
            }
        }
    }
    false
}

pub async fn uninstall_package(id: String) -> bool {
    let status = Command::new("winget")
        .args(["uninstall", "--id", &id, "--silent", "--accept-source-agreements"])
        .status();

    match status {
        Ok(s) => s.success(),
        Err(_) => false,
    }
}

pub async fn upgrade_package(id: String) -> bool {
    let mut retries = 0;
    const MAX_RETRIES: u32 = 2;

    while retries <= MAX_RETRIES {
        let status = Command::new("winget")
            .args(["upgrade", "--id", &id, "--silent", "--accept-package-agreements", "--accept-source-agreements"])
            .status();

        match status {
            Ok(s) if s.success() => return true,
            _ => {
                retries += 1;
                if retries <= MAX_RETRIES {
                    tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
                }
            }
        }
    }
    false
}

pub async fn install_packages(ids: Vec<String>) -> Vec<bool> {
    let mut results = Vec::new();
    for id in ids {
        results.push(install_package(id).await);
    }
    results
}

pub fn export_packages(packages: Vec<WingetPackage>, file_path: String) -> Result<()> {
    let json = serde_json::to_string(&packages)?;
    let key_bytes = b"EasyWingetManager_Key_32Chars_!!"; // 32 bytes
    let cipher = Aes256Gcm::new_from_slice(key_bytes).map_err(|e| anyhow::anyhow!("Invalid key: {}", e))?;
    
    let mut nonce_bytes = [0u8; 12];
    rand::RngCore::fill_bytes(&mut rand::thread_rng(), &mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);
    
    let encrypted = cipher.encrypt(nonce, json.as_bytes())
        .map_err(|e| anyhow::anyhow!("Encryption failed: {}", e))?;
    
    let mut data = Vec::with_capacity(nonce_bytes.len() + encrypted.len());
    data.extend_from_slice(&nonce_bytes);
    data.extend_from_slice(&encrypted);
    
    std::fs::write(file_path, data)?;
    Ok(())
}

pub fn import_packages(file_path: String) -> Result<Vec<WingetPackage>> {
    let data = std::fs::read(file_path)?;
    if data.len() < 12 {
        return Err(anyhow::anyhow!("Invalid file format"));
    }
    
    let key_bytes = b"EasyWingetManager_Key_32Chars_!!";
    let cipher = Aes256Gcm::new_from_slice(key_bytes).map_err(|e| anyhow::anyhow!("Invalid key: {}", e))?;
    
    let (nonce_bytes, encrypted) = data.split_at(12);
    let nonce = Nonce::from_slice(nonce_bytes);
    
    let decrypted = cipher.decrypt(nonce, encrypted)
        .map_err(|e| anyhow::anyhow!("Decryption failed: {}", e))?;
    
    let json = String::from_utf8(decrypted)?;
    let packages: Vec<WingetPackage> = serde_json::from_str(&json)?;
    Ok(packages)
}

fn parse_winget_output(output: &str) -> Vec<WingetPackage> {
    let mut packages = Vec::new();
    let lines: Vec<&str> = output.lines().collect();
    
    if lines.is_empty() {
        return packages;
    }

    // 1. Find the header line
    let header_keywords = ["Name", "Id", "Version", "Ad", "Kimlik", "Sürüm", "İsim"];
    let mut header_idx = None;
    for (i, line) in lines.iter().enumerate() {
        let matches = header_keywords.iter().filter(|&&k| line.contains(k)).count();
        if matches >= 2 {
            header_idx = Some(i);
            break;
        }
    }

    let h_idx = match header_idx {
        Some(idx) => idx,
        None => {
            // If no header found, maybe it's a simple list or search with no results
            return packages;
        }
    };

    let header_line = lines[h_idx];
    
    // 2. Determine column boundaries dynamically from header line
    let find_col = |keywords: &[&str]| -> Option<usize> {
        for &k in keywords {
            if let Some(byte_pos) = header_line.find(k) {
                // Return character position instead of byte position for correct slicing
                return Some(header_line[..byte_pos].chars().count());
            }
        }
        None
    };

    let name_start = find_col(&["Name", "Ad", "İsim"]).unwrap_or(0);
    let id_start = find_col(&["Id", "Kimlik"]).unwrap_or(30);
    let version_start = find_col(&["Version", "Sürüm"]).unwrap_or(60);
    let available_start = find_col(&["Available", "Kullanılabilir"]).unwrap_or(80);
    let source_start = find_col(&["Source", "Kaynak"]).unwrap_or(100);

    let mut boundaries = vec![
        name_start,
        id_start,
        version_start,
        available_start,
        source_start,
    ];
    boundaries.sort();
    boundaries.push(999); // End of last column

    // 3. Parse data lines
    for line in &lines[h_idx + 1..] {
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with('-') || trimmed.starts_with('—') || trimmed.starts_with('+') {
            continue;
        }

        let mut cols = Vec::new();
        for i in 0..boundaries.len() - 1 {
            let start = boundaries[i];
            let end = boundaries[i + 1];
            cols.push(safe_char_substring(line, start, end).trim().to_string());
        }

        // Map columns back to fields based on their original positions
        let mut name = String::new();
        let mut id = String::new();
        let mut version = String::new();
        let mut available = String::new();
        let mut source = String::new();

        for (i, &start) in boundaries.iter().enumerate().take(boundaries.len() - 1) {
            let val = cols[i].clone();
            if start == name_start { name = val; }
            else if start == id_start { id = val; }
            else if start == version_start { version = val; }
            else if start == available_start { available = val; }
            else if start == source_start { source = val; }
        }

        if !name.is_empty() && !id.is_empty() {
            packages.push(WingetPackage {
                name,
                id,
                version: version.clone(),
                available_version: if available.is_empty() || available == version || available.contains("---") { None } else { Some(available) },
                source: if source.is_empty() || source.contains("---") { None } else { Some(source) },
            });
        }
    }

    // 4. Fallback: If no packages found with fixed-width, try a simpler split-based approach
    if packages.is_empty() && lines.len() > h_idx + 1 {
        for line in &lines[h_idx + 1..] {
            let trimmed = line.trim();
            if trimmed.is_empty() || trimmed.starts_with('-') || trimmed.starts_with('—') {
                continue;
            }
            
            let parts: Vec<&str> = trimmed.splitn(3, "  ").filter(|s| !s.trim().is_empty()).collect();
            if parts.len() >= 2 {
                let name = parts[0].trim().to_string();
                let remaining = parts[1].trim();
                let remaining_parts: Vec<&str> = remaining.split_whitespace().collect();
                
                if remaining_parts.len() >= 2 {
                    packages.push(WingetPackage {
                        name,
                        id: remaining_parts[0].to_string(),
                        version: remaining_parts[1].to_string(),
                        available_version: remaining_parts.get(2).map(|s| s.to_string()),
                        source: remaining_parts.get(3).map(|s| s.to_string()),
                    });
                }
            }
        }
    }

    packages
}

fn safe_char_substring(s: &str, start: usize, end: usize) -> String {
    let char_count = s.chars().count();
    if start >= char_count || start >= end {
        return String::new();
    }
    let actual_end = std::cmp::min(end, char_count);
    s.chars().skip(start).take(actual_end - start).collect()
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
