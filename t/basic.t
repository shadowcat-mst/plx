use strict;
use warnings;
use File::Path qw(make_path remove_tree);
use File::Which qw(which);
use Test::More;

require './bin/plx';

my ($out, $err, $log);

my $dir = 't/var/basic';
my $perl = Cwd::realpath($^X);

sub plx {
  no warnings qw(once redefine);
  ($log, $out, $err) = ([], [], []);
  local *App::plx::say = sub { push @$out, $_[0] };
  local *App::plx::stderr = sub { push @$err, $_[0] };
  local *App::plx::barf = sub { push @$err, $_[0]; die $_[0] };
  local *App::plx::run_action_exec = sub { shift; push @$log, @_ };
  App::plx->new->run(@_);
}

sub new {
  remove_tree $dir;
  make_path $dir;
  chdir $dir;
}

subtest 'no .plx', sub {
  new;
  ok(do{ eval { plx "--$_" }; @$err }, "no init: --$_ failed") for qw(
    base
    cmd
    commands
    config
    cpanm
    libs
    paths
    perl
  );
};

subtest 'plx --init', sub {
  new;
  plx '--init';
  ok(-f '.plx/perl', 'file created');
};

subtest 'plx --actions', sub {
  ok 1;
};

subtest 'plx --cmd', sub {
  ok 1;
};

subtest 'plx --commands', sub {
  new;
  plx '--init';
  plx qw(--commands);
  is_deeply [$out, $err], [[],[]], 'commands list empty';
};

subtest 'plx --config', sub {
  new;
  plx '--init';
  plx qw(--config perl set), $^X;
  plx '--perl';
  is_deeply $out, [ $perl ], '--perl output';
  plx qw(--config libspec);
  is_deeply $out, [
    '25-local.ll  local',
    '50-devel.ll  devel',
    '75-lib.dir   lib',
  ], 'libspec config';
};

subtest 'plx --cpanm', sub {
  new;
  plx '--init';
  eval { plx qw(--cpanm --help) };
  like $err->[0], qr(-cpanm args must start with -l or -L), 'no cpanm w/o lib';
  plx qw(--cpanm -llocal --help);
  my ($_perl, $_cpanm) = (scalar(which('perl')), scalar(which('cpanm')));
  is_deeply $log, [$_perl, $_cpanm, '-llocal', '--help'], 'cpanm ok';
  plx qw(--config perl set), $^X;
  plx qw(--cpanm -llocal --help);
  is_deeply $log, [$perl, $_cpanm, '-llocal', '--help'], 'custom perl cpanm ok';
};

subtest 'plx --exec', sub {
  ok 1;
};

subtest 'plx --help', sub {
  new;
  plx '--init';
  no warnings qw(once redefine);
  require Pod::Usage;
  my $called_usage;
  local *Pod::Usage::pod2usage = sub { $called_usage = 1 };
  plx '--help';
  ok $called_usage, 'pod2usage fired for --help';
};

subtest 'plx --libs', sub {
  ok 1;
};

subtest 'plx --paths', sub {
  ok 1;
};

subtest 'plx --perl', sub {
  new;
  plx '--init';
  plx '--perl';
  is_deeply $out, [ scalar which('perl') ], '--perl output';
};

subtest 'plx --version', sub {
  new;
  plx '--init';
  plx '--version';
  is_deeply $out, [ App::plx->VERSION ], '--version output';
};

done_testing;
