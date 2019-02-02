#!/bin/bash  
#Debian automatically checks for updates on first boot. This ensures that has completed before continuing.
#If it hasn't finished in 10 minutes, the script will exit ungracefully.
timeout=$(($(date +%s) + 600))

while pgrep apt > /dev/null; do
   
    time=$(date +%s)

    if [[ $time -ge $timeout ]];
    then
        exit 1
    fi

    sleep 1
done;
exit 0
