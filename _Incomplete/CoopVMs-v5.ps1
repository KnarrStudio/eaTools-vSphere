#requires -Version 1.0

<#
    Requirements - VMware PowerCLI

    ### In need of major rewrite.  

    .DESCRIPTION
    This scripts does the following:
    - Removes and/or Creates copies (COOPs) of our servers for quick replacement in the case of a server problem
    - This could be modified to create the COOP on the SAN, but this is designed to move the files from the SAN to the local ESXi03(6) datastore.
    - Reads in server names from the file: COOP-serverlist.csv (This should be in the same dir as this script)
    - Side Note: Future plans will be to remove the list and COOP servers based on tests.  You may see some of the "pre" work already.
    - Copies COOP to: ESXi06-LOCALdatastore02
    - Write to Host: 192.169.1.89


    .NOTE
    Script Name: COOPVMs.ps1
    Author Name: Erik Arnesen
    Version : 1.7
    Mod Date: 5/21/2015
    Contact : 5276
    Copy of this file is located in OneNote under Scripts



#>

# Functions

Function Set-Safety
{
  <#
      .SYNOPSIS
      Turns on "WhatIf" for the entire script
  #>
  If ($WhatIfPreference -eq $true)
  {
    $Script:WhatIfPreference = $false
    Write-Host 'Safety OFF' -ForegroundColor Red
  }
  else
  {
    $Script:WhatIfPreference = $true
    Write-Host 'Safety ON' -ForegroundColor Green
  }
}

Function Show-MainHeader 
{
  Write-Host `n 
  Write-Host 'Datastore to be written to: '$DataStoreStore
  Write-Host 'VM Host to store COOPs: '$VMHostIP
  Write-Host 'Current File Location: ' $local
}

Function Show-MainMenu 
{
  $NewLine = '`n'
Write-Host $NewLine 
  Write-Host '0 = Set Safety On/Off'
  Write-Host '1 = Remove Old COOPs and Create New'
  Write-Host '2 = Remove Old COOPs'
  Write-Host '3 = Create New COOPs'
  Write-Host '4 = VM/COOP information'
  Write-Host 'E = to Exit'
  Write-Host $NewLine 
}

Function Get-VMinformation 
{
  # User settings
  $Script:VMHostIP = '192.169.1.18'
  $Script:WhatIfPreference = $true #This is a safety measure that I am working on.  My scripts will have a safety mode, or punch the monkey to actually execute.  You can thank Phil West for this idea, when he removed all of the printers on the print server when he double-clicked on a vbs script.
  $Script:MainMenuChoice = 0 # Sets main menu choice
  $Script:VMServerList = '.\COOP-serverlist.csv' # The list of servers 
  $Script:VMDataStoreStore = Get-Datastore | Where-Object -FilterScript {
    $_.name -like 'LOCALdatastore18'
  }


  # Script Variables
  $Script:HostsAll = get-vmhost # All hosts controlled by vcenter
  $Script:HostsLocal = get-vmhost # All hosts in current site
  $Script:VMpoweredON = get-vm | Where-Object -FilterScript {
    $_.PowerState -eq 'PoweredOn'
  } # All powered ON VMs
  $Script:VMPoweredOff = get-vm | Where-Object -FilterScript {
    $_.PowerState -eq 'PoweredOff'
  } # All powered OFF VMs
  $Script:VMtags = get-tags # Tags on vcenter
  $Script:VMsnapshots = get-snap # All Snapshots

  $Script:local = Get-Location

  Set-Location -Path .\
}

