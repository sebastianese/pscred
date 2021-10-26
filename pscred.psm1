$ErrorActionPreference = "SilentlyContinue"
 function Set-Pass{
<# 
    .Synopsis 
Set-Pass Saves a new password. Optionally a description can be added 
   
 
    .DESCRIPTION 
Set-Pass saves a new password with an optional description. The passwords are stored ecrypted using 
PowerShell's ConvertTo-SecureString cmdlet and can only be de-crypted by the same computer and user account that encrypted them.  
    
    .EXAMPLE 
Set-Pass -Name <Name> -Description <Description>
#> 
  Param(
   [Parameter(Mandatory=$True, ValueFromPipeline=$true)]
   [string]$Name,
   [Parameter(Mandatory=$False, ValueFromPipeline=$true)]
   [string]$Description

   )
if ($PSVersionTable.PSEdition -eq "Core"){
$HashPath = "$env:HOME\pscred"
} 
   
else {$HashPath = "$env:USERPROFILE\Documents\pscred"}
If(!(test-path "$HashPath")){
New-Item -Path "$HashPath" -ItemType Directory
}
$Value = Read-Host "Enter Secret" -AsSecureString
$ValueSecure = $Value | ConvertFrom-SecureString
$CredHash = @{}
$CredHash.add( $Name, $ValueSecure )
$CredHash.add( 'Description', $Description )
$json1 = $CredHash | ConvertTo-Json
Add-Content "$HashPath\hash_$Name.json" "$json1" 
Write-Host "Secret: $Name was encrypted and saved!" -ForegroundColor Green
 }

function Get-Pass{
<# 
    .Synopsis 
Get-Pass Gets the value of a stored password and places it on the clipboard 
   
 
    .DESCRIPTION 
Get-Pass Gets the value of a stored password and places it on the clipboard
TIP: It can be piped to Get-Clipboard to pass the password to a script
Ex: $MyPass = Get-Pass server1 | Get-Clipboard 
    
    .EXAMPLE 
Get-Pass -Name <Name>
#> 
 Param(
   [Parameter(Mandatory=$True, ValueFromPipeline=$true)]
   [string]$Name
   )
if ($PSVersionTable.PSEdition -eq "Core"){
$HashPath = "$env:HOME\pscred"
} 
   
else {$HashPath = "$env:USERPROFILE\Documents\pscred"}   
If(!(test-path "$HashPath")){
New-Item -Path "$HashPath" -ItemType Directory
}
$in = Get-Content -Raw "$HashPath\hash_$Name.json" | ConvertFrom-Json
if ($null -eq $in){
Write-host "Password:$Name does not exist" -ForegroundColor Red
}
$secure = ConvertTo-SecureString $in.$Name
$newcred = New-Object -TypeName PSCredential $in.$Name,$secure
$Token_clear = $newcred.GetNetworkCredential().Password
Set-Clipboard $Token_clear 
}

function Get-PassList{
   <# 
    .Synopsis 
Get-PassList gets a list of all stored passwords
   
 
    .DESCRIPTION 
Get-PassList gets a list of all stored passwords and their description 
    
    .EXAMPLE 
    Get-PassList
#> 
if ($PSVersionTable.PSEdition -eq "Core"){
$HashPath = "$env:HOME\pscred"
} 
   
else {$HashPath = "$env:USERPROFILE\Documents\pscred"}   
If(!(test-path "$HashPath")){
New-Item -Path "$HashPath" -ItemType Directory
}
$version = '
                            __      ___ ___
   ___  ___ ___________ ___/ / _  _<  /<  /
  / _ \(_-</ __/ __/ -_) _  / | |/ / / / / 
 / .__/___/\__/_/  \__/\_,_/  |___/_(_)_/  
/_/                                        
'
$hashes = Get-ChildItem $HashPath | Where-Object {$_.Name -like "hash*"} | Sort-Object -Property Name | Select-Object -ExpandProperty Name 
$Hashes_clean1 = $hashes.substring(5) 
$creds = $Hashes_clean1 -replace ".{5}$" 
$CredHash = @{}
foreach ($cred in $creds){
$in = Get-Content -Raw "$HashPath\hash_$cred.json" | ConvertFrom-Json
$Description = $in.Description
$CredHash.add( $Cred, $Description)
}
$CredHashList = $CredHash | convertto-json 
Write-Host "$version
secrets:
$CredHashlist 
" -ForegroundColor Green
}

function Remove-Pass{
<# 
    .Synopsis 
   Remove-Pass removes a stored password
   
 
    .DESCRIPTION 
   Remove-Pass removes a stored password (can not be reverted)
    
    .EXAMPLE 
    Remove-Pass -Name <Name>
#> 
 Param(
   [Parameter(Mandatory=$True, ValueFromPipeline=$true)]
   [string]$Name
   )
if ($PSVersionTable.PSEdition -eq "Core"){
$HashPath = "$env:HOME\pscred"
} 
else {$HashPath = "$env:USERPROFILE\Documents\pscred"}      
If(!(test-path "$HashPath")){
New-Item -Path "$HashPath" -ItemType Directory
}

if (!(test-path "$HashPath\hash_$Name.json" )){
Write-host "Password:$Name does not exist" -ForegroundColor Red
break
}
Remove-Item "$HashPath\hash_$Name.json"
Write-Host "secret: $Name was removed" -ForegroundColor Green
}

