#
# xTeamCityFirstStart: DSC resource to configure TeamCity first start.
#

#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
	param
	(
		[parameter(Mandatory)]
		[Uint32] $TeamCityConnectionPort
  	)
    
	$url =  [System.String]::Format("http://localhost:{0}/mnt", $TeamCityConnectionPort)
	$ret = Send-WebRequest -url $url -method "GET"	
    $retVal = @{ 
       FirstStartPerformed = !$ret.ResponseContent.Contains("<title>TeamCity First Start -- TeamCity</title>")
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
		[Uint32] $TeamCityConnectionPort
  	)
   	
	$url =  [System.String]::Format("http://localhost:{0}/mnt", $TeamCityConnectionPort)
	$ret = Send-WebRequest -url $url -method "GET"    
    if(!($ret.WebResponse.StatusCode  -eq [System.Net.HttpStatusCode]::OK))
    {
        throw $ret.ResponseContent
    }
	if($ret.ResponseContent.Contains("<title>Database connection setup -- TeamCity</title>"))
	{
		return
	}

	$cookie = Get-Cookie -webResponse $ret.WebResponse
	$cookie.Domain = "localhost"
	$url =  [System.String]::Format("http://localhost:{0}/mnt/do/goNewInstallation", $TeamCityConnectionPort)
	$ret = Send-WebRequest -url $url -method "POST" -cookie $cookie
	if(!($ret.WebResponse.StatusCode  -eq [System.Net.HttpStatusCode]::OK))
	{
		throw $ret.ResponseContent
	}
}

#
# The Test-TargetResource cmdlet.
#
function Test-TargetResource
{
	param
	(
		[parameter(Mandatory)]
		[Uint32] $TeamCityConnectionPort
  	)
    
	# Set-TargetResource is idempotent.. return false
    return $false
}

function Send-WebRequest
{
	param
	(
		[string]$url,
		[string]$method,
		$cookie
	)
	[hashtable]$Return = @{}
	
    Write-Verbose "Inside Send-WebRequest $url"
	$request = [System.Net.WebRequest]::Create($url)
	$request.Method = $method;	
	if($cookie)
	{
		$request.CookieContainer = New-Object System.Net.CookieContainer
		$request.CookieContainer.Add($cookie)
	}	
	
	$response = $request.GetResponse()    
	$responseStr = ""
	$reader = New-Object System.IO.StreamReader($response.GetResponseStream())
	$responseStr = $reader.ReadToEnd()
	$reader.Dispose()
	
	$Return.WebResponse = $response
	$Return.ResponseContent = $responseStr
    Write-Verbose $responseStr
	
	return $Return
}

function Get-Cookie
{
	param
	(
		$webResponse
	)
	$cookieVal = $webResponse.Headers["Set-Cookie"].Split(';')[0].Split('=')[1]
	$cookie = New-Object System.Net.Cookie("TCSESSIONID", $cookieVal)
	return $cookie
}

Export-ModuleMember -Function *-TargetResource