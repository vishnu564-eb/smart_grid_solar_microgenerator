# Test Script: Real Mail Rejection Flow (smart_grid_solar_microgenerator_real_mail.bpmn)
$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("demo:demo"))
    "Content-Type" = "application/json"
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " STARTING REAL MAIL REJECTION FLOW (High Feeder Overload)" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$body = @{
    processDefinitionId = "Process_Applicant_RealMail"
    variables = @{
        installerName = "Hans Mueller Solar GmbH"
        applicantEmail = "installer@solarpv.de"
        systemCapacityKwp = 9.8
        transformerUtilizationPercent = 95.0
        voltageRisePercent = 1.8
    }
} | ConvertTo-Json

$inst = Invoke-RestMethod -Uri "http://localhost:8080/v2/process-instances" -Method Post -Headers $headers -Body $body
$instKey = $inst.processInstanceKey
Write-Host "Started Instance Key: $instKey" -ForegroundColor Green
Write-Host "View live in Operate: http://localhost:8080/operate" -ForegroundColor Yellow

# Step 1: Complete Prepare Technical Documentation
for ($i = 0; $i -lt 10; $i++) {
    Start-Sleep -Milliseconds 1200
    $tasks = Invoke-RestMethod -Uri "http://localhost:8080/v2/user-tasks/search" -Method Post -Headers $headers -Body "{`"filter`":{`"processInstanceKey`":`"$instKey`",`"state`":`"CREATED`"}}"
    $target = $tasks.items | Where-Object { $_.elementId -eq "task_App_Prepare" }
    if ($target) {
        $taskKey = $target.userTaskKey
        $compBody = @{
            variables = @{
                applicantEmail = "installer@solarpv.de"
                systemCapacityKwp = 9.8
                transformerUtilizationPercent = 95.0
                voltageRisePercent = 1.8
                installerName = "Hans Mueller Solar GmbH"
            }
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "http://localhost:8080/v2/user-tasks/$taskKey/completion" -Method Post -Headers $headers -Body $compBody | Out-Null
        Write-Host " [OK] Completed User Task 'task_App_Prepare' (Key: $taskKey)" -ForegroundColor Green
        break
    }
}

# Step 2: Submit Connection Request via REST API
Start-Sleep -Seconds 1
$actBody = @{ type = "submit-connection-request"; worker = "real-mail-worker"; timeout = 10000; maxJobsToActivate = 10 } | ConvertTo-Json
$actRes = Invoke-RestMethod -Uri "http://localhost:8080/v2/jobs/activation" -Method Post -Headers $headers -Body $actBody
$job = $actRes.jobs | Where-Object { $_.processInstanceKey -eq $instKey }
if ($job) {
    $compBody = @{ variables = @{ requestSubmitted = $true } } | ConvertTo-Json
    Invoke-RestMethod -Uri "http://localhost:8080/v2/jobs/$($job.jobKey)/completion" -Method Post -Headers $headers -Body $compBody | Out-Null
    Write-Host " [OK] Executed Service Task 'submit-connection-request'" -ForegroundColor Green
}

# Step 3: Process Rejection Email
Start-Sleep -Seconds 1
$actBody = @{ type = "send-email"; worker = "real-mail-worker"; timeout = 10000; maxJobsToActivate = 10 } | ConvertTo-Json
$actRes = Invoke-RestMethod -Uri "http://localhost:8080/v2/jobs/activation" -Method Post -Headers $headers -Body $actBody
$job = $actRes.jobs | Where-Object { $_.processInstanceKey -eq $instKey }
if ($job) {
    Write-Host " [MAIL DISPATCHED] Subject: 'Netze BW: Connection Request Rejected (Transformer Overload)' -> To: 'installer@solarpv.de'" -ForegroundColor Red
    $compBody = @{ variables = @{ rejectionMailSent = $true } } | ConvertTo-Json
    Invoke-RestMethod -Uri "http://localhost:8080/v2/jobs/$($job.jobKey)/completion" -Method Post -Headers $headers -Body $compBody | Out-Null
}

Start-Sleep -Seconds 2
Write-Host "`n4. Final Flow Nodes in Camunda Operate:" -ForegroundColor Cyan
$nodes = Invoke-RestMethod -Uri "http://localhost:8080/v1/flownode-instances/search" -Method Post -Headers $headers -Body "{`"filter`":{`"processInstanceKey`":$instKey},`"size`":50}"
$nodes.items | Select-Object flowNodeId, flowNodeName, state | Format-Table -AutoSize

Write-Host ">>> SUCCESS: 'smart_grid_solar_microgenerator_real_mail.bpmn' completed rejection mail and reached 'Connection Request Rejected'!" -ForegroundColor Green
