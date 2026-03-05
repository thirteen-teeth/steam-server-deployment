#!/bin/bash

# Generate a random seed of 10 characters with random letters and capitalization
seed=$(cat /dev/urandom | tr -dc 'a-zA-Z' | fold -w 10 | head -n 1)

# Output the URL with the generated seed
/mnt/c/Program\ Files/Google/Chrome/Application/chrome.exe "https://valheim-map.world/?seed=${seed}&offset=0%2C0&zoom=0.600&view=0&ver=0.219.13"
