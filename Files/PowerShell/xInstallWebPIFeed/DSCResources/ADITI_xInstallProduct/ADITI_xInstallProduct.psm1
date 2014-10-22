#
# xInstallProduct: DSC resource to install a product via WebPI.
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
        [string] $ProductTitleOrId
  	)
    
    if(Test-Path "$env:ProgramW6432\Microsoft\Web Platform Installer\WebpiCmd.exe")
    {
        $product = Get-Product -SearchOption "Installed" -ProductTitleOrId $ProductTitleOrId
        $retVal = @{
            ProductInstalled = !($product -eq $null)
        }
    }
    else
    {
        $retVal = @{
            ProductInstalled = $false;
            WebPINotAvailable = $true;
        }
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
        [string] $ProductTitleOrId
  	)
   	
	$webpicmdexe = "$env:ProgramW6432\Microsoft\Web Platform Installer\WebpiCmd.exe"
    if(!(Test-Path $webpicmdexe))
    {
        throw "Web Platform Installer not available"
    }
    $product = Get-Product -SearchOption "Available" -ProductTitleOrId $ProductTitleOrId
    if($product -eq $null)
    {
        throw "Could not find any product with ID or Title matching with $ProductTitleOrId"
    }
    Write-Verbose "Installing $ProductTitleOrId"
    $arg = @( "/Install", "/Products:$ProductTitleOrId", "/AcceptEula", "/SuppressReboot", "/Log:$env:BrewmasterDir\Logs\$ProductTitleOrId.log")
    & $webpicmdexe $arg
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
        [string] $ProductTitleOrId		
  	)
    
    if(Test-Path "$env:ProgramW6432\Microsoft\Web Platform Installer\WebpiCmd.exe")
    {
        $product = Get-Product -SearchOption "Installed" -ProductTitleOrId $ProductTitleOrId
        if($product)
        {
            return $true
        }
    }
    return $false
}

function Get-Product
{
    param
    (
        [string]$SearchOption,
        [string]$ProductTitleOrId
    )
    $list = webpicmd /list /ListOption:$SearchOption
    foreach($entry in $list)
    {
        [hashtable]$product = @{}
        $split = $entry.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
        if($split.Length -eq 2)
        {
            $product.ID = $split[0]
            $product.Title = $split[1]
        }
        elseif($split.Length -eq 3) #The product title itself can have a space
        {
            $product.ID = $split[0]
            $product.Title = [System.String]::Concat($split[1], $split[2])
        }
        if(($product.ID -eq $ProductTitleOrId) -or ($product.Title -eq $ProductTitleOrId))
        {
            return $product
        }
    }
    return $null
}

Export-ModuleMember -Function *-TargetResource