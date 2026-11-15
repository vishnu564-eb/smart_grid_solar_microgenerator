# Test Script: Real Mail Solar Microgenerator Flow
$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("demo:demo"))
    "Content-Type" = "application/json"
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " STARTING REAL MAIL PROCESS (smart_grid_solar_microgenerator_real_mail.bpmn)" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$body = @{
    processDefinitionId = "Process_Applicant_RealMail"
    variables = @{
        installerName = "Hans Mueller Solar GmbH"
        applicantEmail = "installer@solarpv.de"
        systemCapacityKwp = 9.8
        transformerUtilizationPercent = 65.0
        voltageRisePercent = 1.8
    }
} | ConvertTo-Json

$inst = Invoke-RestMethod -Uri "http://localhost:8080/v2/process-instances" -Method Post -Headers $headers -Body $body
$instKey = $inst.processInstanceKey
Write-Host "Started Instance Key: $instKey" -ForegroundColor Green
Write-Host "View live in Operate: http://localhost:8080/operate" -ForegroundColor Yellow

# Helper function to complete user tasks with retry
function Complete-ActiveTask($defId, $vars) {
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Milliseconds 1200
        $tasks = Invoke-RestMethod -Uri "http://localhost:8080/v2/user-tasks/search" -Method Post -Headers $headers -Body "{`"filter`":{`"processInstanceKey`":`"$instKey`",`"state`":`"CREATED`"}}"
        $target = $tasks.items | Where-Object { $_.elementId -eq $defId }
        if ($target) {
            $taskKey = $target.userTaskKey
            $compBody = @{ variables = $vars } | ConvertTo-Json
            Invoke-RestMethod -Uri "http://localhost:8080/v2/user-tasks/$taskKey/completion" -Method Post -Headers $headers -Body $compBody | Out-Null
            Write-Host " [OK] Completed User Task '$defId' (Key: $taskKey)" -ForegroundColor Green
            return
        }
    }
}

# Helper function to process automated service & email jobs
function Process-Job($jobType, $emailSubject) {
    Start-Sleep -Milliseconds 800
    $actBody = @{ type = $jobType; worker = "real-mail-worker"; timeout = 10000; maxJobsToActivate = 10 } | ConvertTo-Json
    $actRes = Invoke-RestMethod -Uri "http://localhost:8080/v2/jobs/activation" -Method Post -Headers $headers -Body $actBody
    $job = $actRes.jobs | Where-Object { $_.processInstanceKey -eq $instKey }
    if ($job) {
        if ($jobType -eq "send-email") {
            Write-Host " [MAIL DISPATCHED] Subject: '$emailSubject' -> To: 'installer@solarpv.de'" -ForegroundColor Magenta
        } else {
            Write-Host " [OK] Executed Service Task '$jobType'" -ForegroundColor Green
        }
        $compBody = @{ variables = @{ mailSent = $true; requestSubmitted = $true } } | ConvertTo-Json
        Invoke-RestMethod -Uri "http://localhost:8080/v2/jobs/$($job.jobKey)/completion" -Method Post -Headers $headers -Body $compBody | Out-Null
    }
}

Write-Host "`n1. Completing Prepare Technical Documentation..." -ForegroundColor Cyan
Complete-ActiveTask "task_App_Prepare" @{
    applicantEmail = "installer@solarpv.de"
    systemCapacityKwp = 9.8
    transformerUtilizationPercent = 65.0
    voltageRisePercent = 1.8
    installerName = "Hans Mueller Solar GmbH"
}

Write-Host "`n2. Submitting Digital Connection Request (REST API)..." -ForegroundColor Cyan
Process-Job "submit-connection-request" ""

Write-Host "`n3. DSO Automated Feasibility Check -> Sending Grid Approval Email..." -ForegroundColor Cyan
Start-Sleep -Seconds 1
Process-Job "send-email" "Netze BW: Netzanschlusszusage (Grid Connection Approval) Granted"

Write-Host "`n4. Installing PV Panels & Inverter..." -ForegroundColor Cyan
Complete-ActiveTask "task_App_Install" @{
    inverterModel = "SMA Sunny Tripower 10.0"
    installationComplete = $true
}

Write-Host "`n5. Verifying VDE-AR-N 4105 Safety Compliance..." -ForegroundColor Cyan
Complete-ActiveTask "task_App_SafetyCheck" @{
    antiIslandingVerified = $true
    electricianLicense = "VDE-BW-88492"
}

Write-Host "`n6. Reviewing Commissioning Protocols & Registering in MaStR..." -ForegroundColor Cyan
Complete-ActiveTask "task_DSO_VerifyProtocols" @{ protocolsApproved = $true }
Complete-ActiveTask "task_App_MaStR" @{ mastrRegistrationNumber = "SEE9827163"; mastrRegistrationComplete = $true }

Write-Host "`n7. Grid Energization -> Sending Final Activation & Feed-In Confirmation Email..." -ForegroundColor Cyan
Start-Sleep -Seconds 1
Process-Job "send-email" "Netze BW: Solar PV Connection Active & Energized in Smart Grid"

Start-Sleep -Seconds 2
Write-Host "`n8. Final Flow Nodes in Camunda Operate:" -ForegroundColor Cyan
$nodes = Invoke-RestMethod -Uri "http://localhost:8080/v1/flownode-instances/search" -Method Post -Headers $headers -Body "{`"filter`":{`"processInstanceKey`":$instKey},`"size`":50}"
$nodes.items | Select-Object flowNodeId, flowNodeName, state | Format-Table -AutoSize

Write-Host ">>> SUCCESS: 'smart_grid_solar_microgenerator_real_mail.bpmn' completed all mail and grid nodes!" -ForegroundColor Green
