#!/bin/bash
# ----------------------------------------------------------------------------
# Script Name: Deploy_Staticwebsite.sh
# Description: This script deploys a static website to an local machine as first
# Purpose: Deploy website template to local machine with backup,rollback,slack/email notifications, logging and cron ready
# ----------------------------------------------------------------------------

#-----------------------VARIABLES-----------------------
WEB_ROOT="/var/www/html"
TMP_DIR="/tmp/New_Template"
TEMPLATE_URL="https://www.tooplate.com/zip-templates/2108_dashboard.zip"
TEMPLATE_FOLDER="2108_dashboard"
BACKUP_DIR="$TMP_DIR/website_backup_$(date +%Y%m%d%H%M%S)"
LOG_FILE="$TMP_DIR/deploy_website_$(date +%Y%m%d%H%M%S).log"
MAX_BACKUPS=5
TIMESTAMP=$(date +%Y%m%d-%H%M%S)


#-----------------------FUNCTIONS-----------------------

#Load environment variables from .env file
if [ -f .env ]; then
    source .env
    echo "Environment variables loaded from .env file."
else
    echo "No .env file found. Please create a .env file with the required variables."
    exit 1
    #export $(grep -v '^#' .env | xargs)
fi

# Function to log messages with timestamps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" #---- Keeping the square brackets for better readability of logs and tee to log both to file and console and -a to append logs to the file instead of overwriting it.
}

# Function to send Slack notifications
send_slack() {
    local message="$1"
    curl -s -X POST -H 'Content-type: application/json' \
         --data "{\"text\":\"$message\"}" "$SLACK_WEBHOOK_URL" > /dev/null
}

# Function to send email notifications
send_email() {
    local subject="$1"
    local body="$2"
    echo "$body" | mail -s "$subject" "$EMAIL_RECIPIENTS"
}

# Detect OS for pacakge installation
detect_os() {
    if [[ -f /etc/os-release ]]; then
       . /etc/os-release
       echo "$ID"
    else
       echo "not found"
       fi       
}

# Function to install required packages
install_packages() {
    for pkg in "$@"; do
        OS=$(detect_os)
        case $OS in
            ubuntu|debian)
                 sudo apt-get update -y
                 sudo apt-get install -y "$pkg"
                 ;;
            centos|rhel)
                 sudo dnf install -y "$pkg"
                 ;;
            *)
                 log "Unsupported OS: $OS"
                 exit 1
                 ;;
        esac
        log "Installed package: $pkg"
    done
}

#---------------- Start Deployment ------------------------

log "----------- Starting Deployment ---------------------------"

# Step 1: Install required packages
log "Installing required packages..."

install_packages wget unzip zip mailutils

#step 2: Create Necessary Directories
log "Folder created for backup and temporary files"

mkdir -p "$TMP_DIR"
mkdir -p "$BACKUP_DIR"

# Step 3 : Download and unzip the template
log "Downloading website template from $TEMPLATE_URL"

#cd "$TMP_DIR"
wget -O "$TMP_DIR/template.zip" "$TEMPLATE_URL"
unzip -o "$TMP_DIR/template.zip" -d "$TMP_DIR"

log "Template downloaded and extracted to $TMP_DIR"

#------------ Backup existing website ----------------
log "Backing up existing website from $WEB_ROOT to $BACKUP_DIR"
if [ -d "$WEB_ROOT" ]; then
    cp -r "$WEB_ROOT" "$BACKUP_DIR/backup_$TIMESTAMP"
    zip -r "$BACKUP_DIR/backup_$TIMESTAMP.zip" "$BACKUP_DIR/backup_$TIMESTAMP"
    rm -rf "$BACKUP_DIR/backup_$TIMESTAMP"
    log "Backup completed and saved to $BACKUP_DIR/backup_$TIMESTAMP.zip"
else
    log "No existing website found at $WEB_ROOT, skipping backup."
    
    #keep only the latest 5 backups
    cd "$BACKUP_DIR"
    ls -1t | tail -n +$(($MAX_BACKUPS + 1)) | xargs -d '\n' rm -rf --
    log "Old backups removed, keeping only the latest $MAX_BACKUPS backups."
fi

#------------ Deploy new website ----------------

log "Deploying new website to $WEB_ROOT"
rm -rf "$WEB_ROOT"/*
if cp -r "$TMP_DIR/$TEMPLATE_FOLDER/"* "$WEB_ROOT"; then
    log "Admin_Dashboard deployed successfully to ($hostname)"
    send_slack "Admin_Dashboard deployed successfully to ($hostname)"
    send_email "Admin_Dashboard Deployment Success" "The website has been successfully deployed to $WEB_ROOT."
else
    log "Deployment failed!! Rolling back to previous version from backup."
    #Rollback to previous version
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.zip | head -n 1)
    unzip -o "$LATEST_BACKUP" -d "$WEB_ROOT"
    send_slack "Website deployment failed for ($hostname)"
    send_email "Website Deployment Failure" "Failed to deploy the website to ($hostname). Please check the logs for details."
    exit 1
fi

# ----------- Restart web server (Nginx/apache2) ---------------
if systemctl list units --type=service | grep -q nginx; then
    systemctl restart nginx
    log "Nginx web server restarted successfully."
elif systemctl list-units --type=service | grep -q apache2; then
    systemctl restart apache2
    log "Apache web server restarted successfully."
else
    log "No supported web server found to restart."
fi

log "Deployment completed successfully."


