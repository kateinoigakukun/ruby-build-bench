# ruby-build-bench

Cold build timings of two Ruby source tarballs on GitHub-hosted runners.

The release given to the `bench` workflow carries the tarballs (`*.tar.gz`;
speedups are relative to `baseline.tar.gz`). For each runner, each tarball is unpacked fresh and built
with `configure`, `make -jN` (N = the runner's CPUs) and `make install
DESTDIR=...` (Windows: `configure.bat`, `nmake`, `nmake install`), several times
with the order rotating, without and with YJIT (Unix). Ruby, git and compiler
caches are kept off `PATH`. Results: the job summaries and the `results.txt`
artifacts (`VARIANT JIT REP configure_s make_s install_s rc`).
