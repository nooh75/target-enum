#!/bin/bash

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

# Output directory
OUTPUT_DIR="recon_output"

# Check if required tools are installed
check_tools() {
    REQUIRED_TOOLS=("whois" "dig" "nslookup" "curl" "jq")
    MISSING_TOOLS=()

    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            MISSING_TOOLS+=("$tool")
        fi
    done

    if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
        echo -e "${RED}[✘] Missing required tools:${NC} ${MISSING_TOOLS[*]}"
        echo -e "${YELLOW}[!] Please install them and try again.${NC}"
        exit 1
    fi
}

# WHOIS lookup
whois_lookup() {
    local domain=$1
    echo -e "${BLUE}[*] Performing WHOIS lookup for $domain${NC}"
    mkdir -p "$OUTPUT_DIR/whois"
    whois "$domain" > "$OUTPUT_DIR/whois/whois_$domain.txt"

    # Extract valuable information
    grep -Ei "registrant|admin|tech|name server|creation date|expiration date|updated date|organization|email" \
        "$OUTPUT_DIR/whois/whois_$domain.txt" > "$OUTPUT_DIR/whois/whois_${domain}_important.txt"

    echo -e "${GREEN}[+] WHOIS results saved to $OUTPUT_DIR/whois/whois_$domain.txt${NC}"
}

# Reverse WHOIS lookup using registrant email
reverse_whois() {
    local domain=$1
    echo -e "${BLUE}[*] Performing reverse WHOIS lookup for $domain${NC}"

    local email=$(grep -i "registrant email" "$OUTPUT_DIR/whois/whois_$domain.txt" | awk '{print $NF}' | head -1)

    if [ -z "$email" ]; then
        echo -e "${YELLOW}[-] No registrant email found in WHOIS, skipping reverse WHOIS${NC}"
        return
    fi

    echo -e "${BLUE}[*] Querying viewdns.info for reverse WHOIS using email: $email${NC}"
    curl -s "https://viewdns.info/reversewhois/?q=$email" -o "$OUTPUT_DIR/whois/reverse_whois_$domain.html"

    echo -e "${GREEN}[+] Reverse WHOIS results saved to $OUTPUT_DIR/whois/reverse_whois_$domain.html${NC}"
}

# DNS and reverse IP lookup
dns_lookup() {
    local domain=$1
    echo -e "${BLUE}[*] Performing DNS lookups for $domain${NC}"
    mkdir -p "$OUTPUT_DIR/dns"

    nslookup "$domain" > "$OUTPUT_DIR/dns/nslookup_$domain.txt"

    local ip=$(dig +short "$domain" | head -1)

    if [ -z "$ip" ]; then
        echo -e "${YELLOW}[-] Could not resolve IP address for $domain${NC}"
        return
    fi

    echo -e "${BLUE}[*] Performing reverse IP lookup for $ip${NC}"
    curl -s "https://viewdns.info/reverseip/?host=$ip" -o "$OUTPUT_DIR/dns/reverse_ip_$domain.html"

    echo -e "${GREEN}[+] DNS and reverse IP results saved${NC}"
}

# Certificate transparency logs check (crt.sh)
cert_transparency() {
    local domain=$1
    echo -e "${BLUE}[*] Checking certificate transparency logs for $domain${NC}"
    mkdir -p "$OUTPUT_DIR/dns"

    curl -s "https://crt.sh/?q=${domain}&output=json" | jq . > "$OUTPUT_DIR/dns/cert_sh_${domain}.json" 2>/dev/null

    jq -r '.[].name_value' "$OUTPUT_DIR/dns/cert_sh_${domain}.json" 2>/dev/null | tr '\n' '\n' | sort -u \
        > "$OUTPUT_DIR/dns/crtsh_$domain.txt"

    echo -e "${GREEN}[+] Certificate transparency results saved to $OUTPUT_DIR/dns/crtsh_$domain.txt${NC}"
}

# Separator
separator() {
    echo -e "${YELLOW}------------------------------------------------------------${NC}"
}

# Usage banner
banner() {
    echo -e "${BLUE}Usage: $0 <domain>${NC}"
    echo -e "${YELLOW}Example: $0 example.com${NC}"
}

# Main execution
main() {
    if [ "$#" -ne 1 ]; then
        banner
        exit 1
    fi

    local domain=$1
    mkdir -p "$OUTPUT_DIR"
    check_tools
    separator
    whois_lookup "$domain"
    reverse_whois "$domain"
    separator
    dns_lookup "$domain"
    separator
    cert_transparency "$domain"
    separator
}

main "$@"
