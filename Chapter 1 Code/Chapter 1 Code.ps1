		Listing 1.1	Sample script for an automated installation of vCenter Server

#Install vCenter Server unattended
$VCMedia = “D:\vCenter-Server”
$SVC_USER = "WIN_VCENTER6\vCenter"
$SVC_PASS = "VMw@re123"
$FQDN = "MGMT-VC6.contoso.com"
$VcIP = "10.144.99.16"

#Database Info
$TYPE = "external"
$DSN = "vCenter"
$USER = "vCenter"
$PASS = "VMw@re123"

$SSO_DOMAIN = "vsphere.local"
$SSO_PASS = "VMw@re123!"
$SSO_SITE ="MY_SITE"

# Install vCenter

Write-Host “Installing vCenter”

$vars = "/i `"$VCmedia\VMware-vCenter-Server.msi`" ”
$vars += "/l*e `"c:\temp\vCenterinstall.txt`" /qr "
$vars += "LAUNCHED_BY_EXE=0 FQDN=`"$FQDN`" "
$vars += "INSTALL_TYPE=embedded "
$vars += "DB_TYPE=$Type DB_DSN=`"$DSN`" "
$vars += "DB_USER=`"$USER`" "
$vars += "DB_PASSWORD=`"$PASS`" "
$vars += "INFRA_NODE_ADDRESS=`"$vCIP`" "
$vars += "VC_SVC_USER=`"$SVC_USER`" "
$vars += "VC_SVC_PASSWORD=`"$SVC_PASS`" "
$vars += "SSO_DOMAIN=`"$SSO_DOMAIN`" "
$vars += "SSO_PASSWORD=`"$SSO_PASS`" "
$vars += "SSO_SITENAME=`"$SSO_SITE`" "
Start-Process msiexec -ArgumentList $vars –Wait



Listing 1.2	Sample script for an automated installation of vCenter Server Appliance

# Deploy vCSA6 using vCSA-Deploy
# Convert JSON file to PowerShell object 
$ConfigLoc = "D:\vcsa-cli-installer\templates\full_conf.json"
$Installer = "D:\vcsa-cli-installer\win32\vcsa-deploy.exe"
$UpdatedConfig = "C:\Temp\configuration.json"
$json = (Get-Content -Raw $ConfigLoc) | ConvertFrom-Json

# vCSA system information
$json.vcsa.system."root.password"="VMw@re123"
$json.vcsa.system."ntp.servers"="198.60.73.8"
$json.vcsa.sso.password = "VMw@re123"
$json.vcsa.sso."site-name" = "Primary-Site"

# ESXi Host Information
$json.deployment."esx.hostname"="10.144.99.11"
$json.deployment."esx.datastore"="ISCSI-SSD-900GB"
$json.deployment."esx.username"="root"
$json.deployment."esx.password"="VMw@re123"
$json.deployment."deployment.option"="tiny"
$json.deployment."deployment.network"="VM Network"
$json.deployment."appliance.name"="Primary-vCSA6"

# Database connection
$json.vcsa.database.type="embedded"

# Networking
$json.vcsa.networking.mode = "static"
$json.vcsa.networking.ip = "10.144.99.19"
$json.vcsa.networking.prefix = "24"
$json.vcsa.networking.gateway = "10.144.99.1"
$json.vcsa.networking."dns.servers"="10.144.99.5"
$json.vcsa.networking."system.name"="10.144.99.19"
$json | ConvertTo-Json | Set-Content -Path "$UpdatedConfig"
Invoke-Expression "$installer $UpdatedConfig"


Listing 1.3	Sample script for a silent install of the vSphere Client

# Install vCenter Client
Write-Host “Installing vCenter Client”
$VIMedia = “D:\vsphere-Client\VMware-viclient.exe”
Start-Process $VIMedia -ArgumentList ‘/q /s /w /V” /qr”’ -Wait -Verb RunAs


Listing 1.4	Sample script for an automated installation of vSphere Update Manager
# Media
$VUMMedia = "D:\updateManager"
 
# Database
$DSN = "VUM"
$User = "vCenter"
$Pass = "VMw@re123"
 
# vCenter
$vCenter = "10.144.99.16"
$port = "80"
$vCAdmin = "administrator@vsphere.local"
$vCAdmin_Pass = "VMw@re123"