Function Get-InformationOfCOOPsSnaps 
{
  $DoubleLineBorder = '============================='
$NewLine = '`n'
$PoweredOffVM = get-vm | Where-Object -FilterScript {
    ($_.PowerState -eq 'PoweredOff') -and ($_.Name -notmatch 'COOP')
  }# | Format-Table -AutoSize
  $COOPSinuse = get-vm | Where-Object -FilterScript {
    ($_.PowerState -eq 'PoweredOn') -and ($_.Name -match 'COOP')
  }
  $Snapshotinfo = get-vm | get-snapshot 

  # $PoweredOffVM = get-vm | where {($_.PowerState -eq "PoweredOff") -and ($_.Name -notmatch "COOP")}# | Format-Table -AutoSize

  # Regular VM's which are in a powered off state
  Write-Host $NewLine "Regular VM's with the Power turned OFF." -foreground Black -BackgroundColor Cyan
  Write-Host $DoubleLineBorder -foregroundcolor Cyan
  If ($PoweredOffVM.count -ne 0)
  {
    Write-Host -sep $NewLine $PoweredOffVM -foregroundcolor Cyan
  }
  else
  {
    Write-Host "`nNone to Report." -foregroundcolor Cyan
  }
  Write-Host $DoubleLineBorder -foregroundcolor Cyan
  Write-Host -sep $NewLine 

  # COOP Server In use
  Write-Host $NewLine "COOP'ed Servers with the Power ON." -foreground White -BackgroundColor Red
  Write-Host $DoubleLineBorder -foregroundcolor Red
  If ($PoweredOffVM.count -ne 0)
  {
    Write-Host -sep $NewLine $COOPSinuse -foregroundcolor Red
  }
  else
  {
    Write-Host "`nNone to Report." -foregroundcolor Red
  }
  Write-Host $DoubleLineBorder -foregroundcolor Red
  Write-Host -sep $NewLine 

  # Snapshot Information
  Write-Host $NewLine "Snapshot information of all VM's in our vSphere." -foreground Yellow -BackgroundColor Black
  Write-Host $DoubleLineBorder -foregroundcolor Yellow

  If ($Snapshotinfo.count -ne 0)
  {
    Write-Host -sep $NewLine $Snapshotinfo | Format-Table -AutoSize -foregroundcolor Yellow
  }
  else
  {
    Write-Host "`nNone to Report." -foregroundcolor Yellow
  }
  Write-Host $DoubleLineBorder -foregroundcolor Yellow
}

Function Old-Info-COOPs-Snaps 
{
  $NewLine = '`n'
$DoubleLineBorder = '============================='
get-tag
  Write-Host $DoubleLineBorder
  Write-Host $NewLine 
  $PoweredOffVM = get-vm | Where-Object -FilterScript {
    ($_.PowerState -eq 'PoweredOff') -and ($_.Name -notmatch 'COOP')
  }# | Format-Table -AutoSize
  If ($PoweredOffVM.count -ne 0)
  {
    Write-Host $NewLine "Regular VM's with the Power turned OFF." -foreground Black -BackgroundColor Cyan
    Write-Host $DoubleLineBorder -foregroundcolor Cyan
    Write-Host -sep $NewLine $PoweredOffVM -foregroundcolor Cyan #| Format-Table -AutoSize
    Write-Host $DoubleLineBorder -foregroundcolor Cyan
    Write-Host -sep $NewLine 
  }
  $COOPSinuse = get-vm | Where-Object -FilterScript {
    ($_.PowerState -eq 'PoweredOn') -and ($_.Name -match 'COOP')
  }
  If ($COOPSinuse.count -ne 0)
  {
    Write-Host $NewLine "COOP'ed Servers with the Power ON." -foreground White -BackgroundColor Red
    Write-Host $DoubleLineBorder -foregroundcolor Red
    Write-Host -sep $NewLine $COOPSinuse -foregroundcolor Red
    Write-Host $DoubleLineBorder -foregroundcolor Red
    Write-Host -sep $NewLine 
  }
  $Snapshotinfo = get-vm |
  get-snapshot |
  Sort-Object -Property Created, SizeGB -Descending |
  Format-Table -Property VM, Name, Created, @{n = 'SizeGb';e = {'{0:N2}' -f $_.SizeGb}}#, id -AutoSize
  If ($Snapshotinfo.count -ne 0)
  {
    Write-Host $NewLine "Snapshot information of all VM's in our vsphere." -foreground Yellow -BackgroundColor Black
    Write-Host $DoubleLineBorder -foregroundcolor Yellow
    $Snapshotinfo | Format-Table
    Write-Host $DoubleLineBorder -foregroundcolor Yellow
  }
}

