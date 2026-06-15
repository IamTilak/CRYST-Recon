#!/bin/bash

set -euo pipefail

START_TIME=$(date +%s)

# ==========================================
# CRYST FAST RECON
# ==========================================

echo "====================================================="
echo "   ██████╗██████╗ ██╗   ██╗███████╗████████╗"
echo "  ██╔════╝██╔══██╗╚██╗ ██╔╝██╔════╝╚══██╔══╝"
echo "  ██║     ██████╔╝ ╚████╔╝ ███████╗   ██║"
echo "  ██║     ██╔══██╗  ╚██╔╝  ╚════██║   ██║"
echo "  ╚██████╗██║  ██║   ██║   ███████║   ██║"
echo "   ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝   ╚═╝"
echo ""
echo "        Fast Bug Bounty Recon Framework"
echo "                 By CRYST 🔥"
echo "====================================================="

# Check input
if [ $# -ne 1 ]; then
    echo ""
    echo "Usage: ./PowerRecon.sh example.com"
    exit 1
fi

DOMAIN=$1

# Check required tools
echo ""
echo "[+] Checking Required Tools..."

TOOLS=(
    subfinder
    assetfinder
    httpx
    katana
    gau
    waybackurls
    gf
)

for tool in "${TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "[!] Missing tool: $tool"
        exit 1
    fi
done

echo "[+] All Required Tools Found"

# Create output directory
mkdir -p "$DOMAIN"
cd "$DOMAIN"

# ==========================================
# SUBDOMAIN ENUMERATION
# ==========================================

echo ""
echo "[+] Starting Subdomain Enumeration..."

subfinder -d "$DOMAIN" -all -recursive -silent -o subfinder.txt

assetfinder --subs-only "$DOMAIN" 2>/dev/null > assetfinder.txt

cat subfinder.txt assetfinder.txt 2>/dev/null \
| grep -E "^[a-zA-Z0-9._-]+\.[a-zA-Z]{2,}$" \
| sort -u > subs.txt

echo "[+] Total Subdomains Found: $(wc -l < subs.txt)"

# ==========================================
# LIVE HOST DETECTION
# ==========================================

echo ""
echo "[+] Checking Live Hosts..."

httpx -l subs.txt -silent -threads 100 -o live.txt >/dev/null 2>&1

echo "[+] Live Hosts Found: $(wc -l < live.txt)"

# ==========================================
# URL COLLECTION
# ==========================================

echo ""
echo "[+] Collecting URLs..."

touch katana.txt gau.txt wayback.txt

katana -list live.txt -silent -o katana.txt >/dev/null 2>&1

gau --threads 50 < subs.txt > gau.txt 2>/dev/null

waybackurls < subs.txt > wayback.txt

cat katana.txt gau.txt wayback.txt | sort -u > urls.txt

echo "[+] Total URLs Collected: $(wc -l < urls.txt)"

# ==========================================
# PARAMETER EXTRACTION
# ==========================================

echo ""
echo "[+] Extracting Parameters..."

grep "=" urls.txt | sort -u > params.txt || true

echo "[+] Parameter URLs Found: $(wc -l < params.txt)"

# ==========================================
# JAVASCRIPT FILES
# ==========================================

echo ""
echo "[+] Extracting JavaScript Files..."

grep -Ei "\.js(\?|$)" urls.txt | sort -u > js-files.txt || true

echo "[+] JavaScript Files Found: $(wc -l < js-files.txt)"

# ==========================================
# SENSITIVE FILES
# ==========================================

echo ""
echo "[+] Searching For Sensitive Files..."

grep -Ei "\.(env|json|sql|bak|log|yaml|yml|gz|zip|rar|config|xml|txt)(\?|$)" urls.txt \
| sort -u > sensitive-files.txt || true

echo "[+] Sensitive Files Found: $(wc -l < sensitive-files.txt)"

# ==========================================
# GF PATTERNS
# ==========================================

echo ""
echo "[+] Running GF Pattern Matching..."

mkdir -p gf-results

gf xss < urls.txt > gf-results/xss.txt || true
gf sqli < urls.txt > gf-results/sqli.txt || true
gf ssrf < urls.txt > gf-results/ssrf.txt || true
gf lfi < urls.txt > gf-results/lfi.txt || true
gf redirect < urls.txt > gf-results/redirect.txt || true

echo "[+] GF Pattern Matching Completed"
echo ""
echo "[+] XSS Candidates: $(wc -l < gf-results/xss.txt)"
echo "[+] SQLi Candidates: $(wc -l < gf-results/sqli.txt)"
echo "[+] SSRF Candidates: $(wc -l < gf-results/ssrf.txt)"
echo "[+] LFI Candidates: $(wc -l < gf-results/lfi.txt)"
echo "[+] Redirect Candidates: $(wc -l < gf-results/redirect.txt)"

# ==========================================
# FINAL OUTPUT
# ==========================================

echo ""
echo "====================================================="
echo "           CRYST Recon Completed 🚀"
echo "====================================================="
echo ""

echo "Generated Files:"
echo ""
echo "subs.txt                -> All Subdomains"
echo "live.txt                -> Live Hosts"
echo "urls.txt                -> Collected URLs"
echo "params.txt              -> URLs With Parameters"
echo "js-files.txt            -> JavaScript Files"
echo "sensitive-files.txt     -> Sensitive Files"
echo "gf-results/             -> GF Pattern Results"
echo ""
echo "[+] Total URLs: $(wc -l < urls.txt)"
echo "[+] Total Parameters: $(wc -l < params.txt)"
echo "[+] Total JS Files: $(wc -l < js-files.txt)"
echo "[+] Total Sensitive Files: $(wc -l < sensitive-files.txt)"
echo ""

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "[+] Recon completed in ${MINUTES}m ${SECONDS}s"
echo ""
echo "[+] Happy Hunting 🔥"
                            
