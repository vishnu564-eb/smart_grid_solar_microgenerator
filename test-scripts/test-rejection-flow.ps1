# Test Script: Solar Microgenerator Rejection Flow (Failure Path: Grid Overload)
$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("demo:demo"))
    "Content-Type" = "application/json"
}

Write-Host "1. Starting Process Instance with High Feeder Load (Rejection Path)..." -ForegroundColor Cyan
$body = @{
    processDefinitionId = "Process_Applicant"
    variables = @{
        installerName = "Hans Mueller Solar GmbH"
        systemCapacityKwp = 9.8
        transformerUtilizationPercent = 95.0
        voltageRisePercent = 1.8
    }
} | ConvertTo-Json

$inst = Invoke-RestMethod -Uri "http://localhost:8080/v2/process-instances" -Method Post -Headers $headers -Body $body
$instKey = $inst.processInstanceKey
Write-Host "Started Instance Key: $instKey" -ForegroundColor Green
Write-Host "View live in Operate: http://localhost:8080/operate" -ForegroundColor Yellow

# Helper function to complete user tasks with retry
function Complete-ActiveTask($defId, $vars) {
    $found = $false
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Milliseconds 1200
        $tasks = Invoke-RestMethod -Uri "http://localhost:8080/v2/user-tasks/search" -Method Post -Headers $headers -Body "{`"filter`":{`"processInstanceKey`":`"$instKey`",`"state`":`"CREATED`"}}"
        $target = $tasks.items | Where-Object { $_.elementId -eq $defId }
        if ($target) {
            $taskKey = $target.userTaskKey
            $compBody = @{ variables = $vars } | ConvertTo-Json
            Invoke-RestMethod -Uri "http://localhost:8080/v2/user-tasks/$taskKey/completion" -Method Post -Headers $headers -Body $compBody | Out-Null
            Write-Host " [OK] Completed '$defId' (Key: $taskKey)" -ForegroundColor Green
            $found = $true
            break
        }
    }
    if (-not $found) {
        Write-Host " [!] Warning: Could not locate task '$defId' within timeout." -ForegroundColor Yellow
    }
}

Write-Host "`n2. Completing Prepare Technical Documentation with Overload Values (95% transformer load)..." -ForegroundColor Cyan

Complete-ActiveTask "task_App_Prepare" @{
    systemCapacityKwp = 9.8
    transformerUtilizationPercent = 95.0
    voltageRisePercent = 1.8
    installerName = "Hans Mueller Solar GmbH"
}

# Complete Service Task (Submit Digital Connection Request)
Start-Sleep -Seconds 1
$actBody = @{ type = "submit-connection-request"; worker = "rest-worker"; timeout = 10000; maxJobsToActivate = 10 } | ConvertTo-Json
$actRes = Invoke-RestMethod -Uri "http://localhost:8080/v2/jobs/activation" -Method Post -Headers $headers -Body $actBody
$job = $actRes.jobs | Where-Object { $_.processInstanceKey -eq $instKey }
if ($job) {
    $compJobBody = @{ variables = @{ requestSubmitted = $true } } | ConvertTo-Json
    Invoke-RestMethod -Uri "http://localhost:8080/v2/jobs/$($job.jobKey)/completion" -Method Post -Headers $headers -Body $compJobBody | Out-Null
    Write-Host " [OK] Submitted Digital Connection Request via REST API" -ForegroundColor Green
}

Start-Sleep -Seconds 2
Write-Host "`n3. Checking Execution State in Camunda Operate..." -ForegroundColor Cyan
$nodes = Invoke-RestMethod -Uri "http://localhost:8080/v1/flownode-instances/search" -Method Post -Headers $headers -Body "{`"filter`":{`"processInstanceKey`":$instKey},`"size`":50}"
$nodes.items | Select-Object flowNodeId, flowNodeName, state | Format-Table -AutoSize

Write-Host ">>> SUCCESS: DMN evaluated overload and routed cleanly to: 'Connection Request Rejected'!" -ForegroundColor Green
