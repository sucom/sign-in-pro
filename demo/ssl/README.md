# Local SSL Certificate Generator for VS Code Live Server

This folder contains automated scripts to quickly generate self-signed SSL certificates (`.key`, `.csr`, `.crt`) and automatically register them with the Windows Trusted Root store.

---

## 🚀 Quick Usage

### Windows (`ssl-cert.cmd`)
From command line:
```cmd
# Run interactively (prompts for hostname, defaults to 127.0.0.1)
ssl\ssl-cert.cmd

# Or specify the hostname directly as an argument
ssl\ssl-cert.cmd 127.0.0.1
ssl\ssl-cert.cmd xyz.demo.local
```

> **Pro Tip**: If you run `ssl-cert.cmd` from an **Administrator** command prompt, it will automatically install the certificate into the **Windows Trusted Root Certification Authorities** store using `certutil -addstore -f "ROOT"`, giving you a trusted green padlock in browsers immediately without manual steps.

### Linux / macOS / Git Bash (`ssl-cert.sh`)
```bash
chmod +x ssl/ssl-cert.sh

# Run interactively:
./ssl/ssl-cert.sh

# Or specify the hostname directly:
./ssl/ssl-cert.sh 127.0.0.1
./ssl/ssl-cert.sh xyz.demo.local
```

---

## ⚙️ Steps Executed by the Script

1. **Key & CSR Generation**: RSA 2048-bit key and Certificate Signing Request with Subject Alternative Names (SAN).
2. **Certificate Signing**: Signs the certificate using OpenSSL with 825 days validity.
3. **Windows Root Store Registration**: Automatically runs:
   ```cmd
   certutil -addstore -f "ROOT" "<hostname>.crt"
   ```
4. **Convenience Copies**: Synchronizes `server.key` and `server.crt` so `.vscode/settings.json` never needs to change.

---

## 📂 Output Files

| File | Purpose |
| :--- | :--- |
| `<host>.key` | Host-specific private key (RSA 2048-bit, unencrypted) |
| `<host>.csr` | Host-specific Certificate Signing Request (CSR) |
| `<host>.crt` | Host-specific self-signed Certificate (825 days validity) |
| `server.key` | Convenience copy of the private key |
| `server.crt` | Convenience copy of the certificate |

---

## 🌐 Running From a Common `bin` Folder

You can copy or move `ssl-cert.cmd` / `ssl-cert.sh` into your personal `bin` directory (e.g. `C:\Users\kr\bin` or `~/bin`) that is in your system `PATH`:

The scripts automatically detect the target output directory using the following logic:
1. If the current working folder is named `ssl`, files are written to `.`
2. If a `./ssl` folder exists in your project root, files are written to `./ssl/`
3. If no `ssl` folder exists, the script automatically creates `./ssl/` in your current working folder and places all certificates inside it.

This means you can simply open any project in terminal and type:
```bash
ssl-cert
```
and it will create the `./ssl/` directory with certificates for that project!

---

## ⚙️ VS Code Live Server Configuration

Pre-configured in [`.vscode/settings.json`](file:///e:/_kProjects/extensions+/signInPro/demo-app/.vscode/settings.json):

```json
{
  "liveServer.settings.https": {
    "enable": true,
    "cert": "./ssl/server.crt",
    "key": "./ssl/server.key",
    "passphrase": ""
  }
}
```
