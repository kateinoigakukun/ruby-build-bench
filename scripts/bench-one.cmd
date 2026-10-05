@echo off
:: bench-one.cmd VARIANT WORK: a fresh tree WORK\b-VARIANT from WORK\VARIANT.tar.gz, then configure
:: (configure.bat when the tarball has one at its top, else win32\configure.bat), nmake prepare-vcpkg, nmake and
:: nmake install DESTDIR=, each between MARK lines
setlocal
set "V=%~1"
set "W=%~2"
set "BLD=%W%\b-%V%"
set "PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0"
call "%VCVARS%" > nul || exit /b 1
set MAKEFLAGS=
set MFLAGS=
:: (System32\bash.exe, the WSL launcher, may be there: not a shell the build can use)
where sh.exe ruby.exe git.exe 2>nul && (echo sh/ruby/git found on PATH & exit /b 1)
if exist "%BLD%" rd /s /q "%BLD%"
if exist "%BLD%-dest" rd /s /q "%BLD%-dest"
mkdir "%BLD%" || exit /b 1
tar.exe -xzf "%W%\%V%.tar.gz" -C "%BLD%" --strip-components=1 || exit /b 1
mklink /J "%BLD%\vcpkg_installed" "%W%\vcpkg\vcpkg_installed" > nul || exit /b 1
cd /d "%BLD%" || exit /b 1
set "OPTS=--disable-install-doc --disable-yjit --disable-zjit --with-opt-dir=%BLD:\=/%/vcpkg_installed/x64-windows --with-gmp"
echo MARK configure %TIME%
if exist configure.bat (call configure.bat %OPTS% > %W%\logs\%V%-configure.log 2>&1) else (call win32\configure.bat %OPTS% --without-baseruby > %W%\logs\%V%-configure.log 2>&1)
if not exist Makefile (echo FAILED configure & exit /b 1)
echo MARK vcpkg %TIME%
nmake prepare-vcpkg > %W%\logs\%V%-vcpkg.log 2>&1 || (echo FAILED vcpkg & exit /b 1)
echo MARK nmake %TIME%
nmake > %W%\logs\%V%-nmake.log 2>&1 || (echo FAILED nmake & exit /b 1)
echo MARK install %TIME%
nmake install DESTDIR=%BLD%-dest > %W%\logs\%V%-install.log 2>&1 || (echo FAILED install & exit /b 1)
echo MARK end %TIME%
cd /d %W%
rd /s /q "%BLD%"
