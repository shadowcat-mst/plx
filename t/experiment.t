use strict;
use warnings;
use File::Spec::Functions qw(catfile);
use File::Path qw(remove_tree);
use File::Temp qw(tempdir);
use Test::More;

require 'bin/plx';

sub prg {
  my ($base, $path, $lines) = @_;
  map mkdir(catfile($base, $_)), 'bin', 'dev';
  my $file = catfile($base, @$path);
  open my $fh, ">", $file or die "Can't open $file: $!";
  print $fh join "\n", @$lines;
  close $fh;
  catfile(@$path);
}

sub plx {
  no warnings qw(once redefine);
  my ($dir) = (tempdir('CLEANUP', 0));
  my ($out, $err, $plx) = ([], [], App::plx->new(layout_base_dir => $dir));
  sub {
    local $@;
    local *App::plx::say = sub { push @$out, $_[0] };
    local *App::plx::stderr = sub { push @$err, $_[0] };
    (eval{$plx->run(@_)}, $@, $out, $err, $dir);
  }
}

subtest 'plx --init', sub {
  my $plx = plx;
  my ($res, $err, $stdout, $stderr, $dir) = $plx->('--init');
  ok 1;
  remove_tree $dir;
};

subtest 'plx --actions', sub {
  my $plx = plx;
  $plx->('--init');
  no warnings 'redefine';
  require Pod::Usage;
  local *Pod::Usage::pod2usage = sub {["caught"]};
  my ($res, $err, $stdout, $stderr, $dir) = $plx->('--actions');
  is_deeply $res, ["caught"];
  ok 1;
  remove_tree $dir;
};

subtest 'plx --cmd', sub {
  my $plx = plx;
  $plx->('--init');
  my ($res, $err, $stdout, $stderr, $dir) = $plx->('--cmd', '1');
  ok 1;
  remove_tree $dir;
};

subtest 'plx --commands', sub {
  my $plx = plx;
  $plx->('--init');
  my ($res, $err, $stdout, $stderr, $dir) = $plx->('--commands');
  ok 1;
  remove_tree $dir;
};

subtest 'plx --config', sub {
  my $plx = plx;
  $plx->('--init');
  my ($res, $err, $stdout, $stderr, $dir) = $plx->('--config');
  ok 1;
  remove_tree $dir;
};

subtest 'plx --cpanm', sub {
  my $plx = plx;
  $plx->('--init');
  my ($res, $err, $stdout, $stderr, $dir) = $plx->('--cpanm');
  ok 1;
  remove_tree $dir;
};

subtest 'plx --exec', sub {
  my $plx = plx;
  $plx->('--init');
  my ($res, $err, $stdout, $stderr, $dir) = $plx->('--exec');
  ok 1;
  remove_tree $dir;
};

subtest 'plx --help', sub {
  my $plx = plx;
  $plx->('--init');
  no warnings 'redefine';
  require Pod::Usage;
  local *Pod::Usage::pod2usage = sub {["caught"]};
  my ($res, $err, $stdout, $stderr, $dir) = $plx->('--help');
  is_deeply $res, ["caught"];
  ok 1;
  remove_tree $dir;
};

subtest 'plx --libs', sub {
  my $plx = plx;
  $plx->('--init');
  my ($res, $err, $stdout, $stderr, $dir) = $plx->('--libs');
  ok 1;
  remove_tree $dir;
};

subtest 'plx --paths', sub {
  my $plx = plx;
  $plx->('--init');
  my ($res, $err, $stdout, $stderr, $dir) = $plx->('--paths');
  ok 1;
  remove_tree $dir;
};

subtest 'plx --perl', sub {
  my $plx = plx;
  $plx->('--init');
  my ($res, $err, $stdout, $stderr, $dir) = $plx->('--perl');
  ok 1;
  remove_tree $dir;
};

ok 1 and done_testing;
