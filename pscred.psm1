$ErrorActionPreference = "SilentlyContinue"
 #Encrypt Pass
 function Set-Pass{
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
 #Decrypt Pass
function Get-Pass{
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
#List Secrets
function Get-PassList{
if ($PSVersionTable.PSEdition -eq "Core"){
$HashPath = "$env:HOME\pscred"
} 
   
else {$HashPath = "$env:USERPROFILE\Documents\pscred"}   
If(!(test-path "$HashPath")){
New-Item -Path "$HashPath" -ItemType Directory
}
$hashes = Get-ChildItem $HashPath | Where-Object {$_.Name -like "hash*"} | Select-Object -ExpandProperty Name 
$Hashes_clean = ($hashes).trim('hash')
$Hashes_clean1 = ($hashes_clean).trim('_')
$creds = $Hashes_clean1 -replace ".{5}$" 
$CredHash = @{}
foreach ($cred in $creds){
$in = Get-Content -Raw "$HashPath\hash_$cred.json" | ConvertFrom-Json
$Description = $in.Description
$CredHash.add( $Cred, $Description)
}
$CredHashList = $CredHash | convertto-json 
Write-Host "secrets:
$CredHashlist 
" -ForegroundColor Green
}
#Remove Pass
function Remove-Pass{
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
#Export secrets so they can be transferred and decrypted on a different system
function Export-Pass{
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
$Hashes_clean = ($cred).trim('hash')
$Hashes_clean1 = ($hashes_clean).trim('_')
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
#Import exported secrets from another system
function Import-Pass{
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
$Hashes_clean = ($cred).trim('hash')
$Hashes_clean1 = ($hashes_clean).trim('_')
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
Write-host "All secrets are safe" -ForegroundColor Green
}

