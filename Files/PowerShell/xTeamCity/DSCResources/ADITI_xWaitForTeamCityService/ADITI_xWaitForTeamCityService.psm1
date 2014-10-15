#
# xWaitForTeamCityService: DSC Resource that will wait for TeamCity service to start.
#

#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    param
    (	
        [parameter(Mandatory)]
		[Uint32] $TeamCityConnectionPort,

		[parameter(Mandatory)]
        [Uint32] $RetryCount,
		
        [parameter(Mandatory)]
		[Uint32] $RetryIntervalSec
    )

    @{
        TeamCityServiceName = "TeamCity"        
    }
}

#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    param
    (        
		[parameter(Mandatory)]
		[Uint32] $TeamCityConnectionPort,

		[parameter(Mandatory)]
        [Uint32] $RetryCount,
		
        [parameter(Mandatory)]
		[Uint32] $RetryIntervalSec
    )    

	$teamCityServiceRunning = $false
    $url =  [System.String]::Format("http://localhost:{0}/mnt", $TeamCityConnectionPort)
    for ($count = 0; $count -lt $RetryCount; $count++)
	{
        $teamCityServiceRunning = Check-TeamCityService
        $teamCityWebAccessible = Ping-TeamCityWeb -url $url
		if($teamCityWebAccessible -and $teamCityServiceRunning)
        {
            $teamCityServiceRunning = $true
            break
        }
		Write-Verbose -Message "TeamCity service not started yet. Will retry again after $RetryIntervalSec sec"
		Start-Sleep -Seconds $RetryIntervalSec
	}
	
	if (!$teamCityServiceRunning)
    {
        throw "TeamCity service not running after $count attempts with $RetryIntervalSec sec interval"
    }
}

# 
# Test-TargetResource
#
function Test-TargetResource  
{
    param
    (	
       [parameter(Mandatory)]
		[Uint32] $TeamCityConnectionPort,

		[parameter(Mandatory)]
        [Uint32] $RetryCount,
		
        [parameter(Mandatory)]
		[Uint32] $RetryIntervalSec
    )

    # Set-TargetResource is idempotent.. return false
    return $false
}

function Check-TeamCityService
{
    $service =  Get-Service | Where { $_.Name -eq "TeamCity" }
    if(!$service)
    {
        throw "Unable to find TeamCity service"
    }
	if($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running)
	{
       return $true
	}
    return $false
}

function Ping-TeamCityWeb
{
    param
    (
        [string]$url
    )
    try
    {        
        $request = [System.Net.WebRequest]::Create($url)
        $request.Method = "GET"
        $response = $request.GetResponse()
        if($resonse.StatusCode  -eq [System.Net.HttpStatusCode]::OK)
        {
            return $true
        }
    }
    catch
    {
        return $false
    }
    return $false
}