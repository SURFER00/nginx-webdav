#!/bin/bash
set -e

sed -i "s/\${CLIENT_MAX_BODY_SIZE}/$CLIENT_MAX_BODY_SIZE/g" /etc/nginx/nginx.conf

# Function to create a WebDAV user
create_webdav_user() {
    local USERNAME=$1
    local PASSWORD=$2
    
    # Create user directory if it doesn't exist
    mkdir -p /data/$USERNAME
    
    # Set proper permissions
    chown -R nginx:nginx /data/$USERNAME
    chmod -R 755 /data/$USERNAME

    htpasswd -b /etc/nginx/htpasswd $USERNAME $PASSWORD

    echo "Created WebDAV user: $USERNAME"
}

touch /etc/nginx/htpasswd

# Process users from environment variables
# Format: WEBDAV_USER_name=password
for var in $(env | grep -E '^WEBDAV_USER_' | cut -d= -f1); do
    # Extract username from the variable name
    username=$(echo $var | sed 's/WEBDAV_USER_//')
    # Get the password from the environment variable
    password=${!var}
    
    # Create the user
    create_webdav_user $username $password
done

# Make sure /data is owned by nginx
chown -R nginx:nginx /data

# Start nginx
echo "Starting Nginx..."
exec "$@"