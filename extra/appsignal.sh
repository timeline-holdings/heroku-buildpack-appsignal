#!/usr/bin/env bash

# Start AppSignal collector in the background if it's not already running
if ! pgrep -x "appsignal-collector" > /dev/null; then
  nohup /usr/bin/appsignal-collector start > /dev/null 2>&1 &
  # Store the PID for potential management
  echo $! > /tmp/appsignal-collector.pid
fi