function Export-Pass{
<# 
    .Synopsis 
Export-Pass creates a folder with all passwords (encrypted hashes) that can be imported on a different system. 
   
   
 
    .DESCRIPTION 
Export-Pass creates a folder with all passwords (encrypted hashes) that can be imported on a different system.
An 8 digit PIN will be requested and the same PIN will be needed to import the passwords to the new system
    
    .EXAMPLE 
Export-Pass 
#> 
if ($PSVersionTable.PSEdition -eq "Core"){
$HashPath = "$env:HOME\pscred"
$ExportPath = "$env:HOME\pscred\pscredexport"
} 

else {$HashPath = "$env:USERPROFILE\Documents\pscred"   
$ExportPath = "$env:USERPROFILE\Documents\pscred\pscredexport"}
if (Test-Path $ExportPath){
Remove-Item $ExportPath -Recurse
}

New-Item -ItemType Directory -Path $ExportPath
$Key = Read-Host "Enter a 8 Digit PIN" -AsSecureString
$secure = $key  | ConvertFrom-SecureString
$newcred = New-Object -TypeName PSCredential $secure,$key
$Token_clear = $newcred.GetNetworkCredential().Password
if(!($Token_clear.length -eq "8")){
Write-Host "PIN should be 8 digits long."
break 
}

if(!($Token_clear -match "^\d+$")){
Write-Host "PIN should only contain numbers"
break
}

$creds = Get-ChildItem $HashPath | Where-Object {$_.Name -like "*.json"} | Select-Object -ExpandProperty Name
foreach ($cred in $creds){
$in = Get-Content -Raw $HashPath\$cred | ConvertFrom-Json
$Hashes_clean1 = $cred.substring(5)
$name = $Hashes_clean1 -replace ".{5}$"
$TokenSecure = ConvertTo-SecureString $in.$Name
$newcred = New-Object -TypeName PSCredential $in.$Name,$TokenSecure
$Token_clear = $newcred.GetNetworkCredential().Password
$ValueSecure = $Token_clear | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -SecureKey $Key
$Description = $in.Description
$CredHash = @{}
$CredHash.add( $Name, $ValueSecure )
$CredHash.add( 'Description', $Description )
$json1 = $CredHash | ConvertTo-Json
Add-Content "$ExportPath\hash_$Name.json" "$json1" 
}

Write-host "Export completed ++++++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-host "Move the pscredexport folder to the target system 
pscredexport folder path: $ExportPath" -ForegroundColor Green
Write-host "Then install pscred and run Import-Pass" -ForegroundColor Green
}

function Import-Pass{
<# 
    .Synopsis 
Import-Pass imports the passwords exported from a different system 
   
   
 
    .DESCRIPTION 
Import-Pass imports the passwords exported from a different system 
An 8 digit PIN will be requested (this is the same PIN used when running the Export-Pass command on the source system)
    
    .EXAMPLE 
Import-Pass 
#> 
if ($PSVersionTable.PSEdition -eq "Core"){
$HashPath = "$env:HOME\pscred"
} 
else {$HashPath = "$env:USERPROFILE\Documents\pscred"
$HashPath = "$env:USERPROFILE\Documents\pscred"
}   
$ExportPath = Read-Host "Enter the location of the pscredexport folder (Example-> C:\users\username\desktop)" 
$ExportFolder = "$ExportPath\pscredexport"
if (!(test-path $ExportFolder )){
Write-host "The pscredexport folder was not found on: $ExportFolder " -ForegroundColor Red
break
}

$Key = Read-Host "Enter a 8 Digit PIN" -AsSecureString
$secure = $key  | ConvertFrom-SecureString
$newcred = New-Object -TypeName PSCredential $secure,$key
$Token_clear = $newcred.GetNetworkCredential().Password
if(!($Token_clear.length -eq "8")){
Write-Host "PIN should be 8 digits long."
break 
}

if(!($Token_clear -match "^\d+$")){
Write-Host "PIN should only contain numbers"
break
}

If(!(test-path "$HashPath")){
New-Item -Path "$HashPath" -ItemType Directory
}

$creds = Get-ChildItem $ExportFolder | Where-Object {$_.Name -like "*.json"} | Select-Object -ExpandProperty Name
foreach ($cred in $creds){
$in = Get-Content -Raw $ExportFolder\$cred | ConvertFrom-Json
$Hashes_clean1 = $cred.substring(5)
$name = $Hashes_clean1 -replace ".{5}$"
$TokenSecure = ConvertTo-SecureString $in.$Name -SecureKey $Key
$newcred = New-Object -TypeName PSCredential $in.$Name,$TokenSecure
$Token_clear = $newcred.GetNetworkCredential().Password
$ValueSecure = $Token_clear | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
$Description = $in.Description
$CredHash = @{}
$CredHash.add( $Name, $ValueSecure )
$CredHash.add( 'Description', $Description )
$json1 = $CredHash | ConvertTo-Json
Add-Content "$HashPath\hash_$Name.json" "$json1" 
}
Write-host "Import completed ++++++++++++++++++++++++++++++++++++" -ForegroundColor Green
}

