# NAME

App::plx - Perl Layout Executor

# SYNOPSIS

     plx --help                             # This output

     plx --init <perl>                      # Initialize layout config
     plx --perl                             # Show layout perl binary
     plx --libs                             # Show layout $PERL5LIB entries
     plx --paths                            # Show layout additional $PATH entries
     plx --cpanm -llocal --installdeps .    # Run cpanm from outside $PATH
    
     plx perl <args>                        # Run perl within layout
     plx -E '...'                           # (ditto)
     plx script-in-dev <args>               # Run dev/ script within layout
     plx script-in-bin <args>               # Run bin/ script within layout
     plx script/in/cwd <args>               # Run script within layout
     plx program <args>                     # Run program from layout $PATH

# WHY PLX

While perl has many tools for configuring per-project development
environments, using them can still be a little on the lumpy side. With
[Carton](https://metacpan.org/pod/Carton), you find yourself running one of

    perl -Ilocal/lib/perl -Ilib bin/myapp
    carton exec perl -Ilib bin/myapp

With [App::perlbrew](https://metacpan.org/pod/App::perlbrew),

    perlbrew switch perl-5.28.0@libname
    perl -Ilib bin/myapp

With [https://github.com/tokuhirom/plenv](https://github.com/tokuhirom/plenv),

    plenv exec perl -Ilib bin/myapp

and if you have more than one distinct layer of dependencies, while
[local::lib](https://metacpan.org/pod/local::lib) will happily handle that, integrating it with everything else
becomes a pain in the buttocks.

As a result of this, your not-so-humble author found himself regularly having
a miniature perl executor script at the root of git clones that looked
something like:

    #!/bin/sh
    eval $(perl -Mlocal::lib=--deactivate-all)
    export PERL5LIB=$PWD/local/lib/perl5
    bin=$1
    shift
    ~/perl5/perlbrew/perls/perl-5.28.0/bin/$bin "$@"

and then running:

    ./pl perl -Ilib bin/myapp

However, much like back in 2007 frustration with explaining to other
developers how to set up [CPAN](https://metacpan.org/pod/CPAN) to install into `~/perl5` and how to
set up one's environment variables to then find the modules so installed
led to the exercise in rage driven development that first created
[local::lib](https://metacpan.org/pod/local::lib), walking newbies through the creation and subsequent use of
such a script was not the most enjoyable experience for anybody involved.

Thus, the creation of this module to reduce the setup process to:

    cpanm App::plx
    plx --init 5.28.0
    plx --cpanm -llocal --notest --installdeps .

Follwed by being able to immediately (and even more concisely) run:

    plx myapp

which will execute `perl -Ilib bin/myapp` with the correct `perl` and the
relevant [local::lib](https://metacpan.org/pod/local::lib) already in scope.

If this seems of use to you, the [QUICKSTART](https://metacpan.org/pod/QUICKSTART) is next and the [ACTIONS](https://metacpan.org/pod/ACTIONS)
section of this document lists the full capabilities of plx. Onwards!

# QUICKSTART

Let's assume we're going to be working on Foo-Bar, so we start with:

    git clone git@github.com:arthur-nonymous/Foo-Bar.git
    cd Foo-Bar

Assuming the perl we'd get from running just `perl` suffices, then we
next run:

    plx --init

If we want a different perl - say, we have a `perl5.30.1` in our path, or
a `perl-5.30.1` built in perlbrew, we'd instead run:

    plx --init 5.30.1

To quickly get our dependencies available, we then run:

    plx --cpanm -llocal --notest --installdeps .

If the project is designed to use [Carton](https://metacpan.org/pod/Carton) and has a `cpanfile.snapshot`,
instead we would run:

    plx --cpanm -ldevel --notest Carton
    plx carton install

If the goal is to test this against our current development version of another
library, then we'd also want to run:

    plx --config libspec add 40otherlib.dir ../Other-Lib/lib

If we want our ~/perl [local::lib](https://metacpan.org/pod/local::lib) available within the plx environment, we
can add that as the least significant libspec with:

    plx --config libspec add 00tilde.ll $HOME/perl5

At which point, we're ready to go, and can run:

    plx myapp              # to run bin/myapp
    plx t/foo.t            # to run one test file
    plx prove              # to run all t/*.t test files
    plx -E 'say for @INC'  # to run a one liner within the layout

To learn everything else plx is capable of, read on to the [ACTIONS](https://metacpan.org/pod/ACTIONS) section
coming next.

Have fun!

# ACTIONS

    plx --help                             # Print synopsis

    plx --init <perl>                      # Initialize layout config
    plx --perl                             # Show layout perl binary
    plx --libs                             # Show layout $PERL5LIB entries
    plx --paths                            # Show layout additional $PATH entries
    plx --cpanm -llocal --installdeps .    # Run cpanm from outside $PATH

    plx --config perl                      # Show perl binary
    plx --config perl show                 # Show perl binary
    plx --config perl set /path/to/perl    # Select exact perl binary
    plx --config perl set perl-5.xx.y      # Select perl via $PATH or perlbrew

    plx --config libspec                   # Show lib specifications
    plx --config libspec show              # Show lib specifications
    plx --config libspec add <name> <path> # Add lib specification
    plx --config libspec del <name> <path> # Delete lib specification

    plx --exec <cmd> <args>                # exec()s with env vars set
    plx --perl <args>                      # Run perl with args
    plx --bin <script> <args>              # Run script from bin/
    plx --dev <script> <args>              # Run script from dev/

    plx --cmd <cmd> <args>                 # DWIM command:
    
      cmd = perl           -> --perl <args>
      cmd = -<flag>        -> --perl -<flag> <args>
      cmd = some/file      -> --perl some/file <args>
      cmd = ./file         -> --perl ./file <args>
      cmd = name ->
        exists dev/<name>  -> --dev <name> <args>
        exists bin/<name>  -> --bin <name> <args>
        else               -> --exec <name> <args>
    
    plx <something> <args>                 # Shorthand for plx --cmd

## --help

Prints out the usage information (i.e. the ["SYNOPSIS"](#synopsis)) for plx.

## --init

    plx --init                     # resolve 'perl' in $PATH
    plx --init perl                # (ditto)
    plx --init 5.28.0              # looks for perl5.28.0 in $PATH
                                   # or perl-5.28.0 in perlbrew
    plx --init /path/to/some/perl  # uses the absolute path directly

Initializes the layout.

If a perl name is passed, attempts to resolve it via `$PATH` and `perlbrew`
and sets the result as the layout perl; if not looks for just `perl`.

Creates the following libspec config:

    25local.ll  local
    50devel.ll  devel
    75lib.dir   lib

## --libs

Prints the directories that will be added to `PERL5LIB`, one per line.

These will include the `lib/perl5` subdirectory for each `ll` entry in the
libspecs, and the directory for each `dir` entry.

## --paths

Prints the directories that will be added to `PATH`, one per line.

These will include the containing directory of the environment's perl binary
if not already in `PATH`, followed by the `bin` directories of any `ll`
entries in the libspecs.

## --cpanm

    plx --cpanm -Llocal --installdeps .
    plx --cpanm -ldevel App::Ack

Finds the `cpanm` binary in the `PATH` that `plx` was executed _from_,
and executes it using the layout's perl binary and environment variables.

Requires the user to specify a [local::lib](https://metacpan.org/pod/local::lib) to install into via `-l` or
`-L` in order to avoid installing modules into unexpected places.

Note that this action exists primarily for bootstrapping, and if you want
to use a different installer such as [App::cpm](https://metacpan.org/pod/App::cpm), you'd install it with:

    plx --cpanm -ldevel App::cpm

and then subsequently run e.g.

    plx cpm install App::Ack

to install modules.

## --exec

    plx --exec <command> <args>

Sets up the layout's environment variables and `exec`s the command.

## --perl

    plx --perl
    plx --perl <options> <script> <args>

Without arguments, sugar for `--config perl show`.

Otherwise, sets up the layout's environment variables and `exec`s the
layout's perl with the given options and arguments.

## --dev

    plx --dev <script> <args>

Runs `dev/script` ala [--perl](https://metacpan.org/pod/--perl).

Much like the `devel` [local::lib](https://metacpan.org/pod/local::lib) is created to allow for the installation
of out-of-band dependencies that aren't going to be needed in production, the
`dev` directory is supported to allow for the easy addition of development
time only sugar commands. Note that since `perl` will re-exec anything with
a non-perl shebang, one can add wrappers here ala:

    $ cat dev/prove
    #!/bin/sh
    exec prove -j8 "$@"

## --bin

    plx --bin <script> <args>

Runs `bin/script` ala [--perl](https://metacpan.org/pod/--perl).

## --cmd

    plx --cmd <cmd> <args>                 # DWIM command:
    
      cmd = perl           -> --perl <args>
      cmd = -<flag>        -> --perl -<flag> <args>
      cmd = some/file      -> --perl some/file <args>
      cmd = ./file         -> --perl ./file <args>
      cmd = name ->
        exists dev/<name>  -> --dev <name> <args>
        exists bin/<name>  -> --bin <name> <args>
        else               -> --exec <name> <args>

## --config

    plx --config                     # Show current config
    plx --config <name>              # Alias for --config <name> show
    plx --config <name> <operation>  # Invoke config operation

### perl

    plx --config perl show
    plx --config perl set <spec>

If the spec passed to `set` contains a `/` character, plx assumes that it's
an absolute bath and records it as-is.

If not, we go a-hunting.

First, if the spec begins with a `5`, we replace it with `perl5`.

Second, we search `$PATH` for a binary of that name, and record it if so.

Third, if the (current) spec begins `perl5`, we replace it with `perl-5`.

Fourth, we search `$PATH` for a `perlbrew` binary, and ask it if it has a
perl named after the spec, and record that if so.

Fifth, we shrug and hope the user can come up with an absolute path next time.

**Note:** The original spec passed to `set` is recorded in `.plx/perl.spec`,
so if you intend to share the `.plx` directory across multiple machines via
version control or otherwise, remove/exclude the `.plx/perl` file and plx
will automatically attempt to re-locate the perl on first invocation.

### libspec

    plx --config libspec show
    plx --config libspec add <name> <spec>
    plx --config libspec del <name> <spec>

A libspec config entry consists of a name and a spec, and the show output
prints them space separated one per line, with enough spaces to make the
specs align:

    25local.ll  local
    50devel.ll  devel
    75lib.dir   lib

The part of the name before the last `.` is not semantically significant to
plx, but is used for asciibetical sorting of the libspec entries to determine
in which order to apply them.

The part after must be either `ll` for a [local::lib](https://metacpan.org/pod/local::lib), or `dir` for a bare
[lib](https://metacpan.org/pod/lib) directory.

When loaded, the spec is (if relative) resolved to an absolute path relative
to the layout root, then all `..` entries and symlinks resolved to give a
final path used to set up the layout environment.

# AUTHOR

    mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

# CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

# COPYRIGHT

Copyright (c) 2020 the App::plx ["AUTHOR"](#author) and ["CONTRIBUTORS"](#contributors)
as listed above.

# LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
