function ExecRetry($command, $maxRetryCount = 10, $retryInterval=2)
{
    $currErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    $retryCount = 0
    while ($true)
    {
        try 
        {
            & $command
            break
        }
        catch [System.Exception]
        {
            $retryCount++
            if ($retryCount -ge $maxRetryCount)
            {
                $ErrorActionPreference = $currErrorActionPreference
                throw
            }
            else
            {
                Write-Error $_.Exception
                Start-Sleep $retryInterval
            }
        }
    }

    $ErrorActionPreference = $currErrorActionPreference
}

function GitClonePull($path, $url, $branch="master")
{
    Write-Host "Calling GitClonePull with path=$path, url=$url, branch=$branch"
    if (!(Test-Path -path $path))
    {
        ExecRetry {
            git clone $url $path
            if ($LastExitCode) { throw "git clone failed - GitClonePull - Path does not exist!" }
        }
        pushd $path
        git checkout $branch
        git pull
        popd
        if ($LastExitCode) { throw "git checkout failed - GitCLonePull - Path does not exist!" }
    }else{
        pushd $path
        try
        {
            ExecRetry {
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue "$path\*"
                git clone $url $path
                if ($LastExitCode) { throw "git clone failed - GitClonePull - After removing existing Path.." }
            }
            ExecRetry {
                (git checkout $branch) -Or (git checkout master)
                if ($LastExitCode) { throw "git checkout failed - GitClonePull - After removing existing Path.." }
            }

            Get-ChildItem . -Include *.pyc -Recurse | foreach ($_) {Remove-Item $_.fullname}

            git reset --hard
            if ($LastExitCode) { throw "git reset failed!" }

            git clean -f -d
            if ($LastExitCode) { throw "git clean failed!" }

            ExecRetry {
                git pull
                if ($LastExitCode) { throw "git pull failed!" }
            }
        }
        finally
        {
            popd
        }
    }
}

function destroy_planned_vms() {
    $planned_vms = [array] (gwmi -ns root/virtualization/v2 -class Msvm_PlannedComputerSystem)
    $svc = gwmi -ns root/virtualization/v2 -class Msvm_VirtualSystemManagementService

    $pvm_count = $planned_vms.Count
    log_message "Found $pvm_count planned vms."
    foreach($pvm in $planned_vms) {
        $svc.DestroySystem($pvm)
    }
}

function log_message($message){
    echo "[$(Get-Date)] $message"
}
