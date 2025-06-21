#!/bin/bash

# Trivy Security Scanner for Docker Compose Images
# This script extracts all images from docker-compose.yml and scans them for vulnerabilities

set -e

COMPOSE_FILE="docker-compose.yml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$PROJECT_DIR/security-reports"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔒 Trivy Security Scanner for Docker Compose${NC}"
echo "=================================================="

# Check if trivy is installed
if ! command -v trivy &> /dev/null; then
    echo -e "${RED}❌ Trivy is not installed. Please install it first:${NC}"
    echo "   curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin"
    exit 1
fi

# Check if docker-compose.yml exists
if [ ! -f "$PROJECT_DIR/$COMPOSE_FILE" ]; then
    echo -e "${RED}❌ docker-compose.yml not found in $PROJECT_DIR${NC}"
    exit 1
fi

# Create reports directory
mkdir -p "$REPORTS_DIR"

echo -e "${BLUE}📋 Extracting images from $COMPOSE_FILE...${NC}"

# Extract images from docker-compose.yml using simpler grep/sed approach
IMAGES=$(cd "$PROJECT_DIR" && grep -E "^\s*image:\s*" "$COMPOSE_FILE" | sed 's/.*image:\s*//' | sed 's/["\x27]//g' | sed 's/\s*$//' | sort | uniq)

# Extract services that have build directive - simpler approach
BUILT_SERVICES=$(cd "$PROJECT_DIR" && python3 -c "
import yaml
with open('$COMPOSE_FILE', 'r') as f:
    data = yaml.safe_load(f)
    services = data.get('services', {})
    for name, config in services.items():
        if isinstance(config, dict) and 'build' in config:
            print(name)
" 2>/dev/null || echo "")

if [ -z "$IMAGES" ] && [ -z "$BUILT_SERVICES" ]; then
    echo -e "${RED}❌ No images found in $COMPOSE_FILE${NC}"
    exit 1
fi

# Function to scan an image
scan_image() {
    local image="$1"
    local report_file="$2"
    
    echo -e "${YELLOW}🔍 Scanning $image...${NC}"
    
    # Run trivy scan with multiple output formats
    trivy image \
        --format table \
        --severity HIGH,CRITICAL \
        --no-progress \
        "$image" | tee "$report_file.txt"
    
    # Generate JSON report for automation
    trivy image \
        --format json \
        --severity HIGH,CRITICAL \
        --no-progress \
        "$image" > "$report_file.json" 2>/dev/null
    
    # Count vulnerabilities
    local critical_count=$(cat "$report_file.json" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' 2>/dev/null || echo "0")
    local high_count=$(cat "$report_file.json" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' 2>/dev/null || echo "0")
    
    echo -e "${BLUE}📊 Summary for $image:${NC}"
    echo -e "   Critical: ${RED}$critical_count${NC}"
    echo -e "   High: ${YELLOW}$high_count${NC}"
    echo ""
    
    return 0
}

echo -e "${GREEN}🐳 Found the following images to scan:${NC}"

# List all images to be scanned
echo "Direct images from compose file:"
for image in $IMAGES; do
    echo "  - $image"
done

# Check for built images
if [ -n "$BUILT_SERVICES" ]; then
    echo "Built images (need to be built first):"
    for service in $BUILT_SERVICES; do
        local_image="$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]')_$service"
        echo "  - $local_image (from service: $service)"
    done
fi

echo ""
read -p "Do you want to continue with the scan? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Scan cancelled."
    exit 0
fi

# Build images first if they don't exist
if [ -n "$BUILT_SERVICES" ]; then
    echo -e "${BLUE}🔨 Building local images...${NC}"
    cd "$PROJECT_DIR"
    docker-compose build --no-cache
    echo ""
fi

# Scan direct images from registry
for image in $IMAGES; do
    report_file="$REPORTS_DIR/$(echo "$image" | tr '/' '_' | tr ':' '_')"
    scan_image "$image" "$report_file"
done

# Scan built images
if [ -n "$BUILT_SERVICES" ]; then
    for service in $BUILT_SERVICES; do
        local_image="$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]')_$service"
        
        # Check if image exists
        if docker image inspect "$local_image" >/dev/null 2>&1; then
            report_file="$REPORTS_DIR/$(echo "$local_image" | tr '/' '_' | tr ':' '_')"
            scan_image "$local_image" "$report_file"
        else
            echo -e "${RED}❌ Built image $local_image not found. Try running 'docker-compose build' first.${NC}"
        fi
    done
fi

# Generate summary report
echo -e "${BLUE}📋 Generating summary report...${NC}"
summary_file="$REPORTS_DIR/security-summary.txt"

cat > "$summary_file" << EOF
Security Scan Summary
====================
Generated: $(date)
Project: $(basename "$PROJECT_DIR")

Images Scanned:
EOF

# Add summary for each image
for image in $IMAGES; do
    report_file="$REPORTS_DIR/$(echo "$image" | tr '/' '_' | tr ':' '_')"
    if [ -f "$report_file.json" ]; then
        critical_count=$(cat "$report_file.json" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' 2>/dev/null || echo "0")
        high_count=$(cat "$report_file.json" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' 2>/dev/null || echo "0")
        echo "- $image: Critical: $critical_count, High: $high_count" >> "$summary_file"
    fi
done

if [ -n "$BUILT_SERVICES" ]; then
    for service in $BUILT_SERVICES; do
        local_image="$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]')_$service"
        report_file="$REPORTS_DIR/$(echo "$local_image" | tr '/' '_' | tr ':' '_')"
        if [ -f "$report_file.json" ]; then
            critical_count=$(cat "$report_file.json" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' 2>/dev/null || echo "0")
            high_count=$(cat "$report_file.json" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' 2>/dev/null || echo "0")
            echo "- $local_image: Critical: $critical_count, High: $high_count" >> "$summary_file"
        fi
    done
fi

echo -e "${GREEN}✅ Security scan completed!${NC}"
echo -e "${BLUE}📁 Reports saved to: $REPORTS_DIR${NC}"
echo -e "${BLUE}📄 Summary: $summary_file${NC}"

# Display summary
echo ""
echo -e "${BLUE}📊 Security Summary:${NC}"
cat "$summary_file"