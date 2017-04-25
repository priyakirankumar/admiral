#!/bin/bash -e

export COMPONENT="db"
export DB_DATA_DIR="$RUNTIME_DIR/$COMPONENT/data"
export DB_CONFIG_DIR="$CONFIG_DIR/$COMPONENT"
export LOGS_FILE="$RUNTIME_DIR/logs/$COMPONENT.log"

## Write logs of this script to component specific file
exec &> >(tee -a "$LOGS_FILE")

__validate_db_envs() {
  __process_msg "Creating system settings table"
  __process_msg "DB_DATA_DIR: $DB_DATA_DIR"
  __process_msg "DB_CONFIG_DIR: $DB_CONFIG_DIR"
  __process_msg "LOGS_FILE:$LOGS_FILE"
}

__copy_system_settings() {
  __process_msg "Copying system_settings.sql to db container"
  local host_location="$SCRIPTS_DIR/configs/system_settings.sql"
  local container_location="$CONFIG_DIR/db/system_settings.sql"
  sudo cp -vr $host_location $container_location

  __process_msg "Successfully copied system_settings.sql to db container"
}

__upsert_system_settings() {
  __process_msg "Upserting system settings in db"

  local system_settings_location="/etc/postgresql/config/system_settings.sql"
  local upsert_cmd="sudo docker exec db \
    psql -U $DBUSERNAME -d $DBNAME \
    -v ON_ERROR_STOP=1 \
    -f $system_settings_location"

  __process_msg "Executing: $upsert_cmd"
	eval "$upsert_cmd"
}

__update_release() {
  __process_msg "Updating system settings with release"

  local upsert_release_cmd="sudo docker exec db \
    psql -U $DBUSERNAME -d $DBNAME \
    -v ON_ERROR_STOP=1 \
    -c \"UPDATE \\\"systemSettings\\\" SET \\\"releaseVersion\\\"='$RELEASE'\""

  __process_msg "Executing: $upsert_release_cmd"
  eval "$upsert_release_cmd"
}

main() {
  __process_marker "Generating system settings"
  __validate_db_envs
  __copy_system_settings
  __upsert_system_settings
  __update_release
}

main