# Diccionario para almacenar el estado de los trabajos y sus detalles
$JobStatus = @{}

# Función para iniciar el servidor HTTP
function Start-HttpServer {
    param (
        [string[]]$prefixes
    )

    $listener = New-Object System.Net.HttpListener
    foreach ($prefix in $prefixes) {
        if (-not $prefix.EndsWith('/')) {
            $prefix += '/'
        }
        $listener.Prefixes.Add($prefix)
    }
    $listener.Start()

    Write-Host "Servidor HTTP iniciado. Escuchando en:" $prefixes

    while ($true) {
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            $responseString = ""

            if ($request.Url.AbsolutePath -eq "/ping/") {
                $responseString = ConvertTo-Json @{
                    message = "Solicitud recibida correctamente"
                    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                }
            } elseif ($request.Url.AbsolutePath -eq "/execute/") {
                $reader = New-Object IO.StreamReader $request.InputStream
                $body = $reader.ReadToEnd() | ConvertFrom-Json
                $command = $body.command

                $jobId = [guid]::NewGuid().ToString()
                $JobStatus[$jobId] = @{
                    Status = "Running"
                    Command = $command
                    StartTime = Get-Date
                    Job = $null
                    Output = $null
                }

                Write-Host "Ejecutando comando en segundo plano: $command"

                # Crear y ejecutar un job en segundo plano
                $job = Start-Job -ScriptBlock {
                    param($cmd)
                    try {
                        # Ejecutar el comando y capturar la salida
                        cmd.exe /c $cmd
                    } catch {
                        Write-Host "Error durante la ejecución del comando en segundo plano: $_"
                    }
                } -ArgumentList $command

                # Asociar el job al ID del trabajo
                $JobStatus[$jobId].Job = $job

                $responseString = ConvertTo-Json @{
                    jobId = $jobId
                    status = "Running"
                }
            } elseif ($request.Url.AbsolutePath -eq "/status/") {
                $jobId = $request.QueryString["jobId"]
                if ($JobStatus.ContainsKey($jobId)) {
                    $job = $JobStatus[$jobId].Job

                    if ($job -and (Get-Job -Id $job.Id -ErrorAction SilentlyContinue)) {
                        $jobState = $job.State

                        if ($jobState -eq "Completed") {
                            $output = Receive-Job -Id $job.Id
                            $JobStatus[$jobId].Status = "Completed"
                            $JobStatus[$jobId].Output = $output
                            Remove-Job -Id $job.Id
                        } elseif ($jobState -eq "Failed") {
                            $JobStatus[$jobId].Status = "Failed"
                            Remove-Job -Id $job.Id
                        } else {
                            $JobStatus[$jobId].Status = "Running"
                        }
                    } else {
                        $JobStatus[$jobId].Status = "Failed"
                        $JobStatus[$jobId].Output = "Job no encontrado o falló al iniciar."
                    }

                    $responseString = ConvertTo-Json @{
                        jobId = $jobId
                        status = $JobStatus[$jobId].Status
                        output = $JobStatus[$jobId].Output
                    }
                } else {
                    $responseString = ConvertTo-Json @{
                        error = "Job ID no encontrado"
                    }
                }
            } else {
                $responseString = ConvertTo-Json @{
                    error = "Ruta no encontrada"
                }
            }

            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
        } catch {
            Write-Host "Error en la gestión de la solicitud HTTP: $_"
            continue
        }
    }
}

# Iniciar el servidor HTTP
try {
    Start-HttpServer -prefixes @("http://+:8080/ping/", "http://+:8080/execute/", "http://+:8080/status/")
} catch {
    Write-Host "Error al iniciar el servidor HTTP: $_"
    throw
}
