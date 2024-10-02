set -e

if [ -z "$1" ]; then
    echo "Brother, show me some user@host, and then we'll talk."
    echo "\n\t$0 <user>@<host>\n"
    # We're not putting up with this.
    exit 1
fi

# We're just going to assume this is what we want. :-)
USER_ID="$1"
USER=$(echo "$USER_ID" | cut -d "@" -f 1)
HOST=$(echo "$USER_ID" | cut -d "@" -f 2)

echo "Copying SSH key to $HOST as $USER...\n"
ssh-copy-id $USER_ID
echo "Copied!"

echo "\nCopying scripts to $HOST as $USER...\n"
scp -r "$(dirname "$0")" "$USER_ID:scripts"
echo "\nCopied!"

echo "\nTime to roll!\n"
clear
ssh $USER_ID
