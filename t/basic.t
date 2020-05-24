use strict;
use warnings;
use File::Path qw(make_path remove_tree);
use Test::More;

require 'bin/plx';

my ($out, $err);

sub plx {
  no warnings qw(once redefine);
  ($out, $err) = ([], []);
  local *App::plx::say = sub { push @$out, $_[0] };
  local *App::plx::stderr = sub { push @$err, $_[0] };
  App::plx->new->run(@_);
}

my $dir = 't/var/basic';

remove_tree $dir;
make_path $dir;
chdir $dir;

ok(!eval { plx '--perl'; 1 }, "Can't run commands against empty dir");

plx '--init';

ok(-f '.plx/perl', 'file created');

plx '--perl';

is_deeply $out, [ $^X ], '--perl output';

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

done_testing;
