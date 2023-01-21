# NAME

App::plx - Perl Layout Executor

# SYNOPSIS

     plx --help                             # This output

     plx --init <perl>                      # Initialize layout config
     plx --perl                             # Show layout perl binary
     plx --libs                             # Show layout $PERL5LIB entries
     plx --paths                            # Show layout additional $PATH entries
     plx --env                              # Show layout env var changes
     plx --cpanm -llocal --installdeps .    # Run cpanm from outside $PATH
    
     plx perl <args>                        # Run perl within layout
     plx -E '...'                           # (ditto)
     plx script-in-dev <args>               # Run dev/ script within layout
     plx script-in-bin <args>               # Run bin/ script within layout
     plx ./script <args>                    # Run script within layout
     plx script/in/cwd <args>               # (ditto)
     plx program <args>                     # Run program from layout $PATH

# WHY PLX

While perl has many tools for configuring per-project development
environments, using them can still be a little on the lumpy side. With
[Carton](https://metacpan.org/pod/Carton), you find yourself running one of

    perl -Ilocal/lib/perl -Ilib bin/myapp
    carton exec perl -Ilib bin/myapp

With [App::perlbrew](https://metacpan.org/pod/App%3A%3Aperlbrew),

    perlbrew switch perl-5.28.0@libname
    perl -Ilib bin/myapp

With [https://github.com/tokuhirom/plenv](https://github.com/tokuhirom/plenv),

    plenv exec perl -Ilib bin/myapp

and if you have more than one distinct layer of dependencies, while
[local::lib](https://metacpan.org/pod/local%3A%3Alib) will happily handle that, integrating it with everything else
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
[local::lib](https://metacpan.org/pod/local%3A%3Alib), walking newbies through the creation and subsequent use of
such a script was not the most enjoyable experience for anybody involved.

Thus, the creation of this module to reduce the setup process to:

    cpanm App::plx
    cd MyProject
    plx --init 5.28.0
    plx --cpanm -llocal --notest --installdeps .

Follwed by being able to immediately (and even more concisely) run:

    plx myapp

which will execute `perl -Ilib bin/myapp` with the correct `perl` and the
relevant [local::lib](https://metacpan.org/pod/local%3A%3Alib) already in scope.

If this seems of use to you, the ["QUICKSTART"](#quickstart) is next and the ["ACTIONS"](#actions)
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

If we want our ~/perl [local::lib](https://metacpan.org/pod/local%3A%3Alib) available within the plx environment, we
can add that as the least significant libspec with:

    plx --config libspec add 00tilde.ll $HOME/perl5

At which point, we're ready to go, and can run:

    plx myapp              # to run bin/myapp
    plx t/foo.t            # to run one test file
    plx prove              # to run all t/*.t test files
    plx -E 'say for @INC'  # to run a one liner within the layout

To learn everything else plx is capable of, read on to the ["ACTIONS"](#actions) section
coming next.

Have fun!

# BOOTSTRAP

Under normal circumstances, one would run something like:

    cpanm App::plx

However, if you want a self-contained plx script without having a cpan
installer available, you can run:

    mkdir bin
    wget https://raw.githubusercontent.com/shadowcat-mst/plx/master/bin/plx-packed -O bin/plx

to get the current latest packed version.

The packed version bundles [local::lib](https://metacpan.org/pod/local%3A%3Alib) and [File::Which](https://metacpan.org/pod/File%3A%3AWhich), and also includes
a modified `--cpanm` action that uses an inline `App::cpanminus`.

# ENVIRONMENT

`plx` actions that execute external commands all clear any existing
environment variables that start with `PERL` to keep an encapsulated setup
for commands being run within the layouts - and also set `PERL5OPT` to
exclude `site_perl` (but not `vendor_perl`) to avoid locally installed
modules causing unexpected effects.

Having done so, `plx` then loads each env config entry and sets those
variables - then prepends the `plx` specific entries to both `PATH` and
`PERL5LIB`. You can add env config entries with ["--config"](#config):

    plx --config env add NAME VALUE

The changes that will be made to your environment can be output by calling
the ["--env"](#env) command.

Additionally, environment variable overrides may be provided to the
["--cmd"](#cmd), ["--exec"](#exec) and ["--perl"](#perl) commands by providing them in
 `NAME=VALUE` format:

    # do not do this, it will be deleted
    PERL_RL=Perl5 plx <something>

    # do this instead, it will provide the environment variable to the command
    plx PERL_RL=Perl5 <something>

# ACTIONS

    plx --help                             # Print synopsis
    plx --version                          # Print plx version

    plx --init <perl>                      # Initialize layout config for .
    plx --bareinit <perl>                  # Initialize bare layout config for .
    plx --base                             # Show layout base dir 
    plx --base <base> <action> <args>      # Run action with specified base dir
    
    plx --perl                             # Show layout perl binary
    plx --libs                             # Show layout $PERL5LIB entries
    plx --paths                            # Show layout additional $PATH entries
    plx --env                              # Show layout env var changes
    plx --cpanm -llocal --installdeps .    # Run cpanm from outside $PATH

    plx --config perl                      # Show perl binary
    plx --config perl set /path/to/perl    # Select exact perl binary
    plx --config perl set perl-5.xx.y      # Select perl via $PATH or perlbrew

    plx --config libspec                   # Show lib specifications
    plx --config libspec add <name> <path> # Add lib specification
    plx --config libspec del <name> <path> # Delete lib specification
    
    plx --config env                       # Show additional env vars
    plx --config env add <name> <path>     # Add env var
    plx --config env del <name> <path>     # Delete env var

    plx --exec <cmd> <args>                # exec()s with env vars set
    plx --perl <args>                      # Run perl with args

    plx --cmd <cmd> <args>                 # DWIM command:
    
      cmd = perl           -> --perl <args>
      cmd = -<flag>        -> --perl -<flag> <args>
      cmd = some/file      -> --perl some/file <args>
      cmd = ./file         -> --perl ./file <args>
      cmd = name ->
        exists .plx/cmd/<name> -> --perl .plx/cmd/<name> <args>
        exists dev/<name>      -> --perl dev/<name> <args>
        exists bin/<name>      -> --perl bin/<name> <args>
        else                   -> --exec <name> <args>

    plx --which <cmd>                      # Expands --cmd <cmd> without running
    
    plx <something> <args>                 # Shorthand for plx --cmd
    
    plx --commands <filter>?               # List available commands
    
    plx --multi [ <cmd1> <args1> ] [ ... ] # Run multiple actions
    plx --showmulti [ ... ] [ ... ]        # Show multiple action running
    plx [ ... ] [ ... ]                    # Shorthand for plx --multi
    
    plx --userinit <perl>                  # Init ~/.plx with ~/perl5 ll
    plx --installself                      # Installs plx and cpanm into layout
    plx --installenv                       # Appends plx --env call to .bashrc
    plx --userstrap <perl>                 # userinit+installself+installenv

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

    25-local.ll  local
    50-devel.ll  devel
    75-lib.dir   lib

## --bareinit

Identical to `--init` but creates no default configs except for `perl`.

## --base

    plx --base
    plx --base <base> <action> <args>

Without arguments, shows the selected base dir - `plx` finds this by
checking for a `.plx` directory in the current directory, and if not tries
the parent directory, recursively. The search stops either when `plx` finds
a `.git` directory, to avoid accidentally escaping a project repository, or
at the last directory before the root - i.e. `plx` will test `/home` but
not `/`.

With arguments, specifies a base dir to use, and then invokes the rest of the
arguments with that base dir selected - so for example one can make a default
configuration in `$HOME` available as `plh` by running:

    plx --init $HOME
    alias plh='plx --base $HOME'

## --libs

Prints the directories that will be added to `PERL5LIB`, one per line.

These will include the `lib/perl5` subdirectory for each `ll` entry in the
libspecs, and the directory for each `dir` entry.

## --paths

Prints the directories that will be added to `PATH`, one per line.

These will include the containing directory of the environment's perl binary
if not already in `PATH`, followed by the `bin` directories of any `ll`
entries in the libspecs.

## --env

Prints the changes that will be made to your environment variables, in a
syntax that is (hopefully) correct for your current shell.

## --cpanm

    plx --cpanm -Llocal --installdeps .
    plx --cpanm -ldevel App::Ack

Finds the `cpanm` binary in the `PATH` that `plx` was executed _from_,
and executes it using the layout's perl binary and environment variables.

Requires the user to specify a [local::lib](https://metacpan.org/pod/local%3A%3Alib) to install into via `-l` or
`-L` in order to avoid installing modules into unexpected places.

Note that this action exists primarily for bootstrapping, and if you want
to use a different installer such as [App::cpm](https://metacpan.org/pod/App%3A%3Acpm), you'd install it with:

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

Without arguments, sugar for `--config perl`.

Otherwise, sets up the layout's environment variables and `exec`s the
layout's perl with the given options and arguments.

## --cmd

    plx --cmd <cmd> <args>
    
      cmd = perl           -> --perl <args>
      cmd = -<flag>        -> --perl -<flag> <args>
      cmd = some/file      -> --perl some/file <args>
      cmd = ./file         -> --perl ./file <args>
      cmd = name ->
        exists .plx/cmd/<name> -> --perl .plx/cmd/<name> <args>
        exists dev/<name>      -> --perl dev/<name> <args>
        exists bin/<name>      -> --perl bin/<name> <args>
        else                   -> --exec <name> <args>

**Note**: Much like the `devel` [local::lib](https://metacpan.org/pod/local%3A%3Alib) is created to allow for the
installation of out-of-band dependencies that aren't going to be needed in
production, the `dev` directory is supported to allow for the easy addition
of development time only sugar commands. Note that since `perl` will re-exec
anything with a non-perl shebang, one can add wrappers here ala:

    $ cat dev/prove
    #!/bin/sh
    exec prove -j8 "$@"

## --which

    plx --which <cmd>

Outputs the expanded form of a `--cmd` invocation without running it.

## --config

    plx --config                     # Show current config
    plx --config <name>              # Show current <name> config
    plx --config <name> <operation>  # Invoke config operation

### perl

    plx --config perl
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

    plx --config libspec
    plx --config libspec add <name> <spec>
    plx --config libspec del <name> <spec>

A libspec config entry consists of a name and a spec, and the show output
prints them space separated one per line, with enough spaces to make the
specs align:

    25-local.ll  local
    50-devel.ll  devel
    75-lib.dir   lib

The part of the name before the last `.` is not semantically significant to
plx, but is used for asciibetical sorting of the libspec entries to determine
in which order to apply them.

The part after must be either `ll` for a [local::lib](https://metacpan.org/pod/local%3A%3Alib), or `dir` for a bare
[lib](https://metacpan.org/pod/lib) directory.

When loaded, the spec is (if relative) resolved to an absolute path relative
to the layout root, then all `..` entries and symlinks resolved to give a
final path used to set up the layout environment.

### env

    plx --config env
    plx --config env add <name> <value>
    plx --config env del <name> <value>

Manages additional environment variables, which are set immediately before
any environment changes required for the current ["libspec"](#libspec) and ["perl"](#perl)
settings are processed.

## --commands

    plx --commands         # all commands
    plx --commands c       # all commands starting with c
    plx --commands /json/  # all commands matching /json/

Lists available commands, name first, then full path.

If a filter argument is given, treats it as a fixed prefix to filter the
command list, unless the filter is `/re/` in which case the slashes are
stripped and the filter is treated as a regexp.

## --multi

    plx --multi [ --init ] [ --config perl set 5.28.0 ]

Runs multiple plx commands from a single invocation delimited by `[ ... ]`.

## --showmulti

    plx --showmulti [ --init ] [ --config perl set 5.28.0 ]

Outputs approximate plx invocations that would be run by `--multi`.

## --userinit

Same as `--init` but assumes `$HOME` as base and sets up only a single
libspec pointing at `$HOME/perl5`.

## --installself

Installs [App::plx](https://metacpan.org/pod/App%3A%3Aplx) and [App::cpanminus](https://metacpan.org/pod/App%3A%3Acpanminus) into the highest-numbered
[local::lib](https://metacpan.org/pod/local%3A%3Alib) within the layout.

## --installenv

(bash only currently)

Appends an eval line to set up the layout environment to the user's bashrc.

## --userstrap

Convenience command for `--userinit` plus `--installself` plus
`--installenv`.

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
