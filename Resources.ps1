$Version = New-xDscResourceProperty -Name Version -Type String -Attribute Key -Description "The Vault version to download"
$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present", "Absent"
#Now create the resource
New-xDscResource -Name xVaultDownload -Property $Version $Ensure -Path "C:\Users\Anthony\Documents\BitBucket\xDSCVault"

$Method = New-xDscResourceProperty -Name Method -Type String -Attribute Key -Description "Method to perform action. CLI or API" -ValidateSet "CLI", "API"
$WrappedToken = New-xDscResourceProperty -Name WrappedToken -Type String -Attribute Write -Description "Value of the wrapped token"
$VaultAddress = New-xDscResourceProperty -Name VaultAddress -Type String -Attribute Write -Description "Address of the Vault server"

#Now create the resource
New-xDscResource -Name xVaultUnwrap -Property $Method, $WrappedToken, $VaultAddress -Path "C:\Users\Anthony\Documents\BitBucket\xDSCVault"