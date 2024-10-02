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

echo "Copying SSH key to $HOST as $USER . . ."
ssh-copy-id $USER_ID
echo "Copied!"

echo -n "Copying scripts to $HOST as $USER . . ."
scp -r "$(dirname "$0")" "$USER_ID:scripts"
echo "Copied!"

echo "Time to roll!"
ssh $USER_ID
