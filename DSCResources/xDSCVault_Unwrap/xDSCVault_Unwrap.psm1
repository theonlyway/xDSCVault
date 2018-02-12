function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('CLI', 'API')]
        [System.String]
        $VaultMethod,

        [parameter(Mandatory = $true)]        
        [System.String]
        $WrappedToken,

        [parameter(Mandatory = $true)]        
        [System.String]
        $RoleId,

        [parameter(Mandatory = $true)]        
        [System.String]
        $VaultAddress,

        [System.String]
        $CliPath = $null,
   
        [System.String]
        $ApiPrefix = 'v1'
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    $returnValue = @{
        VaultMethod  = $VaultMethod
        WrappedToken = $WrappedToken
        RoleId       = $RoleId
        VaultAddress = $VaultAddress
        CliPath      = $CliPath
        ApiPrefix    = $ApiPrefix
        ApiPath      = ($VaultAddress + '/' + $ApiPrefix + '/')
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('CLI', 'API')]
        [System.String]
        $VaultMethod,

        [parameter(Mandatory = $true)]        
        [System.String]
        $WrappedToken,

        [parameter(Mandatory = $true)]        
        [System.String]
        $RoleId,

        [parameter(Mandatory = $true)]        
        [System.String]
        $VaultAddress,

        [System.String]
        $CliPath = $null,
   
        [System.String]
        $ApiPrefix = 'v1'
    )

    $result = [string]::Empty

    $resourceData = Get-TargetResource -VaultMethod $VaultMethod -WrappedToken $WrappedToken -RoleId $RoleId -VaultAddress $VaultAddress -CliPath $CliPath -ApiPrefix $ApiPrefix
    if ($VaultMethod -eq 'CLI')
    {
        Write-Verbose -Message 'CLI method selected'
    }
    else
    {
        Write-Verbose -Message 'API method selected'
        $unwrapApi = ($resourceData.ApiPath + 'sys/wrapping/unwrap')
        $headers = New-Object -TypeName 'System.Collections.Generic.Dictionary[[String],[String]]'
        $headers.Add('X-Vault-Token', $resourceData.WrappedToken)
        $result = Invoke-RestMethod -Method Post -Uri $unwrapApi -Headers $headers
        $resourceData.VaultAddress -match '(?<=://).+'
        New-StoredCredential -Target $resourceData.VaultAddress -Type Generic -UserName $resourceData.RoleId -Password $($result.data.secret_id) -Persist LocalMachine
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('CLI', 'API')]
        [System.String]
        $VaultMethod,

        [parameter(Mandatory = $true)]        
        [System.String]
        $WrappedToken,

        [parameter(Mandatory = $true)]        
        [System.String]
        $RoleId,

        [parameter(Mandatory = $true)]        
        [System.String]
        $VaultAddress,

        [System.String]
        $CliPath = $null,
   
        [System.String]
        $ApiPrefix = 'v1'
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    if ($VaultMethod -eq 'CLI')
    {
        Write-Verbose -Message 'CLI method selected'
        if ($CliPath -ne $null)
        {
            if ((Test-Path -Path $CliPath) -eq $true)
            {
                try
                {
                    Write-Verbose -Message "Checking DNS for $VaultAddress"
                    $regex = $VaultAddress -match '(?<=://).+'
                    $dns = Resolve-DnsName -Name $matches[0] -ErrorAction Stop
                    if ((Get-StoredCredential | Where-Object -FilterScript {
                                $_.UserName -eq $RoleId
                            }) -ne $null) 
                    {
                        Write-Verbose -Message 'Credential found in credential manager'
                        return $true
                    }
                    else 
                    {
                        Write-Verbose -Message 'Credential not found in credential manager'
                        return $false
                    }
                }
                catch
                {
                    if ($_.Exception -match 'DNS name does not exist' )
                    {
                        Write-Error -Message 'Vault address could not be resolved'
                        return $false
                    }
                    else
                    {
                        "Error was $_"
                        $line = $_.InvocationInfo.ScriptLineNumber
                        "Error was in Line $line"
                        return $false
                    }
                }
            }
            else
            {
                return $false
            }
        }
        else
        {
            Write-Error -Message 'Cli path is null'
            return $false
        }
    }
    else
    {
        Write-Verbose -Message 'API method selected'
        try
        {
            Write-Verbose -Message "Checking DNS for $VaultAddress"
            $regex = $VaultAddress -match '(?<=://).+'
            $dns = Resolve-DnsName -Name $matches[0] -ErrorAction Stop
            if ((Get-StoredCredential -WarningAction SilentlyContinue | Where-Object -FilterScript {
                        $_.UserName -eq $RoleId
                    }) -ne $null) 
            {
                Write-Verbose -Message 'Credential found in credential manager'
                return $true
            }
            else 
            {
                Write-Verbose -Message 'Credential not found in credential manager'
                return $false
            }
        }
        catch
        {
            if ($_.Exception -match 'DNS name does not exist' )
            {
                Write-Error -Message 'Vault address could not be resolved'
                return $false
            }
            else
            {
                "Error was $_"
                $line = $_.InvocationInfo.ScriptLineNumber
                "Error was in Line $line"
                return $false
            }
        }
    }
}

Export-ModuleMember -Function *-TargetResource
