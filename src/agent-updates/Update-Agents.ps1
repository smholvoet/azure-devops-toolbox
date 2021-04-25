$PAT = $env:PAT_SECRET
$Organization = $env:SYSTEM_COLLECTIONURI
$ApiVersion = '6.0'
 
function Get-Authentication {
        Write-Host "Initialize authentication context"

        $Token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))
        $Header = @{authorization = "Basic $Token"}
        return $Header
}

$Header = Get-Authentication

function Get-LatestRelease {

        $Uri = "https://api.github.com/repos/microsoft/azure-pipelines-agent/releases/latest"

        Write-Host "Fetching latest Azure Pipelines Agent release..."

        try 
        {
            $Response = Invoke-RestMethod -Uri $Uri `
                                          -Method Get `
                                          -ContentType "application/json" `
        } 
        catch 
        {
            Write-Host "URI": $Uri
            Write-Host "Status code:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "Exception reason:" $_.Exception.Response.ReasonPhrase
            Write-Host "Exception message:" $_.Exception.Message
        }                              
        
        Write-Host "Latest release:"
        Write-Host "- Name: $($Response.name)"
        Write-Host "- Release date: $($Response.published_at)"
        Write-Host "- Link: $($Response.html_url)"

        $LatestReleaseVersion = ($Response.name).TrimStart("v")
        return $LatestReleaseVersion
}

$LatestReleaseVersion = Get-LatestRelease

function Get-AgentPools {
        $Uri = "$($Organization)_apis/distributedtask/pools?api-version=$($ApiVersion)"

        Write-Host "Fetching agent pools in $($Organization)"

        try 
        {
            $Response = Invoke-RestMethod -Uri $Uri `
                                          -Method Get `
                                          -ContentType "application/json" `
                                          -Headers $Header
        } 
        catch 
        {
            Write-Host "URI": $Uri
            Write-Host "Status code:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "Exception reason:" $_.Exception.Response.ReasonPhrase
            Write-Host "Exception message:" $_.Exception.Message
        }   
        
        # Loop through all agent pools in org
        $Response.value | ForEach-Object {
                if(!$_.isHosted)
                {       
                        $AgentPoolId = $_.id
                        $AgentPoolName = $_.name

                        Get-AgentInfo -AgentPoolId $AgentPoolId `
                                      -AgentPoolName $AgentPoolName            
                }
        } 
}

function Get-AgentInfo {
        param (
        $AgentPoolId,
        $AgentPoolName
        )

        $Uri = "$($Organization)_apis/distributedtask/pools/$($AgentPoolId)/agents?includeAssignedRequest=true&api-version=$($ApiVersion)"
        
        try 
        {
            $Response = Invoke-RestMethod -Uri $Uri `
                                          -Method Get `
                                          -ContentType "application/json" `
                                          -Headers $Header
        } 
        catch 
        {
            Write-Host "URI": $Uri
            Write-Host "Status code:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "Exception reason:" $_.Exception.Response.ReasonPhrase
            Write-Host "Exception message:" $_.Exception.Message
        }   
        
        # Loop through all agents in the current pool
        $Response.value | ForEach-Object {
                if ($_.version -eq $LatestReleaseVersion)
                {
                        Write-Host "$($AgentPoolName)/$($_.name) is up to date: current = $($_.version) -> latest = $LatestReleaseVersion"
                }
                else {
                        Write-Host "$($AgentPoolName)/$($_.name) is outdated: current = $($_.version) -> latest = $LatestReleaseVersion"
                        if($_.status -eq 'offline') {
                                Write-Host "$($AgentPoolName)/$($_.name) is currently offline, unable to update"
                        }
                        # if an agent is currently running a request, they'll have an 'assignedRequest' object
                        elseif($null -ne $_.assignedRequest) {
                                Write-Host "$($AgentPoolName)/$($_.name) is currently running request $($_.assignedRequest.requestId), unable to update"       
                        }
                        else {
                                Write-Host "Updating $($AgentPoolName)/$($_.name)..."

                                Update-AgentVersion -PoolId $AgentPoolId `
                                                    -AgentId $_.id    
                        }
                }
        }
}

function Update-AgentVersion {
        param (
                $PoolId,
                $AgentId
        )
        
        $Uri = "$($Organization)_apis/distributedtask/pools/$($PoolId)/messages?agentId=$($AgentId)&api-version=$($ApiVersion)"

        try 
        {
            $Response = Invoke-RestMethod -Uri $Uri `
                                          -Method Post `
                                          -ContentType "application/json" `
                                          -Headers $Header
        } 
        catch 
        {
            Write-Host "URI": $Uri
            Write-Host "Status code:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "Exception reason:" $_.Exception.Response.ReasonPhrase
            Write-Host "Exception message:" $_.Exception.Message
        }   
}

Get-AgentPools