#!/bin/bash

# Usage: ./delete_user_remote.sh user_to_delete servers.txt

USER_TO_DELETE="$1"
SERVER_LIST="$2"

if [[ -z "$USER_TO_DELETE" || -z "$SERVER_LIST" ]]; then
  echo "Usage: $0 <username_to_delete> <server_list_file>"
  exit 1
fi

if [[ ! -f "$SERVER_LIST" ]]; then
  echo "Server list file not found: $SERVER_LIST"
  exit 1
fi

for HOST in $(cat "$SERVER_LIST"); do
  echo "Connecting to $HOST..."

  ssh -o BatchMode=yes -o ConnectTimeout=5 "$HOST" "
    if id '$USER_TO_DELETE' &>/dev/null; then
      sudo userdel -r '$USER_TO_DELETE' && echo 'Deleted $USER_TO_DELETE on $HOST' || echo 'Failed to delete $USER_TO_DELETE on $HOST'
    else
      echo 'User $USER_TO_DELETE does not exist on $HOST'
    fi
  "
done