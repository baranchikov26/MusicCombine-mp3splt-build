$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$exe = Join-Path $root '_build\dist\mp3splt.exe'
$fixture = Join-Path $root 'testdata\reference_4s.mp3'
if (-not (Test-Path $exe)) { throw 'Missing mp3splt.exe' }
if (-not (Test-Path $fixture)) { throw 'Missing test MP3' }
$tmp = Join-Path $env:RUNNER_TEMP ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
$old = $env:PATH
try {
 $env:PATH = "$(Split-Path $exe);$env:SystemRoot\System32;$env:SystemRoot"
 & $exe -v
 if ($LASTEXITCODE -ne 0) { throw 'Version check failed' }
 $out = Join-Path $tmp 'out'
 New-Item -ItemType Directory $out | Out-Null
 & $exe -f -d $out $fixture '0.00.00' '0.02.00'
 if ($LASTEXITCODE -ne 0) { throw 'MP3 split failed' }
 $files = @(Get-ChildItem -LiteralPath $out -File -Filter '*.mp3')
 if ($files.Count -ne 1) { throw "Expected 1 output; found $($files.Count)" }
 if ($files[0].Length -le 500 -or $files[0].Length -ge (Get-Item $fixture).Length) { throw 'Invalid output size' }
 Write-Host '[PASS] mp3splt portable Windows smoke test'
} finally {
 $env:PATH = $old
 Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
