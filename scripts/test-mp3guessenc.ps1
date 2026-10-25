$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$exe = Join-Path $root '_build\mp3guessenc\dist\mp3guessenc.exe'
$fixtureDir = Join-Path $root '_build\mp3guessenc\fixtures'
if (-not (Test-Path -LiteralPath $exe)) { throw 'Missing mp3guessenc.exe' }
$fixtures = @(Get-ChildItem -LiteralPath $fixtureDir -Filter '*.mp3' -File)
if ($fixtures.Count -lt 2) { throw 'Expected CBR and VBR MP3 fixtures' }
$old = $env:PATH
try {
    $env:PATH = "$(Split-Path $exe);$env:SystemRoot\System32;$env:SystemRoot"
    foreach ($f in $fixtures) {
        # mp3guessenc returns an encoder index as exit code on successful detection,
        # so nonzero does not automatically mean a failure.
        $output = (& $exe $f.FullName 2>&1 | Out-String)
        $code = $LASTEXITCODE
        Write-Host "FILE: $($f.Name); exit=$code"
        Write-Host ($output.Substring(0, [Math]::Min(900, $output.Length)))
        if ($output.Length -lt 100 -or
            $output -notmatch '(?i)(mpeg|layer|frame|bitrate|encoder)') {
            throw "MP3 analysis produced no meaningful MPEG statistics: $($f.Name)"
        }
        if ($code -lt 0 -or $code -ge 128) {
            throw "MP3 analyzer returned a probable error code $code for $($f.Name)"
        }
    }
    Write-Host '[PASS] Portable mp3guessenc MPEG CBR/VBR smoke tests'
}
finally {
    $env:PATH = $old
}
# Preserve successful analyzer classifications without propagating their
# positive encoder-identification exit codes to the GitHub pwsh wrapper.
$global:LASTEXITCODE = 0
