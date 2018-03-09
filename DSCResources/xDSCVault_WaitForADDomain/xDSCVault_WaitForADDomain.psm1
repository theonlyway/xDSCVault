# User name and password needed for this resource and Write-Verbose Used in helper functions
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()
$errorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultAddress,

        [System.String]
        $DomainAdministratorUsername,

        [System.String]
        $DomainUserVaultPath,

        [UInt64]$RetryIntervalSec = 60,

        [UInt32]$RetryCount = 10,
        
        [UInt32]$RebootRetryCount = 0,
        
        [System.String]
        $ApiPrefix = 'v1'
    )

    if ($DomainUserVaultPath)
    {
        $clientToken = Start-VaultAuth -VaultAddress $VaultAddress -ApiPrefix $ApiPrefix
        $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $DomainUserVaultPath -ApiPrefix $ApiPrefix
        $VaultValue = ConvertTo-SecureString -String $currentVaultValue.data.value -AsPlainText -Force
        $DomainUserCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList (("$DomainName" + '\' + "$DomainAdministratorUsername"), $VaultValue)
    }
    else
    {
        $DomainUserCredential = $null
    }
    
    $domain = Get-Domain -DomainName $DomainName -DomainUserCredential $DomainUserCredential
         
   
    $returnValue = @{
        DomainName           = $domain.Name
        DomainUserCredential = $DomainUserCredential
        RetryIntervalSec     = $RetryIntervalSec
        RetryCount           = $RetryCount
        RebootRetryCount     = $RebootRetryCount
    }
    
    $returnValue
}

function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultAddress,

        [System.String]
        $DomainAdministratorUsername,

        [System.String]
        $DomainUserVaultPath,

        [UInt64]$RetryIntervalSec = 60,

        [UInt32]$RetryCount = 10,
        
        [UInt32]$RebootRetryCount = 0,

        [System.String]
        $ApiPrefix = 'v1'

    )

    $rebootLogFile = "$env:temp\xWaitForADDomain_Reboot.tmp"

    $clientToken = Start-VaultAuth -VaultAddress $VaultAddress -ApiPrefix $ApiPrefix
    $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $DomainUserVaultPath -ApiPrefix $ApiPrefix
    $VaultValue = ConvertTo-SecureString -String $currentVaultValue.data.value -AsPlainText -Force
    $DomainUserCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList (("$DomainName" + '\' + "$DomainAdministratorUsername"), $VaultValue)
    
    for ($count = 0; $count -lt $RetryCount; $count++)
    {
        $domain = Get-Domain -DomainName $DomainName -DomainUserCredential $DomainUserCredential
         
        if ($domain)
        {
            if ($RebootRetryCount -gt 0)
            {
                Remove-Item $rebootLogFile -ErrorAction SilentlyContinue
            }
            
            break
        }
        else 
        {
            Write-Verbose -Message "Domain $DomainName not found. Will retry again after $RetryIntervalSec sec"
            Start-Sleep -Seconds $RetryIntervalSec
            Clear-DnsClientCache
        }    
    }

    if (-not $domain) 
    {
        if ($RebootRetryCount -gt 0)
        {
            [UInt32]$rebootCount = Get-Content $rebootLogFile -ErrorAction SilentlyContinue
            
            if ($rebootCount -lt $RebootRetryCount)
            {
                $rebootCount = $rebootCount + 1
                Write-Verbose -Message  "Domain $DomainName not found after $count attempts with $RetryIntervalSec sec interval. Rebooting.  Reboot attempt number $rebootCount of $RebootRetryCount."
                Set-Content -Path $rebootLogFile -Value $rebootCount
                $global:DSCMachineStatus = 1
            }
            else 
            {
                throw "Domain '$($DomainName)' NOT found after $RebootRetryCount Reboot attempts."
            }
        }
        else
        {
            throw "Domain '$($DomainName)' NOT found after $RetryCount attempts."
        }
    }
}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultAddress,

        [System.String]
        $DomainAdministratorUsername,

        [System.String]
        $DomainUserVaultPath,

        [UInt64]$RetryIntervalSec = 60,

        [UInt32]$RetryCount = 10,
        
        [UInt32]$RebootRetryCount = 0,

        [System.String]
        $ApiPrefix = 'v1'

    )
    
    $rebootLogFile = "$env:temp\xWaitForADDomain_Reboot.tmp"

    $clientToken = Start-VaultAuth -VaultAddress $VaultAddress -ApiPrefix $ApiPrefix
    $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $DomainUserVaultPath -ApiPrefix $ApiPrefix
    $VaultValue = ConvertTo-SecureString -String $currentVaultValue.data.value -AsPlainText -Force
    $DomainUserCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList (("$DomainName" + '\' + "$DomainAdministratorUsername"), $VaultValue)
    
    $domain = Get-Domain -DomainName $DomainName -DomainUserCredential $DomainUserCredential
   
    if ($domain)
    {
        if ($RebootRetryCount -gt 0)
        {
            Remove-Item $rebootLogFile -ErrorAction SilentlyContinue
        }
            
        $true
    }
    else 
    {
        $false
    }    
}



function Get-Domain
{
    [OutputType([PSObject])]
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [PSCredential]$DomainUserCredential

    )
    Write-Verbose -Message "Checking for domain $DomainName ..."
  
    if ($DomainUserCredential)
    {
        $context = New-Object -TypeName System.DirectoryServices.ActiveDirectory.DirectoryContext -ArgumentList ('Domain', $DomainName, $DomainUserCredential.UserName, $DomainUserCredential.GetNetworkCredential().Password)
    }
    else
    {
        $context = New-Object -TypeName System.DirectoryServices.ActiveDirectory.DirectoryContext -ArgumentList ('Domain', $DomainName)
    }
    
    try 
    {
        $domain = ([System.DirectoryServices.ActiveDirectory.DomainController]::FindOne($context)).domain.ToString()
        Write-Verbose -Message "Found domain $DomainName"
        $returnValue = @{
            Name = $domain
        }
    
        $returnValue
    }
    catch
    {
        Write-Verbose -Message "Domain $DomainName not found"
    }
}
