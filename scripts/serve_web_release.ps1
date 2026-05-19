param(
    [int]$Port = 7357,
    [string]$Root = "build/web"
)

$rootPath = Resolve-Path $Root -ErrorAction Stop
$listener = [System.Net.HttpListener]::new()
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
}
catch {
    Write-Error "No se pudo iniciar el servidor en $prefix. Verifica si el puerto ya esta en uso y cierra el proceso anterior."
    $listener.Close()
    exit 1
}

$mimeTypes = @{
    '.html' = 'text/html; charset=utf-8'
    '.js' = 'application/javascript; charset=utf-8'
    '.css' = 'text/css; charset=utf-8'
    '.json' = 'application/json; charset=utf-8'
    '.wasm' = 'application/wasm'
    '.png' = 'image/png'
    '.jpg' = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.svg' = 'image/svg+xml'
    '.ico' = 'image/x-icon'
    '.txt' = 'text/plain; charset=utf-8'
    '.map' = 'application/json; charset=utf-8'
  }

Write-Host "Serving $rootPath on $prefix"
Write-Host 'Press Ctrl+C to stop.'

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $requestPath = $context.Request.Url.AbsolutePath.TrimStart('/')

        if ([string]::IsNullOrWhiteSpace($requestPath)) {
            $requestPath = 'index.html'
        }

        $localPath = Join-Path $rootPath $requestPath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)

        if (-not (Test-Path $localPath -PathType Leaf)) {
            $localPath = Join-Path $rootPath 'index.html'
        }

        $fileInfo = Get-Item $localPath
        $extension = $fileInfo.Extension.ToLowerInvariant()
        $contentType = $mimeTypes[$extension]

        if (-not $contentType) {
            $contentType = 'application/octet-stream'
        }

        $bytes = [System.IO.File]::ReadAllBytes($fileInfo.FullName)
        $response = $context.Response
        $response.StatusCode = 200
        $response.ContentType = $contentType
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        $response.OutputStream.Close()
    }
}
finally {
    if ($listener -and $listener.IsListening) {
        $listener.Stop()
    }
    $listener.Close()
}