$vArgs = "/V`" /qr /L*v c:\temp\vmvci.log "
$vArgs += "WARNING_LEVEL=0 VCI_DB_SERVER_TYPE=Custom "
$vArgs += "DB_DSN=$DSN DB_USERNAME=$user "
$vArgs += "DB_PASSWORD=$pass "
$vArgs += "VMUM_SERVER_SELECT=$vCenter " 
$vArgs += "VC_SERVER_IP=$vCenter "
$vArgs += "VC_SERVER_PORT=$port "
$vArgs += "VC_SERVER_ADMIN_USER=$vCAdmin "
$vArgs += "VC_SERVER_ADMIN_PASSWORD=$vCAdmin_Pass`""


$vars = @()
$vars += '/s'
$vars += '/w'
$vars += $vArgs

Start-Process -FilePath $VUMMedia\VMware-UpdateManager.exe -ArgumentList $vars



Listing 1.5	Using a CSV file to create a vCenter file structure
function Import-Folders {
<#
.SYNOPSIS
  Imports a csv file of folders into vCenter Server and
  creates them automatically.
.DESCRIPTION
  The function will import folders from CSV file and create
  them in vCenter Server.
.NOTES
  Source:  Automating vSphere Administration
.PARAMETER FolderType
  The type of folder to create
.PARAMETER DC
  The Datacenter to create the folder structure
.PARAMETER Filename
  The path of the CSV file to use when importing
.EXAMPLE
  Import-Folders -FolderType “Blue” -DC “DC01” `
      -Filename “C:\BlueFolders.csv”
.EXAMPLE
  Import-Folders -FolderType “Yellow” -DC “Datacenter”
  -Filename “C:\YellowFolders.csv”
#>

  param(
  [String]$FolderType,
  [String]$DC,
  [String]$Filename
  )

  process{
    $vmfolder = Import-Csv $filename | `
    Sort-Object -Property Path
   If ($FolderType -eq “Yellow”) {
      $type = “host”
   } Else {
      $type = “vm”
   }
   foreach($folder in $VMfolder){
      $key = @()
      $key = ($folder.Path -split “\\”)[-2]
      if ($key -eq “vm”) {
       Get-Datacenter $dc | Get-Folder $type | `
       New-Folder -Name $folder.Name
      } else {
        Get-Datacenter $dc | Get-Folder $type | `
        Get-Folder $key | `
            New-Folder -Name $folder.Name
      }
   }
  }
}

Import-Folders -FolderType “blue” -DC “DC01” `
-Filename “C:\BlueFolders.csv”



Listing 1.6	Exporting a vCenter structure to a CSV file
filter Get-FolderPath {
<#
.SYNOPSIS
  Colates the full folder path
.DESCRIPTION
  The function will find the full folder path returning a
  name and path
.NOTES
  Source:  Automating vSphere Administration
#>
    $_ | Get-View | % {
        $row = “” | select Name, Path
        $row.Name = $_.Name

        $current = Get-View $_.Parent
        $path = $_.Name
        do {
            $parent = $current
            if($parent.Name -ne “vm”){
             $path = $parent.Name + “\” + $path
            }
            $current = Get-View $current.Parent
        } while ($current.Parent -ne $null)
        $row.Path = $path
        $row
    }
}

function Export-Folders {
  <#
.SYNOPSIS
  Creates a csv file of folders in vCenter Server.
.DESCRIPTION
  The function will export folders from vCenter Server
  and add them to a CSV file.
.NOTES
  Source:  Automating vSphere Administration
.PARAMETER FolderType
  The type of folder to export
.PARAMETER DC
  The Datacenter where the folders reside
.PARAMETER Filename
  The path of the CSV file to use when exporting
.EXAMPLE
  Export-Folders -FolderType “Blue” -DC “DC01” -Filename `
      “C:\BlueFolders.csv”
.EXAMPLE
  Export-Folders -FolderType “Yellow” -DC “Datacenter”
  -Filename “C:\YellowFolders.csv”
#>

  param(
  [String]$FolderType,
  [String]$DC,
  [String]$Filename
  )

  Process {
   If ($Foldertype -eq “Yellow”) {
      $type = “host”
   } Else {
     $type = “vm”
   }
   $report = @()
   $report = Get-Datacenter $dc | Get-Folder $type | `
   Get-Folder | Get-FolderPath
   $report | foreach {
    if ($type -eq “vm”) {
     $_.Path = ($_.Path).Replace($dc + “\”,”$type\”)
    }
   }
   $report | Export-Csv $filename -NoTypeInformation
  }
}

function Export-VMLocation {
  <#
.SYNOPSIS
  Creates a csv file with the folder location of each VM.
.DESCRIPTION
  The function will export VM locations from vCenter Server
  and add them to a CSV file.
.NOTES
  Source:  Automating vSphere Administration
.PARAMETER DC
  The Datacenter where the folders reside
.PARAMETER Filename
  The path of the CSV file to use when exporting
.EXAMPLE
  Export-VMLocation -DC “DC01” `
      -Filename “C:\VMLocations.csv”
#>

  param(
  [String]$DC,
  [String]$Filename
  )

  Process {
   $report = @()
   $report = Get-Datacenter $dc | Get-VM | Get-FolderPath
   $report | Export-Csv $filename -NoTypeInformation
  }
}

Export-Folders “Blue” “DC01” “C:\BlueFolders.csv”
Export-VMLocation “DC01” “C:\VMLocation.csv”
Export-Folders “Yellow” “DC01” “C:\YellowFolders.csv”



Listing 1.7	Importing VMs to their blue folders
function Import-VMLocation {
 <#
.SYNOPSIS
  Imports the VMs back into their Blue Folders based on
  the data from a csv file.
.DESCRIPTION
  The function will import VM locations from CSV File
  and add them to their correct Blue Folders.
.NOTES
  Source:  Automating vSphere Administration
.PARAMETER DC
  The Datacenter where the folders reside
.PARAMETER Filename
  The path of the CSV file to use when importing
.EXAMPLE
  Import-VMLocation -DC “DC01” -Filename “C:\VMLocations.csv”
#>

  param(
  [String]$DC,
  [String]$Filename
  )

  Process {
   $Report = @()
   $Report = Import-Csv $filename | Sort-Object -Property Path
   foreach($vmpath in $Report){
      $key = @()
      $key = Split-Path $vmpath.Path | Split-Path -Leaf
      Move-VM (Get-Datacenter $dc `
      | Get-VM $vmpath.Name) `
      -Destination (Get-Datacenter $dc | Get-Folder $key)
   }
  }
}

Import-VMLocation “DC01” “C:\VMLocation.csv”


Listing 1.8	Creating a new role
New-VIRole `
-Name ‘New Custom Role’ `
-Privilege (Get-VIPrivilege `
-PrivilegeGroup “Interaction”,”Provisioning”)

$Priv = @()
$MyPriv = “Profile”, “VCIntegrity.Baseline”, `
“VApp.Move”, “Profile.Clear”

Foreach ($CustPriv in $MyPriv){
   $Priv += Get-VIPrivilege | Where {$_.Id -eq $CustPriv}
}

New-VIRole “New selected Role” -Privilege $Priv


Listing 1.9	Exporting permissions
function Export-PermissionsToCSV {
 <#
.SYNOPSIS
  Exports all Permissions to CSV file
.DESCRIPTION
  The function will export all permissions to a CSV
  based file for later import
.NOTES
  Source:  Automating vSphere Administration
.PARAMETER Filename
  The path of the CSV file to be created
.EXAMPLE
  Export-PermissionsToCSV -Filename “C:\Temp\Permissions.csv”
#>

  param(
  [String]$Filename
  )

  Process {
   $folderperms = Get-Datacenter | Get-Folder | Get-VIPermission
   $vmperms = Get-Datacenter | Get-VM | Get-VIPermission

   $permissions = Get-Datacenter | Get-VIpermission

   $report = @()
      foreach($perm in $permissions){
        $row = “” | select EntityId, Name, Role, `
        Principal, IsGroup, Propagate
        $row.EntityId = $perm.EntityId
        $Foldername = (Get-View -Id $perm.EntityId –Property Name).Name
        $row.Name = $foldername
        $row.Principal = $perm.Principal
        $row.Role = $perm.Role
        $row.IsGroup = $perm.IsGroup
        $row.Propagate = $perm.Propagate
        $report += $row
    }

    foreach($perm in $folderperms){
        $row = “” | select EntityId, Name, Role, `
        Principal, IsGroup, Propagate
        $row.EntityId = $perm.EntityId
        $Foldername = (Get-View -Id $perm.EntityId –Property Name).Name
        $row.Name = $foldername
        $row.Principal = $perm.Principal
        $row.Role = $perm.Role
        $row.IsGroup = $perm.IsGroup
        $row.Propagate = $perm.Propagate
        $report += $row
    }

    foreach($perm in $vmperms){
        $row = “” | select EntityId, Name, Role, `
        Principal, IsGroup, Propagate
        $row.EntityId = $perm.EntityId
        $Foldername = (Get-View -Id $perm.EntityId –Property Name).Name
        $row.Name = $foldername
        $row.Principal = $perm.Principal
        $row.Role = $perm.Role
        $row.IsGroup = $perm.IsGroup
        $row.Propagate = $perm.Propagate
        $report += $row
    }

    $report | Export-Csv $Filename -NoTypeInformation
  }
}

