$Version = New-xDscResourceProperty -Name Version -Type String -Attribute Key -Description 'The Vault version to download'
#Now create the resource
New-xDscResource -Name xDSCVault_Download -FriendlyName VaultDownload -Property $Version -Path 'C:\Users\Anthony\Documents\BitBucket\xDSCVault' -Force
Test-xDscSchema -Path 'C:\Users\Anthony\Documents\BitBucket\xDSCVault\DSCResources\xDSCVault_Download\xDSCVault_Download.schema.mof'


$WrappedToken = New-xDscResourceProperty -Name WrappedToken -Attribute Key -Type String -Description 'Value of the wrapped token'
$Method = New-xDscResourceProperty -Name VaultMethod -Attribute Required -Type String -Description 'Method to perform action. CLI or API' -ValueMap 'Api', 'Cli' -Values 'Api', 'Cli'
$VaultAddress = New-xDscResourceProperty -Name VaultAddress -Type String -Attribute Required -Description 'Address of the Vault server'
$cliPath = New-xDscResourceProperty -Name CliPath -Type String -Attribute Write -Description 'Path to the vault binary'
$ApiPrefix = New-xDscResourceProperty -Name ApiPrefix -Type String -Attribute Write -Description 'Version of the API to use'

#Now create the resource
New-xDscResource -Name xDSCVault_Unwrap -FriendlyName VaultUnwrap -Property $WrappedToken, $Method, $VaultAddress, $cliPath, $ApiPrefix -Path 'C:\Users\Anthony\Documents\BitBucket\xDSCVault' -Force
Test-xDscSchema -Path 'C:\Users\Anthony\Documents\BitBucket\xDSCVault\DSCResources\xDSCVault_Unwrap\xDSCVault_Unwrap.schema.mof'


$Method = New-xDscResourceProperty -Name VaultMethod -Attribute Required -Type String -Description 'Method to perform action. CLI or API' -ValueMap 'Api', 'Cli' -Values 'Api', 'Cli'
$VaultAddress = New-xDscResourceProperty -Name VaultAddress -Type String -Attribute Required -Description 'Address of the Vault server'
$cliPath = New-xDscResourceProperty -Name CliPath -Type String -Attribute Write -Description 'Path to the vault binary'
$ApiPrefix = New-xDscResourceProperty -Name ApiPrefix -Type String -Attribute Write -Description 'Version of the API to use'
$VaultPath = New-xDscResourceProperty -Name VaultPath -Type String -Attribute Key -Description 'Vault path to create the secret'
$VaultValue = New-xDscResourceProperty -Name VaultValue -Type String -Attribute Write -Description 'Value for the secret'
$ApiPath = New-xDscResourceProperty -Name ApiPath -Type String -Attribute Read -Description 'Complete API path'
$RandomSecret = New-xDscResourceProperty -Name RandomSecret -Type Boolean -Attribute Required -Description 'Generate a strong random secret'
$ForceUpdate = New-xDscResourceProperty -Name ForceUpdate -Type Boolean -Attribute Required -Description 'Force the secret to be updated'

#Now create the resource
New-xDscResource -Name xDSCVault_Write -FriendlyName VaultWrite -Property $Method, $VaultAddress, $VaultPath, $VaultValue, $cliPath, $ApiPrefix, $ApiPath, $RandomSecret, $ForceUpdate -Path 'C:\Users\Anthony\Documents\BitBucket\xDSCVault' -Force
Test-xDscSchema -Path 'C:\Users\Anthony\Documents\BitBucket\xDSCVault\DSCResources\xDSCVault_Write\xDSCVault_Write.schema.mof'

$UserName = New-xDscResourceProperty -Name UserName -Attribute Key -Type String -Description 'Indicates the account name for which you want to ensure a specific state'
$Description = New-xDscResourceProperty -Name Description -Attribute Write -Type String -Description 'Indicates the description you want to use for the user account'
$Disabled = New-xDscResourceProperty -Name Disabled -Type Boolean -Attribute Required -Description 'Value used to disable/enable a user account'
$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Required -Description 'Ensures that the feature is present or absent' -ValueMap 'Present', 'Absent' -Values 'Present', 'Absent'
$FullName = New-xDscResourceProperty -Name FullName -Type String -Attribute Write -Description 'Value used to disable/enable a user account'
$PasswordChangeNotAllowed = New-xDscResourceProperty -Name PasswordChangeNotAllowed -Type Boolean -Attribute Required -Description 'Indicates if the user can change the password'
$PasswordChangeRequired = New-xDscResourceProperty -Name PasswordChangeRequired -Type Boolean -Attribute Required -Description 'Indicates if the user must change the password at the next sign in'
$PasswordNeverExpires = New-xDscResourceProperty -Name PasswordNeverExpires -Type Boolean -Attribute Required -Description 'Indicates if the password will expire'
$VaultPath = New-xDscResourceProperty -Name VaultPath -Type String -Attribute Key -Description 'Vault path to create the secret'
$VaultAddress = New-xDscResourceProperty -Name VaultAddress -Type String -Attribute Required -Description 'Address of the Vault server'
$Method = New-xDscResourceProperty -Name VaultMethod -Attribute Required -Type String -Description 'Method to perform action. CLI or API' -ValueMap 'Api', 'Cli' -Values 'Api', 'Cli'
$ApiPrefix = New-xDscResourceProperty -Name ApiPrefix -Type String -Attribute Write -Description 'Version of the API to use'
$ApiPath = New-xDscResourceProperty -Name ApiPath -Type String -Attribute Read -Description 'Complete API path'
$cliPath = New-xDscResourceProperty -Name CliPath -Type String -Attribute Write -Description 'Path to the vault binary'


#Now create the resource
New-xDscResource -Name xDSCVault_LocalUser -FriendlyName VaultLocalUser -Property $Method, $VaultAddress, $VaultPath, $cliPath, $ApiPrefix, $ApiPath, `
    $UserName, $Description, $Disabled, $Ensure, $FullName, $PasswordChangeNotAllowed, $PasswordChangeRequired, $PasswordNeverExpires -Path 'C:\Users\Anthony\Documents\BitBucket\xDSCVault' -Force
Test-xDscSchema -Path 'C:\Users\Anthony\Documents\BitBucket\xDSCVault\DSCResources\xDSCVault_LocalUser\xDSCVault_LocalUser.schema.mof'