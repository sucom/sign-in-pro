#!/usr/bin/env bash
set -e

echo "==================================================="
echo "    Local SSL Certificate Generator for Live Server"
echo "==================================================="

# 1. Verify OpenSSL is available
if ! command -v openssl >/dev/null 2>&1; then
    echo "[ERROR] 'openssl' command was not found in your PATH."
    echo "Please install OpenSSL before running this script."
    exit 1
fi

# 2. Determine target output directory
# Priority:
#  a) Current directory if it is named 'ssl'
#  b) Subdirectory './ssl' in current directory if it exists
#  c) Script directory if script is located inside an 'ssl' folder
#  d) Create './ssl' in current working directory
CUR_DIR="$(pwd)"
CUR_NAME="$(basename "$CUR_DIR")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PARENT_NAME="$(basename "$SCRIPT_DIR")"

if [ "$CUR_NAME" = "ssl" ]; then
    OUT_DIR="$CUR_DIR"
elif [ -d "$CUR_DIR/ssl" ]; then
    OUT_DIR="$CUR_DIR/ssl"
elif [ "$SCRIPT_PARENT_NAME" = "ssl" ]; then
    OUT_DIR="$SCRIPT_DIR"
else
    OUT_DIR="$CUR_DIR/ssl"
    mkdir -p "$OUT_DIR"
fi

# 3. Prompt for Hostname / Domain / IP
INPUT_HOST="${1:-}"
if [ -z "$INPUT_HOST" ]; then
    echo ""
    read -r -p "Enter Hostname / Domain / IP [default: 127.0.0.1]: " INPUT_HOST
fi

if [ -z "$INPUT_HOST" ]; then
    INPUT_HOST="127.0.0.1"
fi

# Trim any whitespace
INPUT_HOST="$(echo "$INPUT_HOST" | xargs)"

echo ""
echo "[*] Target Host: $INPUT_HOST"
echo "[*] Output Folder: $OUT_DIR"

# 4. Build Subject Alternative Name (SAN)
# Check if host is an IPv4 address
if [[ "$INPUT_HOST" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    if [ "$INPUT_HOST" = "127.0.0.1" ]; then
        SAN="IP:127.0.0.1,DNS:localhost"
    else
        SAN="IP:${INPUT_HOST},IP:127.0.0.1,DNS:localhost"
    fi
else
    if [ "$INPUT_HOST" = "localhost" ]; then
        SAN="DNS:localhost,IP:127.0.0.1"
    else
        SAN="DNS:${INPUT_HOST},DNS:localhost,IP:127.0.0.1"
    fi
fi

echo "[*] SAN Extension: $SAN"
echo ""

KEY_FILE="$OUT_DIR/${INPUT_HOST}.key"
CSR_FILE="$OUT_DIR/${INPUT_HOST}.csr"
CRT_FILE="$OUT_DIR/${INPUT_HOST}.crt"
SERVER_KEY="$OUT_DIR/server.key"
SERVER_CRT="$OUT_DIR/server.crt"

# 5. Generate Private Key and CSR
echo "[*] Step 1/3: Generating private key and CSR..."
openssl req -new -newkey rsa:2048 -nodes \
    -keyout "$KEY_FILE" \
    -out "$CSR_FILE" \
    -subj "/CN=${INPUT_HOST}" \
    -addext "subjectAltName=${SAN}"

# 6. Generate Self-Signed CRT (825 days validity)
echo "[*] Step 2/3: Signing self-signed certificate..."
openssl x509 -req -days 825 \
    -in "$CSR_FILE" \
    -signkey "$KEY_FILE" \
    -out "$CRT_FILE" \
    -copy_extensions copy

# Also create standard server.key and server.crt convenience copies
cp -f "$KEY_FILE" "$SERVER_KEY"
cp -f "$CRT_FILE" "$SERVER_CRT"

# 7. Add certificate to Windows Trusted Root store if certutil is available (Windows / Git Bash)
if command -v certutil.exe >/dev/null 2>&1; then
    echo ""
    echo "[*] Step 3/3: Adding certificate to Windows Trusted Root Certification Authorities store..."
    WIN_CRT_PATH="$(cygpath -w "$CRT_FILE" 2>/dev/null || echo "$CRT_FILE")"
    echo "[*] Executing: certutil.exe -addstore -f \"ROOT\" \"$WIN_CRT_PATH\""
    certutil.exe -addstore -f "ROOT" "$WIN_CRT_PATH" || {
        echo ""
        echo "[NOTE] Administrator permissions required to write to the System ROOT store."
        echo "Run in an Administrator prompt: certutil -addstore -f \"ROOT\" \"$WIN_CRT_PATH\""
    }
fi

echo ""
echo "==================================================="
echo "[SUCCESS] Local SSL Certificate Created Successfully!"
echo "==================================================="
echo "Host-specific files:"
echo "  - Key: $KEY_FILE"
echo "  - CSR: $CSR_FILE"
echo "  - CRT: $CRT_FILE"
echo ""
echo "Convenience standard files:"
echo "  - Key: $SERVER_KEY"
echo "  - CRT: $SERVER_CRT"
echo ""
echo "VS Code Live Server Configuration:"
echo ---------------------------------------------------
echo "Add this to your .vscode/settings.json:"
echo ""
echo "{"
echo "  \"liveServer.settings.https\": {"
echo "    \"enable\": true,"
echo "    \"cert\": \"./ssl/server.crt\","
echo "    \"key\": \"./ssl/server.key\","
echo "    \"passphrase\": \"\""
echo "  }"
echo "}"
echo "==================================================="
echo ""
