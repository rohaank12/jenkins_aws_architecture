#!/bin/bash

# Enable verbose logging for debugging
set -x

# --- Configuration Variables ---
JENKINS_HOME="/var/lib/jenkins"
S3_BUCKET_NAME="wezvatech-jenkins-backup-88882527"
LOG_FILE="/var/log/jenkins_backup.log"

# --- Script Variables (DO NOT MODIFY) ---
TIMESTAMP=$(date -d "today" +"%Y%m%d%H%M%S")
BACKUP_ARCHIVE_NAME="jenkins-archive-${TIMESTAMP}.tar.gz"
TMP_BACKUP_DIR=$(mktemp -d "/tmp/jenkins_backup_XXXXXX")

# --- Functions ---
log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

cleanup() {
  log_message "Cleaning up temporary directory: $TMP_BACKUP_DIR"
  rm -rf "$TMP_BACKUP_DIR"
}
trap cleanup EXIT # Ensure cleanup happens on exit, even on error

copyto_s3() {
  log_message "Uploading backup to s3://${S3_BUCKET_NAME}/${BACKUP_ARCHIVE_NAME}..."
  # AWS CLI will automatically pick up AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
  # from the environment variables set by withCredentials in the Jenkinsfile.
  aws s3 cp "${TMP_BACKUP_DIR}/${BACKUP_ARCHIVE_NAME}" "s3://${S3_BUCKET_NAME}/"
  local exitcode=$?
  if [ $exitcode -ne 0 ]; then
    log_message "ERROR: S3 upload failed with exit code $exitcode"
    return 1
  fi
  log_message "Successfully copied Jenkins backup tar to S3 bucket."
  return 0
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
echo "Running: sudo systemctl stop jenkins" # Add more output
sudo systemctl stop jenkins
STOP_EXIT_CODE=$?
if [ $STOP_EXIT_CODE -ne 0 ]; then
  log_message "WARNING: Could not stop Jenkins service (exit code: $STOP_EXIT_CODE). Backup might be inconsistent."
fi
echo "Jenkins stop command completed. Waiting 5 seconds." # Add more output
sleep 5

# 2. Perform the backup
log_message "Creating backup of Jenkins Home directory: $JENKINS_HOME"
pushd "$JENKINS_HOME" > /dev/null || { log_message "ERROR: Failed to change to Jenkins home directory. Exiting."; exit 1; }

tar -czf "${TMP_BACKUP_DIR}/${BACKUP_ARCHIVE_NAME}" \
  --exclude="workspace" \
  --exclude="builds" \
  --exclude="plugins/*.jpi.pinned" \
  .

popd > /dev/null
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
echo "Running: sudo systemctl start jenkins" # Add more output
sudo systemctl start jenkins
START_EXIT_CODE=$?
if [ $START_EXIT_CODE -ne 0 ]; then
  log_message "WARNING: Could not start Jenkins service after backup (exit code: $START_EXIT_CODE)."
fi
echo "Jenkins start command completed. Waiting 5 seconds." # Add more output
sleep 5

log_message "--- Jenkins Backup Process Completed ---"
exit 0
