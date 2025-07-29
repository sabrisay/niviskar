#!/bin/bash

# EC2 Security Scanner Deployment Script
# This script runs on the bastion host to deploy and execute security scans
# across multiple EC2 instances in private subnets

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/security_scan_results.log"
SECURITY_SCRIPT="security_scan.sh"  # Your security scanning script
IP_FILE="${SCRIPT_DIR}/private_ips.txt"  # File containing list of IPs
REMOTE_SCRIPT_PATH="/tmp/security_scan.sh"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
SSH_USER="ec2-user"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -o BatchMode=yes"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    local level="$1"
    shift
    local message="$*"
    echo -e "[${TIMESTAMP}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# Function to log with colors
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
    log "INFO" "$*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
    log "SUCCESS" "$*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
    log "WARNING" "$*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
    log "ERROR" "$*"
}

# Function to check if SSH agent is running and has keys
check_ssh_agent() {
    log_info "Checking SSH agent..."
    
    if [ -z "${SSH_AUTH_SOCK:-}" ]; then
        log_error "SSH agent is not running or SSH_AUTH_SOCK is not set"
        log_error "Make sure you've forwarded your SSH agent: ssh -A user@bastion-host"
        exit 1
    fi
    
    if ! ssh-add -l >/dev/null 2>&1; then
        log_error "No SSH keys found in agent"
        log_error "Make sure your ec2-user key is loaded in your local SSH agent"
        exit 1
    fi
    
    log_success "SSH agent is configured correctly"
}

# Function to check if IP file exists and is readable
check_ip_file() {
    if [ ! -f "${IP_FILE}" ]; then
        log_error "IP file '${IP_FILE}' not found"
        log_error "Please create the file with one IP address per line"
        exit 1
    fi
    
    if [ ! -r "${IP_FILE}" ]; then
        log_error "IP file '${IP_FILE}' is not readable"
        exit 1
    fi
    
    log_success "IP file found: ${IP_FILE}"
}

