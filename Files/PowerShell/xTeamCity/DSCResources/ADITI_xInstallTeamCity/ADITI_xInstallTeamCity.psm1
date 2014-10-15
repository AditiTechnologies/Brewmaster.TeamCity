#
# xInstallTeamCity: DSC resource to install TeamCity.
#

#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
	param
	(	
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $DataDirectoryName,
		
		[parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $DataDiskDriveLetter,
		
		[parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ProductVersion,
		
		[parameter(Mandatory)]
		[Uint32] $TeamCityConnectionPort
  	)
    
    $retVal = @{ 
       TeamCityService = $s =  Get-Service | Where { $_.Name -eq "TeamCity" }; 
       TeamCityDataDirectory = "$DataDiskDriveLetter" + ":\" + "$DataDirectoryName";
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
        [ValidateNotNullOrEmpty()]
        [string] $DataDirectoryName,
		
		[parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $DataDiskDriveLetter,
		
		[parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ProductVersion,
		
		[parameter(Mandatory)]
		[Uint32] $TeamCityConnectionPort
  	)
   	
	$teamCityZipFileNameFmt = "$DataDiskDriveLetter" + ":\TeamCity-{0}.tar.gz"
    $teamCityTarFileNameFmt = "$DataDiskDriveLetter" + ":\TeamCity-{0}.tar"
    $teamCityDir = "$DataDiskDriveLetter" + ":\TeamCity"
    $teamCityDataDir = "$DataDiskDriveLetter" + ":\" + "$DataDirectoryName"	
    $teamCitySettings = "$teamCityDir\conf\server.xml"
    $teamCityDownloadUrl = [System.String]::Format("http://download.jetbrains.com/teamcity/TeamCity-{0}.tar.gz", $ProductVersion)    
    $teamCityZipFile = [System.String]::Format($teamCityZipFileNameFmt, $ProductVersion)
    $teamCityTarFile = [System.String]::Format($teamCityTarFileNameFmt, $ProductVersion)
    $outputDir = $DataDiskDriveLetter + ':\'
       
	$webClient = New-Object System.Net.WebClient
	$webClient.DownloadFile($teamCityDownloadUrl, $teamCityZipFile)
	$env:Path += ";${env:ProgramFiles(x86)}\7-zip"
	7z x "$teamCityZipFile" -o"$outputDir"
	7z x "$teamCityTarFile" -o"$outputDir"
	
	$settingsDoc = New-Object System.XML.XMLDocument
    $settingsDoc.Load($teamCitySettings)
    $node = $settingsDoc.SelectSingleNode("/Server/Service/Connector")
    $node.Attributes["port"].InnerText = $TeamCityConnectionPort
    $settingsDoc.Save($teamCitySettings)
	
	[Environment]::SetEnvironmentVariable("TEAMCITY_DATA_PATH", $teamCityDataDir, "Machine")
	$args = @( "install", "/runAsSystem", "/autorun=true", "/settings=$teamCityDir\conf\teamcity-server-service.xml")
	& "$teamCityDir\bin\TeamCityService.exe" $args
	net.exe start TeamCity
}

#
# The Test-TargetResource cmdlet.
#
function Test-TargetResource
{
	param
	(	
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $DataDirectoryName,
		
		[parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $DataDiskDriveLetter,
		
		[parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ProductVersion,
		
		[parameter(Mandatory)]
		[Uint32] $TeamCityConnectionPort
  	)
    
    $service =  Get-Service | Where { $_.Name -eq "TeamCity" }
	if($service -and ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running))
	{
		return $true
	}
	return $false
}

Export-ModuleMember -Function *-TargetResource