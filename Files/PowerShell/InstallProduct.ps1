function GetScript
{
    param
    (
	    [string]$ProductId,
        [string]$Log
	)
    if(Test-Path "$env:ProgramW6432\Microsoft\Web Platform Installer\WebpiCmd.exe")
    {        
        $product = Get-Product -SearchOption "Installed" -ProductTitleOrId $ProductId
        $retVal = @{ WebDeployInstalled = !($product -eq $null) }
    }
    else
    {
        $retVal = @{
            WebDeployInstalled = $false;
            WebPINotAvailable = $true;
         }

    }
    return $retVal
}


function SetScript
{
    param
    (
	    [string]$ProductId,
        [string]$Log
	)
    $webpicmdexe = "$env:ProgramW6432\Microsoft\Web Platform Installer\WebpiCmd.exe"
    if(!(Test-Path $webpicmdexe))
    {
       throw "Web Platform Installer not available"
    }    
    $product = Get-Product -SearchOption "Available" -ProductTitleOrId $ProductId
    if($product -eq $null)
    {
       throw "Could not find any product with ID or Title matching with $ProductId"
    }
    Write-Verbose "Installing $ProductId"
    $arg = @( "/Install", "/Products:$ProductId", "/AcceptEula", "/SuppressReboot", "/Log:$Log")
    & $webpicmdexe $arg
}

function TestScript
{
    param
    (
	    [string]$ProductId,
        [string]$Log
	)
    if(Test-Path "$env:ProgramW6432\Microsoft\Web Platform Installer\WebpiCmd.exe")
    {       
       $product = Get-Product -SearchOption "Installed" -ProductTitleOrId $ProductId
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
    $webpicmdexe = "$env:ProgramW6432\Microsoft\Web Platform Installer\WebpiCmd.exe"
    $arg = @("/List", "/ListOption:$SearchOption")
    $list = & $webpicmdexe $arg
    foreach($entry in $list)
    {
        [hashtable]$product = @{}
        $split = $entry.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
        if($split.Length -eq 2)
        {
            $product.ID = $split[0]
            $product.Title = $split[1]
        }
        elseif($split.Length -gt 2) #The product title itself can have a space
        {
            $product.ID = $split[0]
            $product.Title = [System.String]::Join(' ', $split, 1, $split.Length - 1)
        }
        if(($product.ID -eq $ProductTitleOrId) -or ($product.Title -eq $ProductTitleOrId))
        {
            return $product
        }
    }
    return $null
}