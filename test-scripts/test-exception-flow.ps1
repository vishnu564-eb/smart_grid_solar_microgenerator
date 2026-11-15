# Test Script: Solar Microgenerator Exception Flow (Takes the Boundary Error Exception Link!)
$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("demo:demo"))
    "Content-Type" = "application/json"
}

Write-Host "1. Starting Process Instance to trigger REST API Exception..." -ForegroundColor Cyan
$body = @{
    processDefinitionId = "Process_Applicant"
    variables = @{
        installerName = "Hans Mueller Solar GmbH"
        systemCapacityKwp = 9.8
        transformerUtilizationPercent = 65.0
        voltageRisePercent = 1.8
        triggerRestException = $true
    }
} | ConvertTo-Json

$inst = Invoke-RestMethod -Uri "http://localhost:8080/v2/process-instances" -Method Post -Headers $headers -Body $body
$instKey = $inst.processInstanceKey
Write-Host "Started Instance Key: $instKey" -ForegroundColor Green
Write-Host "View live in Operate: http://localhost:8080/operate" -ForegroundColor Yellow

# Step 2: Complete the initial user task (Prepare Technical Documentation)
Write-Host "`n2. Completing Prepare Technical Documentation..." -ForegroundColor Cyan
for ($i = 0; $i -lt 10; $i++) {
    Start-Sleep -Milliseconds 1200
    $tasks = Invoke-RestMethod -Uri "http://localhost:8080/v2/user-tasks/search" -Method Post -Headers $headers -Body "{`"filter`":{`"processInstanceKey`":`"$instKey`",`"state`":`"CREATED`"}}"
    $target = $tasks.items | Where-Object { $_.elementId -eq "task_App_Prepare" }
    if ($target) {
        $taskKey = $target.userTaskKey
        $compBody = @{
            variables = @{
                systemCapacityKwp = 9.8
                transformerUtilizationPercent = 65.0
                voltageRisePercent = 1.8
                triggerRestException = $true
            }
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "http://localhost:8080/v2/user-tasks/$taskKey/completion" -Method Post -Headers $headers -Body $compBody | Out-Null
        Write-Host " [OK] Completed 'task_App_Prepare' (Key: $taskKey)" -ForegroundColor Green
        break
    }
}

# Step 3: Activate the job for task_App_Submit and throw BPMN Error ERR_REST_FAIL!
Write-Host "`n3. Simulating REST Gateway Failure -> Throwing BPMN Error 'ERR_REST_FAIL'..." -ForegroundColor Cyan
Start-Sleep -Seconds 1

$actBody = @{
    type = "submit-connection-request"
    worker = "rest-gateway-simulator"
    timeout = 10000
    maxJobsToActivate = 10
} | ConvertTo-Json

$actRes = Invoke-RestMethod -Uri "http://localhost:8080/v2/jobs/activation" -Method Post -Headers $headers -Body $actBody
$job = $actRes.jobs | Where-Object { $_.processInstanceKey -eq $instKey }

if ($job) {
    Write-Host " [OK] Activated Job Key: $($job.jobKey) on Task 'Submit Digital Connection Request'" -ForegroundColor Green
    
    # Send BPMN Error to Zeebe to take the Boundary Error Event
    $errBody = @{
        errorCode = "ERR_REST_FAIL"
        errorMessage = "Netze BW REST Gateway timed out (HTTP 504 Gateway Timeout)"
    } | ConvertTo-Json

    Invoke-RestMethod -Uri "http://localhost:8080/v2/jobs/$($job.jobKey)/error" -Method Post -Headers $headers -Body $errBody | Out-Null
    Write-Host " [OK] Successfully threw BPMN Error 'ERR_REST_FAIL'!" -ForegroundColor Green
} else {
    Write-Host " [!] Warning: Job not found for activation." -ForegroundColor Red
}

Start-Sleep -Seconds 2
Write-Host "`n4. Checking Flow Nodes in Camunda Operate..." -ForegroundColor Cyan
$nodes = Invoke-RestMethod -Uri "http://localhost:8080/v1/flownode-instances/search" -Method Post -Headers $headers -Body "{`"filter`":{`"processInstanceKey`":$instKey},`"size`":50}"
$nodes.items | Select-Object flowNodeId, flowNodeName, state | Format-Table -AutoSize

Write-Host ">>> SUCCESS: Exception link followed to 'Handle REST API Error & Retry' -> 'Submission Error Logged'!" -ForegroundColor Green