Export-PermissionsToCSV -Filename “C:\Temp\Permissions.csv”





Listing 1.10	Importing permissions
function Import-Permissions {
<#
.SYNOPSIS
  Imports all Permissions from CSV file
.DESCRIPTION
  The function will import all permissions from a CSV
  file and apply them to the vCenter Server objects.
.NOTES
  Source:  Automating vSphere Administration
.PARAMETER Filename
  The path of the CSV file to be imported
.EXAMPLE
  Import-Permissions -DC -Filename “C:\Temp\Permissions.csv”
#>

param(
[String]$Filename
)

process {
 $permissions = @()
 $permissions = Import-Csv $Filename
 foreach ($perm in $permissions) {
$entity = (Get-View –Id $perm.EntityId –Property Name).MoRef
  $object = Get-Inventory -Name $perm.Name
  if($object.Count){
   $object = $object | where {$_.Id -eq $perm.EntityId}
  }
  if($object){
   switch -Wildcard ($perm.EntityId)
   {
    Folder* {
     $entity.Type = “Folder”
     $entity.value = $object.Id.TrimStart(“Folder-”)
    }
    VirtualMachine* {
     $entity.Type = “VirtualMachine”
     $entity.value = $object.Id.TrimStart(“VirtualMachine-”)
    }
    ClusterComputeResource* {
     $entity.Type = “ClusterComputeResource”
     $entity.value = `
     $object.Id.TrimStart(“ClusterComputeResource-”)
    }
    Datacenter* {
     $entity.Type = “Datacenter”
     $entity.value = $object.Id.TrimStart(“Datacenter-”)
    }
   }
   $setperm = New-Object VMware.Vim.Permission
   $setperm.principal = $perm.Principal
   if ($perm.isgroup -eq “True”) {
    $setperm.group = $true
   } else {
    $setperm.group = $false
   }
   $setperm.roleId = (Get-VIRole $perm.Role).id
   if ($perm.propagate -eq “True”) {
    $setperm.propagate = $true
   } else {
    $setperm.propagate = $false
   }
   $viewAuthManager = Get-View -Id `
   ‘AuthorizationManager-AuthorizationManager’
   Write-Host “Setting Permissions on `
   $($perm.Name) for $($perm.principal)”
   $viewAuthManager.SetEntityPermissions($entity, $setperm)
  }
 }
 }
}

Import-Permissions -DC “DC01” -Filename “C:\Temp\Permissions.csv”




Listing 1.11	Enabling HA with a failover host level and Restart Priority on a new cluster
$ProductionCluster = New-Cluster `
-Location $BostonDC `
-Name “Production” `
-HAEnabled -HAAdmissionControlEnabled `
-HAFailoverLevel 1 `
-HARestartPriority “Medium”



Listing 1.12	Enabling HA with a failover host level and restart priority on an existing cluster
Get-Cluster `
-Location $BostonDC `
-Name “Production” | `
Set-Cluster -HAEnabled $true `
-HAAdmissionControlEnabled $true `
-HAFailoverLevel 1 `
-HARestartPriority “Medium”


Listing 1.13	Configuring DRS on a new cluster
$ProductionCluster = New-Cluster “Production” `
-Location $BostonDC `
-DrsEnabled `
-DrsAutomationLevel “FullyAutomated” `
-Confirm:$false


Listing 1.14	Configuring DRS on an existing cluster
Get-Cluster -Location $BostonDC `
-Name “Production” | Set-Cluster `
-DrsEnabled $true `
-DrsAutomationLevel “FullyAutomated” `
-Confirm:$false


Listing 1.15	Configuring DPM on a cluster
function Set-DPM {
 <#
.SYNOPSIS
  Enables Distributed Power Management on a cluster
.DESCRIPTION
  This function will allow you to configure
  DPM on an existing vCenter Server cluster
.NOTES
  Source:  Automating vSphere Administration
.PARAMETER Cluster
  The cluster on which to set DPM configuration
.PARAMETER Behavior
  DPM Behavior, this can be set to “off”, “manual”
  or “Automated”, by default it is “off”
.EXAMPLE
  Set-DPM -Cluster “Cluster01” -Behavior “Automated”
#>

param(
  [String]$Cluster,
  [String]$Behavior
  )

  Process {
   switch ($Behavior) {
            “Off” {
               $DPMBehavior = “Automated”
               $Enabled = $false
            }
            “Automated” {
               $DPMBehavior = “Automated”
               $Enabled = $true
            }
            “Manual” {
               $DPMBehavior = “Manual”
               $Enabled = $true
            }
            default {
               $DPMBehavior = “Automated”
               $Enabled = $false
            }
      }
   $clus = Get-Cluster $Cluster | Get-View –Property Name
   $spec = New-Object VMware.Vim.ClusterConfigSpecEx
   $spec.dpmConfig = New-Object VMware.Vim.ClusterDpmConfigInfo
   $spec.DpmConfig.DefaultDpmBehavior = $DPMBehavior
   $spec.DpmConfig.Enabled = $Enabled
   $clus.ReconfigureComputeResource_Task($spec, $true)
$clus.UpdateViewData("ConfigurationEx")
	New-Object -TypeName PSObject -Property @{Cluster = $clus.Name; DPMEnabled = $clus.ConfigurationEx.DpmConfigInfo.Enabled; DefaultDpmBehavior = $clus.ConfigurationEx.DpmConfigInfo.DefaultDpmBehavior}

  }
}

Set-DPM -Cluster “Cluster01” -Behavior “Automated”




Listing 1.16	Retrieving license key information from vCenter Server
function Get-LicenseKey {
 <#
.SYNOPSIS
  Retrieves License Key information
.DESCRIPTION
  This function will list all license keys added to
  vCenter Server
.NOTES
  Source:  Automating vSphere Administration
.EXAMPLE
  Get-LicenseKey
#>

  Process {

   $servInst = Get-View ServiceInstance
   $licMgr = Get-View $servInst.Content.licenseManager
   $licMgr.Licenses
  }
}

Get-LicenseKey




Listing 1.17	Adding a license key to a host
function Set-LicenseKey {
 <#
.SYNOPSIS
  Sets a License Key for a host
.DESCRIPTION
  This function will set a license key for a host
  which is attached to a vCenter Server
.NOTES
  Source:  Automating vSphere Administration
.PARAMETER LicKey
  The License Key
.PARAMETER VMHost
  The vSphere host to add the license key to
.PARAMETER Name
  The friendly name to give the license key
.EXAMPLE
  Set-LicenseKey -LicKey “AAAAA-BBBBB-CCCCC-DDDDD-EEEEE” `
       -VMHost “esxhost01.mydomain.com” `
       -Name $null
#>

param(
  [String]$VMHost,
  [String]$LicKey,
  [String]$Name
  )

  Process {
$vmhostId = (Get-VMHost $VMHost | Get-View –Property `
Config.Host).Config.Host.Value
   $servInst = Get-View ServiceInstance
   $licMgr = Get-View $servInst.Content.licenseManager
   $licAssignMgr = Get-View $licMgr.licenseAssignmentManager

   $license = New-Object VMware.Vim.LicenseManagerLicenseInfo
   $license.LicenseKey = $LicKey
   $licAssignMgr.UpdateAssignedLicense(`
   $VMHostId, $license.LicenseKey, $Name)
   $hostlicense = (get-vmhost $VMhost).LicenseKey
   Write-Host ("Host [$VMhost] license has been set to $hostlicense")
   }
}

Set-LicenseKey -LicKey “AAAAA-BBBBB-CCCCC-DDDDD-EEEEE” `
-VMHost “esxhost01.mydomain.com” `
-Name $null
