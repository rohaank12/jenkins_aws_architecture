#!/bin/bash

# --- Configuration Variables ---
# Set the path to your Jenkins home directory
JENKINS_HOME="/var/lib/jenkins" # Assuming this is correct
# S3 Bucket where backups will be stored
S3_BUCKET_NAME="wezvatech-jenkins-backup-88882527" # Your S3 bucket name
# Log file path
LOG_FILE="/var/log/jenkins_backup.log"

# --- Script Variables (DO NOT MODIFY) ---
TIMESTAMP=$(date -d "today" +"%Y%m%d%H%M%S")
BACKUP_ARCHIVE_NAME="jenkins-archive-${TIMESTAMP}.tar.gz"
# Use mktemp for a secure and unique temporary directory
TMP_BACKUP_DIR=$(mktemp -d "/tmp/jenkins_backup_XXXXXX")

# --- Functions ---

# Function to generate logs
log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to handle script exit (cleanup temp directory)
cleanup() {
  log_message "Cleaning up temporary directory: $TMP_BACKUP_DIR"
  rm -rf "$TMP_BACKUP_DIR"
}
trap cleanup EXIT # Ensure cleanup happens on exit, even on error

# Function to upload backup tar to S3 bucket
copyto_s3() {
  log_message "Uploading backup to s3://${S3_BUCKET_NAME}/${BACKUP_ARCHIVE_NAME}..."
  # Rely on IAM Role for AWS CLI authentication (BEST PRACTICE)
  # If you must use explicit keys, uncomment and provide them securely:
  # AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID_VAR}" AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY_VAR}" \
  aws s3 cp "${TMP_BACKUP_DIR}/${BACKUP_ARCHIVE_NAME}" "s3://${S3_BUCKET_NAME}/"
  local exitcode=$?
  if [ $exitcode -ne 0 ]; then
    log_message "ERROR: S3 upload failed with exit code $exitcode"
    return 1 # Indicate failure
  fi
  log_message "Successfully copied Jenkins backup tar to S3 bucket."
  return 0 # Indicate success
}

# --- Main Script Execution ---

log_message "--- Starting Jenkins Backup Process ---"

# Ensure Jenkins home directory exists
if [ ! -d "$JENKINS_HOME" ]; then
  log_message "ERROR: Jenkins home directory '$JENKINS_HOME' not found."
  exit 1
fi

# 1. Stop Jenkins for a consistent backup
log_message "Attempting to stop Jenkins service..."
sudo systemctl stop jenkins || { log_message "WARNING: Could not stop Jenkins service. Backup might be inconsistent."; }
# Give it a moment to stop
sleep 5

# 2. Perform the backup
log_message "Creating backup of Jenkins Home directory: $JENKINS_HOME"
pushd "$JENKINS_HOME" > /dev/null || { log_message "ERROR: Failed to change to Jenkins home directory. Exiting."; exit 1; }

# Exclude unnecessary directories like workspace and builds to keep backup small
# Adjust these excludes based on what you truly need for recovery
tar -czf "${TMP_BACKUP_DIR}/${BACKUP_ARCHIVE_NAME}" \
  --exclude="workspace" \
  --exclude="builds" \
  --exclude="plugins/*.jpi.pinned" \
  . # Backup the current directory ($JENKINS_HOME)

popd > /dev/null # Go back to original directory
local tar_exitcode=$?
if [ $tar_exitcode -ne 0 ]; then
  log_message "ERROR: Failed to create backup archive. Tar exit code: $tar_exitcode"
  exit 1
fi
log_message "Backup archive created: ${TMP_BACKUP_DIR}/${BACKUP_ARCHIVE_NAME}"

# 3. Upload to S3
if ! copyto_s3; then
  log_message "ERROR: S3 upload failed. Exiting."
  exit 1
fi

# 4. Start Jenkins after backup
log_message "Attempting to start Jenkins service..."
sudo systemctl start jenkins || { log_message "WARNING: Could not start Jenkins service after backup."; }
sleep 5 # Give it a moment to start

log_message "--- Jenkins Backup Process Completed ---"
exit 0
