$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 5500
$ip = [System.Net.IPAddress]::Loopback
$listener = [System.Net.Sockets.TcpListener]::new($ip, $port)
$listener.Start()
Write-Host "Kleimpaul local: http://127.0.0.1:$port/" -ForegroundColor Green
Write-Host "Mantenha esta janela aberta. Ctrl+C para encerrar." -ForegroundColor DarkGray

function Get-Mime([string]$path) {
  switch ([IO.Path]::GetExtension($path).ToLowerInvariant()) {
    '.html' { 'text/html; charset=utf-8' }
    '.htm'  { 'text/html; charset=utf-8' }
    '.css'  { 'text/css; charset=utf-8' }
    '.js'   { 'text/javascript; charset=utf-8' }
    '.mjs'  { 'text/javascript; charset=utf-8' }
    '.json' { 'application/json; charset=utf-8' }
    '.svg'  { 'image/svg+xml' }
    '.png'  { 'image/png' }
    '.jpg'  { 'image/jpeg' }
    '.jpeg' { 'image/jpeg' }
    '.webp' { 'image/webp' }
    '.ico'  { 'image/x-icon' }
    default { 'application/octet-stream' }
  }
}

$rootFull = [IO.Path]::GetFullPath($root + [IO.Path]::DirectorySeparatorChar)
while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $stream = $client.GetStream()
    $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::ASCII, $false, 8192, $true)
    $requestLine = $reader.ReadLine()
    if ([string]::IsNullOrWhiteSpace($requestLine)) { continue }
    $parts = $requestLine.Split(' ')
    $method = $parts[0]
    $target = if ($parts.Length -gt 1) { $parts[1] } else { '/' }
    while (($line = $reader.ReadLine()) -ne $null -and $line -ne '') { }

    $rawPath = ($target -split '\?')[0]
    $decoded = [Uri]::UnescapeDataString($rawPath)
    if ($decoded -eq '/' -or [string]::IsNullOrWhiteSpace($decoded)) { $decoded = '/index.html' }
    $relative = $decoded.TrimStart('/').Replace('/', [IO.Path]::DirectorySeparatorChar)
    $file = [IO.Path]::GetFullPath((Join-Path $root $relative))

    $status = '200 OK'
    $body = $null
    $mime = 'text/plain; charset=utf-8'
    if (-not $file.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
      $status = '403 Forbidden'; $body = [Text.Encoding]::UTF8.GetBytes('403 Forbidden')
    } elseif (Test-Path $file -PathType Leaf) {
      $body = [IO.File]::ReadAllBytes($file); $mime = Get-Mime $file
    } else {
      $status = '404 Not Found'; $body = [Text.Encoding]::UTF8.GetBytes('404 Not Found')
    }

    $header = "HTTP/1.1 $status`r`nContent-Type: $mime`r`nContent-Length: $($body.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
    $headerBytes = [Text.Encoding]::ASCII.GetBytes($header)
    $stream.Write($headerBytes, 0, $headerBytes.Length)
    if ($method -ne 'HEAD') { $stream.Write($body, 0, $body.Length) }
    $stream.Flush()
  } catch {
    Write-Host $_.Exception.Message -ForegroundColor DarkYellow
  } finally {
    $client.Close()
  }
}