# Function to read and validate IP addresses from file
read_ip_addresses() {
    local ips=()
    local line_number=0
    
    while IFS= read -r line || [ -n "$line" ]; do
        ((line_number++))
        
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Remove leading/trailing whitespace
        line=$(echo "$line" | xargs)
        
        # Basic IP address validation (simple regex)
        if [[ $line =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            ips+=("$line")
        else
            log_warning "Invalid IP address on line ${line_number}: '$line' - skipping"
        fi
    done < "${IP_FILE}"
    
    if [ ${#ips[@]} -eq 0 ]; then
        log_error "No valid IP addresses found in ${IP_FILE}"
        exit 1
    fi
    
    log_success "Found ${#ips[@]} valid IP addresses in ${IP_FILE}"
    printf '%s\n' "${ips[@]}"
}

# Function to check if security script exists
check_security_script() {
    if [ ! -f "${SCRIPT_DIR}/${SECURITY_SCRIPT}" ]; then
        log_error "Security scanning script '${SECURITY_SCRIPT}' not found in ${SCRIPT_DIR}"
        log_error "Please ensure your security scanning script is present"
        exit 1
    fi
    log_success "Security scanning script found: ${SECURITY_SCRIPT}"
}
test_ssh_connection() {
    local host="$1"
    ssh ${SSH_OPTS} "${SSH_USER}@${host}" "echo 'SSH connection successful'" 2>/dev/null
}

# Function to copy security script to remote host
copy_script_to_host() {
    local host="$1"
    log_info "Copying security script to ${host}..."
    
    if scp ${SSH_OPTS} "${SCRIPT_DIR}/${SECURITY_SCRIPT}" "${SSH_USER}@${host}:${REMOTE_SCRIPT_PATH}"; then
        log_success "Successfully copied script to ${host}"
        return 0
    else
        log_error "Failed to copy script to ${host}"
        return 1
    fi
}

# Function to execute security script on remote host
execute_security_scan() {
    local host="$1"
    log_info "Executing security scan on ${host}..."
    
    # Make the script executable and run it
    if ssh ${SSH_OPTS} "${SSH_USER}@${host}" "chmod +x ${REMOTE_SCRIPT_PATH} && ${REMOTE_SCRIPT_PATH}"; then
        log_success "Security scan completed successfully on ${host}"
        return 0
    else
        log_error "Security scan failed on ${host}"
        return 1
    fi
}

# Function to cleanup remote script
cleanup_remote_script() {
    local host="$1"
    log_info "Cleaning up remote script on ${host}..."
    
    ssh ${SSH_OPTS} "${SSH_USER}@${host}" "rm -f ${REMOTE_SCRIPT_PATH}" 2>/dev/null || true
}

# Function to process a single host
process_host() {
    local host="$1"
    local host_log_file="${SCRIPT_DIR}/scan_${host}_$(date +%Y%m%d_%H%M%S).log"
    
    log_info "Processing host: ${host}"
    echo "==================== SCAN RESULTS FOR ${host} ====================" >> "${LOG_FILE}"
    
    # Test SSH connectivity
    if ! test_ssh_connection "${host}"; then
        log_error "Cannot establish SSH connection to ${host}"
        echo "ERROR: SSH connection failed to ${host}" >> "${LOG_FILE}"
        return 1
    fi
    
    # Copy security script
    if ! copy_script_to_host "${host}"; then
        echo "ERROR: Failed to copy script to ${host}" >> "${LOG_FILE}"
        return 1
    fi
    
    # Execute security scan and capture output
    {
        echo "--- Security Scan Results for ${host} ---"
        echo "Timestamp: $(date)"
        echo "Host: ${host}"
        echo ""
        
        if ssh ${SSH_OPTS} "${SSH_USER}@${host}" "chmod +x ${REMOTE_SCRIPT_PATH} && ${REMOTE_SCRIPT_PATH}" 2>&1; then
            echo ""
            echo "--- Scan completed successfully ---"
            log_success "Security scan completed for ${host}"
        else
            echo ""
            echo "--- Scan failed with errors ---"
            log_error "Security scan failed for ${host}"
        fi
    } >> "${host_log_file}" 2>&1
    
    # Append individual host results to main log
    cat "${host_log_file}" >> "${LOG_FILE}"
    echo "" >> "${LOG_FILE}"
    
    # Cleanup
    cleanup_remote_script "${host}"
    
    log_info "Results for ${host} saved to: ${host_log_file}"
}

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --file FILE       File containing list of IPs (default: private_ips.txt)"
    echo "  -s, --script SCRIPT   Security scanning script name (default: security_scan.sh)"
    echo "  -l, --log-file FILE   Log file path (default: security_scan_results.log)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Uses default private_ips.txt"
    echo "  $0 --file server_list.txt"
    echo "  $0 --script custom_scan.sh --file my_servers.txt"
    echo "  $0 -l /var/log/security_scan.log -f private_ips.txt"
    echo ""
    echo "IP File Format:"
    echo "  One IP address per line, empty lines and lines starting with # are ignored"
    echo "  Example:"
    echo "    10.0.1.10"
    echo "    10.0.1.11"
    echo "    # This is a comment"
    echo "    10.0.1.12"
    echo ""
    echo "Prerequisites:"
    echo "  - SSH agent must be running with ec2-user key loaded"
    echo "  - Connect to bastion with SSH agent forwarding: ssh -A user@bastion"
    echo "  - Security scanning script must be present in the same directory"
    echo "  - IP file must be present in the same directory"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                IP_FILE="$2"
                shift 2
                ;;
            -s|--script)
                SECURITY_SCRIPT="$2"
                shift 2
                ;;
            -l|--log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                usage
                exit 1
                ;;
            *)
                echo "Unexpected argument: $1" >&2
                echo "All IP addresses should be specified in the IP file." >&2
                usage
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    # Parse arguments
    parse_arguments "$@"
    
    # Perform pre-flight checks
    check_ssh_agent
    check_ip_file
    check_security_script
    
    # Read IP addresses from file
    local HOSTS=()
    mapfile -t HOSTS < <(read_ip_addresses)
    
    # Check if hosts were loaded
    if [ ${#HOSTS[@]} -eq 0 ]; then
        log_error "No valid hosts found in IP file"
        exit 1
    fi
    
    # Initialize log file
    echo "================== SECURITY SCAN SESSION START ==================" > "${LOG_FILE}"
    echo "Start Time: ${TIMESTAMP}" >> "${LOG_FILE}"
    echo "Bastion Host: $(hostname)" >> "${LOG_FILE}"
    echo "Target Hosts: ${HOSTS[*]}" >> "${LOG_FILE}"
    echo "IP File: ${IP_FILE}" >> "${LOG_FILE}"
    echo "Security Script: ${SECURITY_SCRIPT}" >> "${LOG_FILE}"
    echo "=================================================================" >> "${LOG_FILE}"
    echo "" >> "${LOG_FILE}"
    
    log_info "Starting security scan deployment for ${#HOSTS[@]} hosts"
    log_info "Results will be logged to: ${LOG_FILE}"
    
    # Perform pre-flight checks
    check_ssh_agent
    check_ip_file
    check_security_script
    
    # Process each host
    local success_count=0
    local failure_count=0
    
    for host in "${HOSTS[@]}"; do
        if process_host "${host}"; then
            ((success_count++))
        else
            ((failure_count++))
        fi
        echo "" # Add spacing between hosts
    done
    
    # Summary
    echo "==================== SCAN SESSION SUMMARY ====================" >> "${LOG_FILE}"
    echo "End Time: $(date '+%Y-%m-%d %H:%M:%S')" >> "${LOG_FILE}"
    echo "Total Hosts: ${#HOSTS[@]}" >> "${LOG_FILE}"
    echo "Successful Scans: ${success_count}" >> "${LOG_FILE}"
    echo "Failed Scans: ${failure_count}" >> "${LOG_FILE}"
    echo "=============================================================" >> "${LOG_FILE}"
    
    log_info "Scan deployment completed!"
    log_info "Summary: ${success_count} successful, ${failure_count} failed out of ${#HOSTS[@]} total hosts"
    
    if [ ${failure_count} -gt 0 ]; then
        log_warning "Some scans failed. Check the log file for details: ${LOG_FILE}"
        exit 1
    else
        log_success "All scans completed successfully!"
        exit 0
    fi
}

# Run main function with all arguments
main "$@"