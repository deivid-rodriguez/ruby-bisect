#!/usr/bin/env bash

ruby_bisect_version="0.0.1"
ruby_bisect_dir=$(cd "${BASH_SOURCE[0]%/*}" && pwd)
project_dir=$(pwd)
ruby_dir="$HOME/src/ruby-head"

source "$ruby_bisect_dir/util.sh"

#
# Runs git inside the cloned copy of ruby sources
#
function git_in_ruby_dir() {
  git -C "$ruby_dir" "$@"
}

#
# Wrapper to "git bisect" inside the ruby source directory
#
function git_bisect() {
  git_in_ruby_dir bisect "$@"
}

#
# Clones Ruby repo and switches to it
#
function clone_ruby() {
  run git clone git@github.com:ruby/ruby.git "$ruby_dir"
}

#
# Translates a commit's svn id to its git sha1 using git's log
#
function svn2git {
  git_in_ruby_dir log --all --grep="trunk@$1" --pretty=format:'%h'
}


#
# Prints usage information
#
function usage() {
  cat <<USAGE

  ruby-bisect <GOOD_SVN_ID>[ <BAD_SVN_ID>] -- COMMAND

  @example

  ruby-bisect 55016 55039 -- bundle exec rake

  Given a known good revision, it finds the commit in ruby-core that broke your
  program. You can optionally specify a bad revision too, otherwise the latest
  revision in ruby-core with be used as the bad commit.

USAGE
}

#
# Parses command line options
#
function parse_options() {
  case "$1" in
    -h|--help)
      usage
      exit
      ;;
    -V|--version)
      echo "ruby-bisect version $ruby_bisect_version"
      exit
      ;;
  esac

  if (($# == 0))
  then
    echo "ruby-bisect: GOOD_SVN_ID and COMMAND required" >&2
    exit 1
  fi

  good_svn_id=$1

  if [[ "$2" != "--" ]]
  then
    bad_svn_id=$2
  fi

  shift $(($(n_args "$@") + 1))

  if (($# == 0))
  then
    echo "ruby-bisect: COMMAND required" >&2
    exit 1
  fi

  command=$*
}

function parse_revisions() {
  good_revision=$(svn2git "$good_svn_id")

  if [[ -v bad_svn_id ]]
  then
    bad_revision=$(svn2git "$bad_svn_id")
  else
    bad_revision=$(git -C "$ruby_dir" show -s --pretty=format:'%h')
  fi
}

#
# Bisects the cloned ruby
#
function ruby_bisect() {
  git_bisect start
  git_bisect good "$good_revision"
  git_bisect bad "$bad_revision"
  git_bisect run "$ruby_bisect_dir/check_revision.sh" "$project_dir" -- "$command"
  git_in_ruby_dir clean -fd && git_bisect reset
}

#
# Final cleanup, gets rid of the cloned ruby
#
function cleanup() {
  run rm -rf "$ruby_dir"
}
