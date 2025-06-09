
This script performs basic reconnaissance on a domain without subdomain enumeration. It includes:

- WHOIS lookup
- Reverse WHOIS lookup (using registrant email)
- DNS resolution
- Reverse IP lookup
- Certificate Transparency log analysis via crt.sh

## 🔧 Requirements

Make sure the following tools are installed:

- `whois`
- `dig`
- `nslookup`
- `curl`
- `jq`

You can install them on Debian/Ubuntu using:

```bash
sudo apt update && sudo apt install whois dnsutils curl jq
