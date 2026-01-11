#!/bin/sh
set -eu

run_post_stop() {
  echo "post-stop: devcontainer is stopping"
}

term_handler() {
  run_post_stop
  if [ -n "${child_pid:-}" ] && kill -0 "$child_pid" 2>/dev/null; then
    kill -TERM "$child_pid" 2>/dev/null || true
    wait "$child_pid" || true
  fi
  exit 0
}

trap term_handler INT TERM

if [ "$#" -eq 0 ]; then
  tail -f /dev/null &
  child_pid=$!
else
  "$@" &
  child_pid=$!
fi

wait "$child_pid"
exit_code=$?

run_post_stop

exit "$exit_code"
