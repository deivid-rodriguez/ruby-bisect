#!/usr/bin/env bash

#
# Given a command line, finds the number of arguments meant for the script
#
# This means the number of arguments before the double dash.
#
function n_args() {
  n=0

  for arg in "$@"
  do
    if [[ "$arg" == "--" ]]
    then
      break
    else
      n=$((n + 1))
    fi
  done

  echo $n
}

#
# Runs a command in a quiet manner
#
function quiet() {
  if ! err=$("$@" 2>&1)
  then
    err "$err"
    exit 1
  fi
}

#
# Runs a command
#
function run() {
  echo "running '$*'..."

  quiet "$@"
}

#
# Prints a program error
#
function err() {
  if [[ "$1" == *$'\n'* ]]
  then
    echo -e "\n*** Error: \n$1" >&2
  else
    echo -e "\n*** Error: $1" >&2
  fi
}

#
# Prints a error message and exits
#
function fail() {
  err "$1"

  usage

  exit 1
}