Function Remove-COOPs 
{
  $NewLine = '`n'
if ($MainMenuChoice -eq '2')
  {
    Clear-Host
  }

  #Get List of all VM's with "COOP" in the name. This will be used as the list of COOP's that will be deleted.
  $VMServers = get-vm | Where-Object -FilterScript {
    $_.Name -match 'COOP'
  }
  $VMServers | Format-Table -Property Name

  #Enter the date of the COOP vms that you want to remove.  From the printout of the list above, you will be able to select the unwanted dates.
  $COOPdate = Read-Host -Prompt 'Enter the date of the COOP you want to remove (YYYYMMDD) '

  #Get List of the VM Clones you want to Remove.  This is similar to the first step, but uses the specific date you gave to search on.  This will be your list of systems to remove.
  $PoweredOffClones = $VMPoweredOff | Where-Object -FilterScript {
    $_.Name -like "$COOPdate*"
  } #| ft Name, ResourcePool  -AutoSize

  #Set "$OkRemove" to "N" 
  $OkRemove = 'N'
  $OkRemove = Read-Host -Prompt ("Preparing to remove ALL COOP'ed vm servers below. {0}`nIs this Okay? [N] " -f $PoweredOffClones)

  If ($OkRemove -eq 'Y')
  {
    #Remove older COOP's from the list you created in the early part of the script.
    foreach ($VMz in $PoweredOffClones) 
    {
      Write-Host -sep $NewLine ('Checking to ensure {0} is Powered Off.' -f $VMz) #-foregroundcolor Red
      If (($VMz.PowerState -eq 'PoweredOff') -and ($VMz.Name -match 'COOP'))
      {
        Write-Host -sep $NewLine $VMz 'is in a Powered Off state and will be removed. ' -foregroundcolor Blue 
        #Write-Host "Remove-VM $VMz -DeletePermanently -confirm:$true "
        Remove-VM $VMz -DeletePermanently -confirm:$true -runasync
      }
    }
  }
}

