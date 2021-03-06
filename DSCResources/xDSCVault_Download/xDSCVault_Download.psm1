function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Version
    )

    $returnValue = @{
        Version = $Version
        URI     = ("https://releases.hashicorp.com/vault/" + $version + "/vault_" + $version + "_windows_amd64.zip")
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Version
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1
    
    $GetResource = Get-TargetResource -Version $Version
    [Net.ServicePointManager]::SecurityProtocol = [System.Security.Authentication.SslProtocols] "tls, tls11, tls12"
    Invoke-WebRequest -Uri $GetResource.URI -OutFile ("C:\Windows\Temp\Vault_" + $Version + ".zip")
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Version
    )

    if ((Test-Path -Path "C:\Windows\Temp\Vault_$Version.zip") -ne $true)
    {
        return $false       
    }
    else
    {
        return $true
    }
}


Export-ModuleMember -Function *-TargetResource