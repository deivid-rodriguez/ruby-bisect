#!/usr/bin/env bash

RUBY_BISECT_DIR=$(cd "${BASH_SOURCE[0]%/*}" && pwd)

# shellcheck source=share/ruby-bisect/util.sh
source "$RUBY_BISECT_DIR/util.sh"

#
# Finds svn_id of last commit
#
function last_revision() {
  git show -s --pretty=format:'%b' | grep -E -o "trunk@[0-9]+" | cut -d@ -f2
}

# Construct names
revision=$(last_revision)
ruby_version_name=ruby-$revision

if [[ "$SWITCHER" == "rbenv" ]]
then
  ruby_install_dir=$HOME/.rubies/$ruby_version_name
else
  ruby_install_dir=$HOME/.rbenv/versions/$ruby_version_name
fi

project_dir=$1

shift $(($(n_args "$@") + 1))

# Cleanup source dir in case it's in a bad state
run git clean -fd

# Generate configure script if needed
if [[ ! -s configure || configure.in -nt configure ]]
then
  run autoconf
fi

# Configure Ruby
run ./configure --disable-install-doc --prefix="$ruby_install_dir"

# Compile and install Ruby
run make -j && run make install

# Back to projects directory
cd "$project_dir" || exit 1

# Run passed command against the new ruby
if [[ "$SWITCHER" == "rbenv" ]]
then
  run chruby-exec "$ruby_version_name" -- "$@"
else
  RBENV_VERSION="$ruby_version_name" run "$@"
fi
