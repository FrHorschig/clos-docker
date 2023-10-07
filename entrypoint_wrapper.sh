#!/bin/bash

cleanup() {
    chown -R $(id -u):$(id -g) /home/lineageos/android
    exit
}

trap cleanup SIGINT SIGTERM
"$@"
wait $!
cleanup
