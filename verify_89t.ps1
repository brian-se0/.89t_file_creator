[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [string]$WordRiderJar = "C:\Users\FoxOS_User\Downloads\wordrider\wordrider-0.7\wordrider.jar",

    [string]$JjsPath = "C:\Users\FoxOS_User\Downloads\OpenJDK8U-jre_x64_windows_hotspot_8u482b08\jdk8u482-b08-jre\bin\jjs.exe",

    [switch]$SkipReaderCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-BigEndianUInt16 {
    param(
        [byte[]]$Bytes,
        [int]$Offset
    )

    return (([int]$Bytes[$Offset] -shl 8) -bor [int]$Bytes[$Offset + 1])
}

function Invoke-ReaderCheck {
    param(
        [string]$TargetPath,
        [string]$JarPath,
        [string]$NashornPath
    )

    if (-not (Test-Path -LiteralPath $JarPath -PathType Leaf)) {
        return [pscustomobject]@{
            Status = "Skipped"
            Detail = "WordRider jar not found"
            ContentLength = $null
        }
    }

    if (-not (Test-Path -LiteralPath $NashornPath -PathType Leaf)) {
        return [pscustomobject]@{
            Status = "Skipped"
            Detail = "jjs.exe not found"
            ContentLength = $null
        }
    }

    $forwardPath = ($TargetPath -replace "\\", "/")
    $tempScript = Join-Path $env:TEMP ("verify_89t_" + [guid]::NewGuid().ToString("N") + ".js")
    $scriptBody = @"
var File = Java.type('java.io.File');
var Reader = Java.type('net.wordrider.ti89.TITextFileReader');
var reader = new Reader();
try {
  var ok = reader.openFromFile(new File('$forwardPath'));
  print('OPEN=' + ok);
  if (ok) {
    print('CONTENT_LENGTH=' + String(reader.getContent()).length());
  }
} catch (e) {
  print('ERROR=' + e);
  java.lang.System.exit(2);
}
"@

    try {
        Set-Content -LiteralPath $tempScript -Value $scriptBody -Encoding ASCII
        $output = & $NashornPath -cp $JarPath -scripting $tempScript 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        if (Test-Path -LiteralPath $tempScript) {
            Remove-Item -LiteralPath $tempScript -Force
        }
    }

    $joined = ($output | ForEach-Object { "$_" }) -join "`n"
    if ($exitCode -ne 0) {
        return [pscustomobject]@{
            Status = "Failed"
            Detail = $joined.Trim()
            ContentLength = $null
        }
    }

    $openMatch = [regex]::Match($joined, "OPEN=(true|false)")
    $lengthMatch = [regex]::Match($joined, "CONTENT_LENGTH=(\d+)")
    if (-not $openMatch.Success) {
        return [pscustomobject]@{
            Status = "Failed"
            Detail = "Reader output did not contain OPEN="
            ContentLength = $null
        }
    }

    if ($openMatch.Groups[1].Value -ne "true") {
        return [pscustomobject]@{
            Status = "Failed"
            Detail = $joined.Trim()
            ContentLength = $null
        }
    }

    $contentLength = $null
    if ($lengthMatch.Success) {
        $contentLength = [int]$lengthMatch.Groups[1].Value
    }

    return [pscustomobject]@{
        Status = "Passed"
        Detail = $joined.Trim()
        ContentLength = $contentLength
    }
}

$resolvedPath = (Resolve-Path -LiteralPath $Path).Path
$bytes = [IO.File]::ReadAllBytes($resolvedPath)

if ($bytes.Length -lt 90) {
    throw "File is too short to be a valid TI text file: $resolvedPath"
}

$signature = [Text.Encoding]::ASCII.GetString($bytes[0..7])
$folderName = [Text.Encoding]::ASCII.GetString($bytes[10..17]).Trim([char]0)
$comment = [Text.Encoding]::ASCII.GetString($bytes[18..57]).Trim([char]0)
$varName = [Text.Encoding]::ASCII.GetString($bytes[64..71]).Trim([char]0)
$sizeField = [BitConverter]::ToUInt32($bytes, 76)
$bodyLengthField = Get-BigEndianUInt16 -Bytes $bytes -Offset 86
$computedBodyLength = $bytes.Length - 88 - 2
$storedChecksum = [BitConverter]::ToUInt16($bytes, $bytes.Length - 2)
$computedChecksum = 0
for ($i = 82; $i -le $bytes.Length - 3; $i++) {
    $computedChecksum = ($computedChecksum + $bytes[$i]) -band 0xFFFF
}

$readerCheck = [pscustomobject]@{
    Status = "Skipped"
    Detail = "Reader check skipped by caller"
    ContentLength = $null
}

if (-not $SkipReaderCheck) {
    $readerCheck = Invoke-ReaderCheck -TargetPath $resolvedPath -JarPath $WordRiderJar -NashornPath $JjsPath
}

$result = [pscustomobject]@{
    Path = $resolvedPath
    Signature = $signature
    FolderName = $folderName
    Comment = $comment
    VarName = $varName
    Length = $bytes.Length
    SizeField = $sizeField
    SizeMatches = ($sizeField -eq $bytes.Length)
    BodyLengthField = ('0x{0:X4}' -f $bodyLengthField)
    ComputedBodyLength = ('0x{0:X4}' -f $computedBodyLength)
    BodyLengthMatches = ($bodyLengthField -eq $computedBodyLength)
    StoredChecksum = ('0x{0:X4}' -f $storedChecksum)
    ComputedChecksum = ('0x{0:X4}' -f $computedChecksum)
    ChecksumMatches = ($storedChecksum -eq $computedChecksum)
    ReaderCheck = $readerCheck.Status
    ReaderContentLength = $readerCheck.ContentLength
    ReaderDetail = $readerCheck.Detail
}

$result | Format-List

$structuralOk = $result.SizeMatches -and $result.BodyLengthMatches -and $result.ChecksumMatches
$readerOk = ($readerCheck.Status -eq "Passed" -or $readerCheck.Status -eq "Skipped")

if (-not ($structuralOk -and $readerOk)) {
    exit 1
}
