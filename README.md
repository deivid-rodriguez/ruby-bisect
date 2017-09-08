# ruby-bisect

Runs a git bisection of your ruby program against the different revisions of
ruby-core, so you can find out which one broke it.

This is just some bash scripts to make this process easier. They copy structure,
style and bash lessons from [ruby-install].

## Requirements

* [bash]
* [chruby]

## Install

```
git clone https://github.com/deivid-rodriguez/ruby-bisect
```

## Synopsis

From your target project directory,

* Bisect `myscript.rb`, known to work with MRI revision r55000, but failing
  against ruby-core latest master.

```
/path/to/ruby-bisect/bin/ruby-bisect 55000 -- myscript.rb
```

* Bisect `myscript.rb`, known to work with MRI revision r55000 and known to
  fail with MRI revision r55100.

```
/path/to/ruby-bisect/bin/ruby-bisect 55000 551000 -- myscript.rb
```

[bash]: https://www.gnu.org/software/bash/
[chruby]: https://github.com/postmodern/chruby
[ruby-install]: https://github.com/postmodern/ruby-install
