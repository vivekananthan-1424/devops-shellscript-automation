# Deployment Flow Documentation

This document explains the deployment workflow used in the automation script.

The deployment process ensures safe and reliable website deployment by including backup, rollback and notifications.

---

# 1. Developer Initiates Deployment

The process starts when the developer runs the deployment script.

Example:

./Deploy_Staticwebsite.sh

The script automates all required steps including server setup, deployment, and validation.

---

# 2. Environment Variables Loading

The script loads configuration variables from the `.env` file.

These variables include:

- Slack webhook URL
- Email recipients for notifications

This ensures sensitive information is not hardcoded in the script.

---

# 3. OS Detection

The script detects the Linux distribution using:

/etc/os-release

Supported operating systems:

- Ubuntu
- Debian
- CentOS
- RHEL

This allows the script to install packages using the correct package manager.

---

# 4. Package Installation

The script installs required dependencies:

- wget
- unzip
- zip
- mailutils

Web servers installed:

- NGINX
- Apache

---

# 5. Template Download

The website template is automatically downloaded from the configured URL.

Example source:

https://www.tooplate.com

The template is extracted inside the temporary working directory.

---

# 6. Backup Creation

Before deployment begins, the existing website is backed up.

Backup includes:

- Copy of the current web root
- Compressed backup archive
- Timestamp-based backup naming

Only the latest 5 backups are retained to save disk space.

---

# 7. Website Deployment

The new website files are copied to the web root directory:

/var/www/html

Existing files are replaced with the new deployment files.

---

# 8. Rollback Mechanism

If deployment fails, the script automatically performs rollback.

Rollback steps:

1. Identify the latest backup
2. Extract backup archive
3. Restore website files to web root

This ensures the website remains available even if deployment fails.

---

# 9. Web Server Restart

After deployment, the script restarts the active web server.

Supported servers:

- NGINX
- Apache

This ensures the new content is served immediately.

---



---

# 10. Notifications

Deployment status notifications are sent via:

- Slack webhook
- Email

Notifications include:

- Deployment success
- Deployment failure
- Rollback status

---

# 11. Logging

All deployment activity is logged into a timestamped log file.

Logs include:

- Package installation status
- Deployment steps
- Errors
- Rollback actions

This helps troubleshooting and auditing deployments.

---

# Summary

The deployment workflow ensures reliable automation by including:

- Automated installation
- Backup protection
- Rollback mechanism
- Notifications
- Detailed logging