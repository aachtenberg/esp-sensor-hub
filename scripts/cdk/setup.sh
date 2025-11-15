#!/bin/bash

###############################################################################
#
# AWS CDK Setup & Deployment Script
# For ESP8266 Temperature Logger Dashboard
#
# Usage:
#   ./cdk/setup.sh                    # Interactive setup
#   ./cdk/setup.sh --bootstrap        # Bootstrap only
#   ./cdk/setup.sh --deploy          # Deploy dashboard
#   ./cdk/setup.sh --destroy         # Destroy resources
#
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 not found. Install with: sudo apt-get install python3"
        exit 1
    fi
    print_success "Python 3 found: $(python3 --version)"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_warning "Node.js not found. Installing..."
        sudo apt-get update && sudo apt-get install -y nodejs npm
    fi
    print_success "Node.js found: $(node --version)"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_warning "AWS CLI not found. Installing..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
        unzip /tmp/awscliv2.zip -d /tmp/
        sudo /tmp/aws/install
        rm -rf /tmp/awscliv2.zip /tmp/aws/
    fi
    print_success "AWS CLI found: $(aws --version)"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        echo "Run: aws configure"
        exit 1
    fi
    print_success "AWS credentials configured"
}

# Install CDK
install_cdk() {
    print_header "Installing AWS CDK"
    
    if ! command -v cdk &> /dev/null; then
        print_warning "AWS CDK not found. Installing..."
        npm install -g aws-cdk
    fi
    print_success "AWS CDK found: $(cdk --version)"
}

# Install Python dependencies
install_dependencies() {
    print_header "Installing Python Dependencies"
    
    if [ ! -f "cdk/requirements.txt" ]; then
        print_error "cdk/requirements.txt not found"
        exit 1
    fi
    
    pip install -r cdk/requirements.txt
    print_success "Dependencies installed"
}

# Bootstrap AWS account
bootstrap_account() {
    print_header "Bootstrapping AWS Account"
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    REGION=${AWS_REGION:-ca-central-1}
    
    print_warning "Using Account: $ACCOUNT_ID"
    print_warning "Using Region: $REGION"
    
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted"
        exit 1
    fi
    
    cdk bootstrap aws://$ACCOUNT_ID/$REGION
    print_success "Account bootstrapped"
}

# Deploy dashboard
deploy_dashboard() {
    print_header "Deploying CloudWatch Dashboard"
    
    cdk deploy --require-approval=never
    print_success "Dashboard deployed!"
    
    print_header "Dashboard Information"
    echo "View your dashboard:"
    echo "  AWS Console → CloudWatch → Dashboards → ESP8266-Temperature-Logger"
    echo ""
    echo "Or copy this URL:"
    REGION=${AWS_REGION:-ca-central-1}
    echo "  https://console.aws.amazon.com/cloudwatch/home?region=$REGION#dashboards:name=ESP8266-Temperature-Logger"
}

# Destroy resources
destroy_resources() {
    print_header "Destroying Dashboard Resources"
    
    print_warning "This will remove the dashboard and alarms"
    print_warning "Log group 'esp-sensor-logs' will be preserved"
    
    read -p "Are you sure? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted"
        exit 1
    fi
    
    cdk destroy --force
    print_success "Resources destroyed"
}

# Full setup
full_setup() {
    check_prerequisites
    install_cdk
    install_dependencies
    bootstrap_account
    deploy_dashboard
}

# Main logic
case "${1:-}" in
    --bootstrap)
        check_prerequisites
        install_cdk
        install_dependencies
        bootstrap_account
        ;;
    --deploy)
        check_prerequisites
        install_cdk
        install_dependencies
        deploy_dashboard
        ;;
    --destroy)
        destroy_resources
        ;;
    *)
        full_setup
        ;;
esac

print_header "✓ Complete!"
