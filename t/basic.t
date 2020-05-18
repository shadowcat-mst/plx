use strict;
use warnings;
use File::Path qw(make_path remove_tree);
use Test::More;

require 'bin/plx';

my ($out, $err);

sub plx {
  no warnings qw(once redefine);
  ($out, $err) = ([], []);
  local *Perl::Layout::Executor::say = sub { push @$out, $_[0] };
  local *Perl::Layout::Executor::stderr = sub { push @$err, $_[0] };
  Perl::Layout::Executor->new->run(@_);
}

my $dir = 't/var/basic';

remove_tree $dir;
make_path $dir;
chdir $dir;

ok(!eval { plx '--perl'; 1 }, "Can't run commands against empty dir");

plx '--init';

ok(-l '.plx/perl', 'symlink created');

is(readlink('.plx/perl'), $^X, 'symlink target');

plx '--perl';

is_deeply $out, [ $^X ], '--perl output';

plx qw(--config libspec);

is_deeply $out, [
  '25local.ll  local',
  '50devel.ll  devel',
  '75lib.dir   lib',
], 'libspec config';

done_testing;
