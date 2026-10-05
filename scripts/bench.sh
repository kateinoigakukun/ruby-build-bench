#!/bin/bash
# bench.sh WORK JOBS REPS JITS: cold `./configure && make -jJOBS && make install DESTDIR=` of
# each VARIANT.tar.gz in WORK, REPS times with the order rotating, for each of JITS
# ("nojit yjit"); no ruby, git or compiler cache on PATH. BUILD_TRACE names a trace file
# for builds that write one.
# One line per build: VARIANT JIT REP configure_s make_s install_s rc
W=$1; J=$2; REPS=$3; JITS=$4
cd $W || exit 1
# PATH without ruby, git and ccache: links to everything else in the usual directories
NOBIN=$W/nobin; rm -rf $NOBIN; mkdir -p $NOBIN
for d in $HOME/.cargo/bin /usr/local/bin /usr/bin /bin /usr/sbin /sbin; do
  [ -d $d ] || continue
  for f in $d/*; do
    n=${f##*/}
    case $n in ruby*|gem|gem[0-9]*|irb*|erb*|rdoc*|ri|ri[0-9]*|bundle*|rake*|racc*|git*|ccache*|brew) continue;; esac
    [ -x "$f" ] && [ ! -e $NOBIN/$n ] && ln -s "$f" $NOBIN/$n
  done
done
now() { /usr/bin/perl -MTime::HiRes=time -e 'printf "%.2f", time'; }
run() { # VARIANT JIT REP
  local v=$1 jit=$2 rep=$3 opts d t0 t1 t2 t3 rc
  [ $jit = yjit ] && opts="--disable-install-doc --enable-yjit --disable-zjit" || opts="--disable-install-doc --disable-yjit --disable-zjit"
  d=$W/b-$v-$jit; rm -rf $d; mkdir -p $d; tar xzf $W/$v.tar.gz -C $d
  cd $d/ruby-* || return
  E="env -i HOME=$HOME PATH=$NOBIN CCACHE_DISABLE=1 BUILD_TRACE=$W/logs/$v-$jit-$rep-trace.txt"
  t0=$(now)
  $E ./configure $opts > $W/logs/$v-$jit-$rep-configure.log 2>&1; rc=$?
  t1=$(now)
  [ $rc = 0 ] && { $E make -j$J > $W/logs/$v-$jit-$rep-make.log 2>&1; rc=$?; }
  t2=$(now)
  [ $rc = 0 ] && { $E make install DESTDIR=$d/dest > $W/logs/$v-$jit-$rep-install.log 2>&1; rc=$?; }
  t3=$(now)
  [ $rc = 0 ] && { $d/dest/usr/local/bin/ruby -v > /dev/null 2>&1 || LD_LIBRARY_PATH=$d/dest/usr/local/lib $d/dest/usr/local/bin/ruby -v >/dev/null 2>&1 || rc=99; }
  echo "$t0 $t1 $t2 $t3" > $W/logs/$v-$jit-$rep-times.txt
  /usr/bin/perl -e "printf \"%s %s %d %.1f %.1f %.1f %d\n\", '$v', '$jit', $rep, $t1-$t0, $t2-$t1, $t3-$t2, $rc"
  cd $W; rm -rf $d
}
mkdir -p $W/logs
VARIANTS=$(cd $W && ls *.tar.gz | sed 's/\.tar\.gz$//' | sort)
for rep in $(seq 1 $REPS); do
  order=$(echo $VARIANTS | tr ' ' '\n' | awk -v r=$rep '{a[NR]=$0} END {for (i = 0; i < NR; i++) print a[(i + r - 1) % NR + 1]}')
  for jit in $JITS; do for v in $order; do run $v $jit $rep; done; done
done
