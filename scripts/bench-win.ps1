# bench-win.ps1 WORK REPS: bench-one.cmd for each VARIANT.tar.gz in WORK, the order rotating; one line per build:
# VARIANT nojit REP configure_s make_s install_s rc (make_s = nmake prepare-vcpkg + nmake)
param([string]$Work, [int]$Reps = 3)
function secs($a, $b) { $d = ([TimeSpan]::Parse($b.Trim().Replace(',', '.')) - [TimeSpan]::Parse($a.Trim().Replace(',', '.'))).TotalSeconds; if ($d -lt 0) { $d += 86400 }; $d }
New-Item -ItemType Directory -Force "$Work\logs" | Out-Null
for ($rep = 1; $rep -le $Reps; $rep++) {
  $all = @(Get-ChildItem "$Work\*.tar.gz" | ForEach-Object { $_.Name -replace '\.tar\.gz$', '' } | Sort-Object)
  $order = for ($i = 0; $i -lt $all.Count; $i++) { $all[($i + $rep - 1) % $all.Count] }
  foreach ($v in $order) {
    $out = cmd /c "$PSScriptRoot\bench-one.cmd $v $Work" 2>&1
    $rc = $LASTEXITCODE
    $m = @{}; foreach ($l in $out) { if ($l -match '^MARK (\S+) (.+)$') { $m[$Matches[1]] = $Matches[2] } }
    if ($m.end) { '{0} nojit {1} {2:F1} {3:F1} {4:F1} {5}' -f $v, $rep, (secs $m.configure $m.vcpkg), (secs $m.vcpkg $m.install), (secs $m.install $m.end), $rc }
    else { "$v nojit $rep 0 0 0 1"; Write-Host "FAILED rc=$rc $($out | Select-Object -Last 5)" }
  }
}
