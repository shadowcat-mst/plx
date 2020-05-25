use strict;
use warnings;
use File::Path qw(make_path remove_tree);
use File::Which qw(which);
use Test::More;

require './bin/plx';

my ($out, $err, $log);

sub plx {
  no warnings qw(once redefine);
  ($log, $out, $err) = ([], [], []);
  local *App::plx::say = sub { push @$out, $_[0] };
  local *App::plx::stderr = sub { push @$err, $_[0] };
  local *App::plx::barf = sub { push @$err, $_[0]; die $_[0] };
  local *App::plx::run_action_exec = sub { shift; push @$log, @_ };
  App::plx->new->run(@_);
}

my $dir = 't/var/basic';
my $perl = Cwd::realpath($^X);

remove_tree $dir;
make_path $dir;
chdir $dir;

ok(do{ eval { plx "--$_" }; @$err }, "Can't run --$_ against empty dir") for qw(
  base
  cmd
  commands
  config
  cpanm
  libs
  paths
  perl
);

plx '--version';

is_deeply $out, [ App::plx->VERSION ], '--version output';

plx '--init';

ok(-f '.plx/perl', 'file created');

plx '--perl';

is_deeply $out, [ scalar which('perl') ], '--perl output';

plx qw(--config perl set), $^X;

plx '--perl';

is_deeply $out, [ $perl ], '--perl output';

plx qw(--config libspec);

is_deeply $out, [
  '25-local.ll  local',
  '50-devel.ll  devel',
  '75-lib.dir   lib',
], 'libspec config';

{
  no warnings qw(once redefine);
  require Pod::Usage;
  my $called_usage;
  local *Pod::Usage::pod2usage = sub { $called_usage = 1 };
  plx '--help';
  ok $called_usage, 'pod2usage fired for --help';
}

plx qw(--commands);

is_deeply [$out, $err], [[],[]], 'commands list empty';

eval { plx qw(--cpanm --help) };

like $err->[0], qr(-cpanm args must start with -l or -L), 'no cpanm w/o lib';

plx qw(--cpanm -llocal --help);

is_deeply $log, [$perl, scalar(which('cpanm')), '-llocal', '--help'], 'cpanm ok';

done_testing;
