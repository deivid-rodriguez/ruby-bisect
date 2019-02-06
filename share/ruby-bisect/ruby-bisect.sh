#!/usr/bin/env bash

ruby_bisect_version="0.0.1"
project_dir=$(pwd)
ruby_dir="$HOME/src/ruby-head"
git_extras_dir="$RUBY_BISECT_DIR/vendor/git-extras"

# shellcheck disable=SC1090
source "$RUBY_BISECT_DIR/util.sh"

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
  "$git_extras_dir/bin/git-force-clone" https://github.com/ruby/ruby "$ruby_dir"
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

  EXAMPLE

  ruby-bisect 55016 55039 -- bundle exec rake

  DESCRIPTION

  Given a known good revision, it finds the commit in ruby-core that broke your
  program. You can optionally specify a bad revision too, otherwise the latest
  revision in ruby-core with be used as the bad commit.

  OPTIONS

    -V, --version  Display ruby-bisect's version
    -h, --help     Display this help message
    -c, --cleanup  Remove cloned ruby after bisection
    -s, --switcher Use a specific version switcher, either chruby or rbenv
                   (default: rbenv)

USAGE
}

#
# Parses command line options
#
function parse_options() {
  while [[ $# -gt 0 ]]
  do
    case "$1" in
      -h|--help)
        usage
        exit
        ;;
      -V|--version)
        echo "ruby-bisect version $ruby_bisect_version"
        exit
        ;;
      -c|--cleanup)
        CLEANUP=1
        shift
        ;;
      -s|--switcher)
        export SWITCHER=$2
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done

  if (($# == 0))
  then
    fail "GOOD_SVN_ID and COMMAND required"
  fi

  good_svn_id=$1

  if [[ "$2" != "--" ]]
  then
    bad_svn_id=$2
  fi

  shift $(($(n_args "$@") + 1))

  if (($# == 0))
  then
    fail "COMMAND required"
  fi

  cmd=$*
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
  git_bisect run "$RUBY_BISECT_DIR/check_revision.sh" "$project_dir" -- "$cmd"
  git_in_ruby_dir clean -fd && git_bisect reset
}

#
# Final cleanup, gets rid of the cloned ruby
#
function cleanup() {
  if [[ "$CLEANUP" -eq "1" ]]
  then
    run rm -rf "$ruby_dir"
  fi
}