Function New-COOPs 
{
  if ($MainMenuChoice -eq '3')
  {
    Clear-Host
  }

  #get-vm *gm* -tag "COOPdr" | where {$_.powerstate -eq "PoweredOn"} | ft Name, ResourcePool -AutoSize
  #$VMServer  = get-vm *gm* | where {($_.powerstate -eq "PoweredOn") -and ($_.ResourcePool -like "Standard Server*") -and ($_.name -ne "rsrcngmfs02") -and ($_.name -ne "RSRCNGMNB01") -and ($_.name -ne "rsrcngmfs01") -and ($_.name -ne "rsrcngmcmps01")} | select Name, ResourcePool
  #get-vm *gm* | where {($_.powerstate -eq "PoweredOn") -and ($_.ResourcePool -like "Standard Server*") -and ($_.name -ne "rsrcngmfs02") -and ($_.name -ne "RSRCNGMNB01") -and ($_.name -ne "rsrcngmfs01") -and ($_.name -ne "rsrcngmcmps01")} | ft Name, ResourcePool -AutoSize

  $VMServer = VMpoweredON | Where-Object -FilterScript {
    ($_.name -match 'gm') -and ($_.tag -match 'COOPdr')
  }
  #$VMServer = get-vm *gm* -tag "COOPdr" | where {$_.powerstate -eq "PoweredOn"}

  #Create Time/Date Stamp
  $TDStamp = Get-Date -UFormat '%Y%m%d' 

  #Prefix of Name of COOP
  $COOPPrefix = $TDStamp + '-COOP.' 

  Write-Host ("`nInformation to be used to create the COOPs: {0}.Name - {1}.ResourcePool" -f $VMServer) -foregroundcolor black -backgroundcolor yellow #
  Write-Host -Separator `n $VMServer | Format-Table -Property Name, ResourcePool -AutoSize 
  Write-Host 'Writing to: '$DataStoreStore -foregroundcolor Yellow
  Write-Host 'On VM Host: '$VMHostIP -foregroundcolor Yellow
  Write-Host 'Example of COOP file name: '$COOPPrefix$($VMServer.Name[1]) -foregroundcolor Yellow
  Write-Host -Separator `n 

  #Set "$OkADD" to "N" and confirm addition of COOPs
  $OkADD = 'N'
  $OkADD = Read-Host -Prompt "Preparing to Create ALL New COOP servers with information above. `nIs this Okay? Y,S,[N] "

  switch ($OkADD){
    Y 
    {
      foreach ($server in $VMServer) 
      {
        Write-Host -Separator `n 'Completed'
        Write-Host '=============================' -foregroundcolor Yellow
        get-vm |
        Where-Object -FilterScript {
          $_.Name -like $TDStamp + '-COOP.*'
        } |
        Format-Table -Property Name
        Write-Host 'New COOP Name: '$COOPPrefix$($server) 'In ResourcePool: '$server.ResourcePool -foregroundcolor Green -backgroundcolor black
        #Create the COOP copies with the information assigned to these var ($COOPPrefix, $VMserver, $dataStoreStore)
        #Write-Host "-name $COOPPrefix$($server) -vm $server -datastore $DataStoreStore -VMHost $VMHostIP -Location COOP -ResourcePool"$Server.ResourcePool
        New-vm -name $COOPPrefix$($server) -vm $server -datastore $DataStoreStore -VMHost $VMHostIP -Location COOP -ResourcePool $server.ResourcePool 
      }
    }
    S 
    {
      $server = Read-Host -Prompt 'Single COOP (ServerName) ' 
      $COOPPrefix + $server
      New-vm -name $COOPPrefix$($server) -vm $server -datastore $DataStoreStore -VMHost $VMHostIP -Location COOP -whatif
    }
    Default 
    {
      Write-Host 'Exit'
    }
  }
}


# -----  Begin Script -----

Clear-Host

Do 
{
  Show-MainHeader
  Show-MainMenu
  $MainMenuChoice = Read-Host -Prompt "Create and/or Remove and Create VM's"
  if($MainMenuChoice -eq 0)
  {
    Set-SafetySwitch
  }
}
Until ($MainMenuChoice -eq '1' -or $MainMenuChoice -eq '2' -or $MainMenuChoice -eq '3' -or $MainMenuChoice -eq '4' -or $MainMenuChoice -eq 'E')


switch ($MainMenuChoice){
  1 
  {
    Clear-Host
    Write-Host 'Start Removing COOPs' -ForegroundColor Green
    Remove-COOPs 
    Write-Host "Start Creating COOP's" -ForegroundColor Green
    New-COOPs
  }
  2 
  {
    Clear-Host
    Write-Host 'Start Removing COOPs' -ForegroundColor Green
    Remove-COOPs
  }
  3 
  {
    Clear-Host
    Write-Host "Start Creating COOP's" -ForegroundColor Green
    New-COOPs
  }
  4 
  {
    Clear-Host
    Get-InformationOfCOOPsSnaps
  }
  Default 
  {
    Clear-Host
    Write-Host 'Exit' -ForegroundColor Red
  }
}




# SIG # Begin signature block
  # MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
  # gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
  # AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBpNhTVUfVdxYfdraLYqVDrTK
  # L96gggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
  # MBYxFDASBgNVBAMTC0VyaWtBcm5lc2VuMB4XDTE3MTIyOTA1MDU1NVoXDTM5MTIz
  # MTIzNTk1OVowFjEUMBIGA1UEAxMLRXJpa0FybmVzZW4wgZ8wDQYJKoZIhvcNAQEB
  # BQADgY0AMIGJAoGBAKYEBA0nxXibNWtrLb8GZ/mDFF6I7tG4am2hs2Z7NHYcJPwY
  # CxCw5v9xTbCiiVcPvpBl7Vr4I2eR/ZF5GN88XzJNAeELbJHJdfcCvhgNLK/F4DFp
  # kvf2qUb6l/ayLvpBBg6lcFskhKG1vbEz+uNrg4se8pxecJ24Ln3IrxfR2o+BAgMB
  # AAGjYDBeMBMGA1UdJQQMMAoGCCsGAQUFBwMDMEcGA1UdAQRAMD6AEMry1NzZravR
  # UsYVhyFVVoyhGDAWMRQwEgYDVQQDEwtFcmlrQXJuZXNlboIQyWSKL3Rtw7JMh5kR
  # I2JlijAJBgUrDgMCHQUAA4GBAF9beeNarhSMJBRL5idYsFZCvMNeLpr3n9fjauAC
  # CDB6C+V3PQOvHXXxUqYmzZpkOPpu38TCZvBuBUchvqKRmhKARANLQt0gKBo8nf4b
  # OXpOjdXnLeI2t8SSFRltmhw8TiZEpZR1lCq9123A3LDFN94g7I7DYxY1Kp5FCBds
  # fJ/uMYIBSjCCAUYCAQEwKjAWMRQwEgYDVQQDEwtFcmlrQXJuZXNlbgIQyWSKL3Rt
  # w7JMh5kRI2JlijAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
  # ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
  # KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUuUjAVKdzfXTZdj+qIzkhow2M8yAw
  # DQYJKoZIhvcNAQEBBQAEgYA8HZpR5ngEYiyfiLFHNPvKGOwhzzkiupr+nzVpTKIc
  # jjKJmBVYoEL+I8QwEyOhS4VOZRTbuVGDTLyS4i5liYwhVUMI6sPyxTR148DPWrZT
  # K3iURyNbm1TX+5U/MppAJaeP1nWrjYnqJ+Eu2dWwGK77QeeaPTcDT6j2ng9t5KTv
  # 6Q==
# SIG # End signature block
