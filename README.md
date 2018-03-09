# xDSCVault #
## Overview ##

Pretty much every DSC module is designed to store credentials in the MOF and if configured in such a way you can configure it to encrypt those credentials. However, for my current environment we don't want any credentials stored in the DSC configuration MOFs.

To do this we are using a combination of Hasicorp's Terraform & Vault products to provision infrastructure. Each peice of infrastructure that requires access to secrets is provisioned with a unique Vault AppRole, policy and wrapped token.

Since the majority of the Microsoft based DSC modules are about 90% fit for purpose with the exception of the credential part basically all I am doing is taking this modules and rewriting them to get the secret from the Vault API then create the credentail object during processing instead of having them expect the credentials be present in the MOF

## Current modules

- xDSCVault_Download
	- Downloads a copy of the vault binary if for some reason you can't use the API to access the Vault endpoint
- xDSCVault_Unwrap
	- Checks to see if a wrapped token is still wrapped and if it is it will unwrap it and stores the AppRole and RoleID in the local Windows Credential Manager
	- All the subsequent modules are designed to obtain the credentials from the location this module saves them
- xDSCVault_Write
	- Writes secrets to the vault endpoint
- xDSCVault_LocalUser
	- Based on the local user module from [PSDSCResources](https://github.com/PowerShell/PSDscResources#user)
- xDSCVault_ADDomain
	- Based on the ADDomain module from [xActiveDirectory](https://github.com/PowerShell/xActiveDirectory#xaddomain)
- xDSCVault_WaitForADDomain
	- Based on the WaitForADDomain module from [xActiveDirectory](https://github.com/PowerShell/xActiveDirectory#xwaitforaddomain)
- xDSCVault_ADDomainController
	- Based on the ADDomainController module from [xActiveDirectory](https://github.com/PowerShell/xActiveDirectory#xaddomaincontroller)

## In-progress modules

## Planned

List of processes that I want to get working

- AD users
- Service accounts
- SQL clusters
- Octopus Deploy step template

## Resources

### VaultUnwrap
* **[String] VaultAddress** _(Required)_: URL to the Vault
* **[String] RoleID** _(Key)_: RoleID for the AppRole
* **[String] WrappedToken** _(Required)_: Wrapped token for the AppRole
```powershell
VaultUnwrap Unwrap
{
  RoleId = randomroleID
  WrappedToken = dee09a64-429b-619c-0466-9c108320105e
  VaultAddress = https://pathtovaultserver.com   
} 
```
    
### VaultWrite
* **[String] VaultAddress** _(Key)_: URL to the Vault
* **[String] VaultPath** _(Required)_: Path to where the credential will be written to in the Vault
* **[String] VaultValue** _(Key)_: Specify the value to be written
  * _Either a value must be specified or random secret must be $true_
* **[Boolean] RandomSecret** _(Required)_: Generate a random secret
  * _Either a value must be specified or random secret must be $true_
* **[Boolean] ForceUpdate** _(Required)_: Everytime the module runs it will write the value to Vault
```powershell
VaultWrite LocalAdministratorPassword
{
  VaultAddress = https://pathtovaultserver.com       
  VaultPath = "secret/path/somevalue-administrator"
  RandomSecret = $true
  ForceUpdate = $false
} 
```
### VaultLocalUser
* **[String] VaultAddress** _(Required)_: URL to the Vault
* **[String] UserName** _(Key)_: Indicates the account name for which you want to ensure a specific state.
* **[String] VaultPath** _(Required)_: Path to where the credential will be written to in the Vault
* **[String] Description** _(Write)_: Indicates the description you want to use for the user account.
* **[Boolean] Disabled** _(Write)_: Indicates if the account is disabled. Set this property to true to ensure that this account is disabled, and set it to false to ensure that it is enabled. The default value is false.
* **[String] Ensure** _(Write)_: Ensures that the feature is present or absent { *Present* | Absent }.
* **[String] FullName** _(Write)_: Represents a string with the full name you want to use for the user account.
* **[PSCredential] Password** _(Write)_: Indicates the password you want to use for this account.
* **[Boolean] PasswordChangeNotAllowed** _(Write)_: Indicates if the user can change the password. Set this property to true to ensure that the user cannot change the password, and set it to false to allow the user to change the password. The default value is false.
* **[Boolean] PasswordChangeRequired** _(Write)_: Indicates if the user must change the password at the next sign in. Set this property to true if the user must change their password. The default value is true.
* **[Boolean] PasswordNeverExpires** _(Write)_: Indicates if the password will expire. To ensure that the password for this account will never expire, set this property to true. The default value is false.
```powershell
VaultLocalUser LocalAdministratorPassword
{
  VaultAddress = https://pathtovaultserver.com       
  VaultPath = "secret/path/somevalue-administrator"
  Username = 'Administrator'
  PasswordNeverExpires = $true
  Ensure = 'Present'
}   
```
### VaultADDomain
* **[String] VaultAddress** _(Required)_: URL to the Vault
* **[String] DomainName** _(Key)_: Name of the domain.
  * If no parent name is specified, this is the fully qualified domain name for the first domain in the forest.
* **[String] ParentDomainName** _(Write)_: Fully qualified name of the parent domain
* **[String] DomainAdministratorUsername** _(Required)_: Credentials used to query for domain existence.
  * _Note: These are NOT used during domain creation._
* **[String] DomainAdministratorVaultPath** _(Required)_: Path to where the credential is located in the Vault
  * _Note: These are NOT used during domain creation._
* **[String] SafemodeAdministratorPasswordVaultPath** _(Required)_: Password for the administrator account when the computer is started in Safe Mode.
* **[String] DnsDelegationUserName** _(Write)_: Username used for creating DNS delegation.
* **[String] DnsDelegationVaultPath** _(Write)_: Path to the secret in vault to be used for DNS delegation 
* **[String] DomainNetBIOSName** _(Write)_: Specifies the NetBIOS name for the new domain.
  * If not specified, then the default is automatically computed from the value of the DomainName parameter.
* **[String] DatabasePath** _(Write)_: Specifies the fully qualified, non-Universal Naming Convention (UNC) path to a directory on a fixed disk of the local computer that contains the domain database.
* **[String] LogPath** _(Write)_: Specifies the fully qualified, non-UNC path to a directory on a fixed disk of the local computer where the log file for this operation will be written.
* **[String] SysvolPath** _(Write)_: Specifies the fully qualified, non-UNC path to a directory on a fixed disk of the local computer where the Sysvol file will be written.

```powershell
VaultADDomain FirstDS
{
    VaultAddress = https://pathtovaultserver.com
    DomainName = contoso.local
    SafemodeAdministratorPasswordVaultPath = "secret/path/somevalue-domainsafemode"
    DomainAdministratorUsername = 'Administrator'
    DomainAdministratorVaultPath = "secret/path/somevalue-administrator"
}
```
### VaultWaitForADDomain
* **[String] VaultAddress** _(Required)_: URL to the Vault
* **[String] DomainName** _(Key)_: Name of the domain.
* **[String] DomainUserUsername** _(Write)_: Credentials used to query for domain existence.
* **[String] DomainUserVaultPath** _(Write)_: Path to where the credential is located in the Vault
* **[Int] RetryIntervalSec** _(Write)_: Interval to check for the domain's existence.
* **[Int] RetryCount** _(Write)_: Maximum number of retries to check for the domain's existence.

```powershell
VaultWaitForADDomain DscForestWait
{
  VaultAddress = https://pathtovaultserver.com       
  DomainName = contoso.local
  DomainUserUsername = 'Administrator'
  DomainUserVaultPath = "secret/path/somevalue-administrator"
  RetryCount = 50
  RetryIntervalSec = 30
}
```
### VaultADDomainController
* **[String] VaultAddress** _(Required)_: URL to the Vault
* **[String] DomainName** _(Key)_: The fully qualified domain name for the domain where the domain controller will be present.
* **[String] DomainAdministratorCredential** _(Required)_: Specifies the credential for the account used to install the domain controller.
* **[String] SafemodeAdministratorPassword** _(Required)_: Password for the administrator account when the computer is started in Safe Mode.
* **[String] DatabasePath** _(Write)_: Specifies the fully qualified, non-Universal Naming Convention (UNC) path to a directory on a fixed disk of the local computer that contains the domain database.
* **[String] LogPath** _(Write)_: Specifies the fully qualified, non-UNC path to a directory on a fixed disk of the local computer where the log file for this operation will be written.
* **[String] SysvolPath** _(Write)_: Specifies the fully qualified, non-UNC path to a directory on a fixed disk of the local computer where the Sysvol file will be written.
* **[String] SiteName** _(Write)_: Specify the name of an existing site where new domain controller will be placed.
```powershell
VaultADDomainController SecondDC
{
  VaultAddress = https://pathtovaultserver.com       
  DomainName = contoso.local
  DomainAdministratorUsername = 'Administrator'
  DomainAdministratorVaultPath = "secret/path/somevalue-administrator"
  SafemodeAdministratorPasswordVaultPath = "secret/path/somevalue-domainsafemode"
}
```