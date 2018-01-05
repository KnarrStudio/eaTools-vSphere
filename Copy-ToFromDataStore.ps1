<#############################################
Script Name: DataStoreCopy.ps1
Author Name: Erik Arnesen
Version : 1.0
Mod Date: 9/14/2017
Contact : 836-9087
Copy of this file is located in S:\Scripts
 
.SYNOPSIS
 Requirements - PowerCLI 

 This scripts does the following:
 - Ask the user for a server name.  If no name is input, then it uses the primary DataStore (hard coded)
 - It sets the working location to the C:\Temp folder
 - The script will create a PSdrive named DS: and set-location to it.
 - It displays the files on the datastore and then asks you the direction to copy and selected file.

.DESCRIPTION
 Copies files to or from the datastore

.EXAMPLE
 DataStoreCopy.ps1 


Versions
1.0 New Script
1.1 Added a confirm statement
 
#############################################>

#Connect-viserver -Server 214.54.192.21

get-datastore | ft Name -AutoSize

$datastore = Read-Host("Enter the datastore from the list above")
$datastore = Get-Datastore $datastore

$dsName = Read-Host("Enter first three (3) charactors of the datastore")
New-PSDrive -Location  $datastore -name $dsName -PSProvider VimDatastore -Root ""

$NETlocation = $dsName + ":\"
Set-Location "C:\Temp" #$location

Get-ChildItem | ft Name -AutoSize

$copyFrom = Read-Host("From the list above select the file/folder you want to copy")
$copyTo = $NETlocation  # "c:\Temp\$copyFrom"

$copyTo = Read-Host("Enter the full path [default = $copyTo]")

Copy-DatastoreItem -Item $copyFrom+"\*" -Destination $copyTo -Force -Recurse



$g = "n"
$g = read-host("Would you like to disconnect? [n]")
if($g -eq "y"){disconnect-viserver}
