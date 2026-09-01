#!/bin/zsh
echo -n "Enter your Mac login password: "
read -s pw
echo
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$pw" ~/Library/Keychains/login.keychain-db
security unlock-keychain -p "$pw" ~/Library/Keychains/login.keychain-db
echo "Done."
