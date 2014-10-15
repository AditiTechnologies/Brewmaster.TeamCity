#
# xTeamCityFirstStart: DSC resource to configure TeamCity database.
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
        [boolean] $UseInternalDb
  	)
    
	$url =  [System.String]::Format("http://localhost:{0}/mnt", $TeamCityConnectionPort)
	$ret = Send-WebRequest -url $url -method "GET"	
    $retVal = @{ 
       DbSetupDone = !$ret.ResponseContent.Contains("<title>Database connection setup -- TeamCity</title>")
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
        [boolean] $UseInternalDb
  	)
   	
    if(!$UseInternalDb)
    {
        Write-Warning "Skipping database setup since internal HSQLDB database engine is not to be used. Please perform the database setup manually via teamcity web portal."
        return
    }

	$url =  [System.String]::Format("http://localhost:{0}/mnt", $TeamCityConnectionPort)
	$ret = Send-WebRequest -url $url -method "GET"
	$cookie = Get-Cookie -webResponse $ret.WebResponse
	$cookie.Domain = "localhost"
	
	$url =  [System.String]::Format("http://localhost:{0}/mnt/do/goNewDatabase", $TeamCityConnectionPort)
	$postData = "dbType=HSQLDB2&connHost=&connInst=&connDB=&connIntegratedSecurity=-&connUser=&connPwd=";
	$contentType = "application/x-www-form-urlencoded;charset=UTF-8"
	$ret = Send-WebRequest -url $url -method "POST" -cookie $cookie -content $postData -contentType $contentType
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
		[Uint32] $TeamCityConnectionPort,

        [parameter(Mandatory)]
        [boolean] $UseInternalDb
  	)
    
	$url =  [System.String]::Format("http://localhost:{0}/mnt", $TeamCityConnectionPort)
	$ret = Send-WebRequest -url $url -method "GET"    
	if($ret.ResponseContent.Contains("<title>TeamCity is starting -- TeamCity</title>") -or 
	   $ret.ResponseContent.Contains("<title>License Agreement -- TeamCity</title>"))
	{
		return $true
	}	
	return $false
}

function Send-WebRequest
{
	param
	(
		[string]$url,
		[string]$method,
		$cookie,
		[string]$content,
		[string]$contentType
	)
	[hashtable]$Return = @{}
	
	$request = [System.Net.WebRequest]::Create($url)
	$request.Method = $method;
	if($cookie)
	{
		$request.CookieContainer = New-Object System.Net.CookieContainer
		$request.CookieContainer.Add($cookie)
	}
    if($content)
	{		
		$encoding = New-Object System.Text.UTF8Encoding
		$byteArray = $encoding.GetBytes($content)
		$request.ContentType = $contentType
		$request.ContentLength = $byteArray.Length
		$dataStream = $request.GetRequestStream()
		$dataStream.Write($byteArray, 0, $byteArray.Length)
		$dataStream.Close()
	}	
	$response = $request.GetResponse()
	$responseStr = ""
	$reader = New-Object System.IO.StreamReader($response.GetResponseStream())
	$responseStr = $reader.ReadToEnd()
    $reader.Dispose()
	$Return.WebResponse = $response
	$Return.ResponseContent = $responseStr
	
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