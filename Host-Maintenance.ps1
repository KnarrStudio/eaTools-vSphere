<#
    .SYNOPSIS
    This Script migrates all machines to one host so you can reboot the empty one.
    .DESCRIPTION
    <A detailed description of the script>
    .PARAMETER <paramName>
    <Description of script parameter>
    .EXAMPLE
    <An example of using the script>
#>


. "$env:USERPROFILE\Documents\GitHub\PowerShell_VM-Modules\f_CreateMenu.ps1"

# Functions

Function Set-SafetySwitch
{
  <#
      .SYNOPSIS
      Turns on "WhatIf" for the entire script

      .PARAMETER toggle
      Currently does nothing.  I may set it up to take an ON/OFF later on

      .PARAMTER Bombastic
      Another word for verbose

      .EXAMPLE
      Set-SafetySwitch 
      Sets the WhatIfPreference to the opposite of its current setting

      .NOTES
      Best to just copy this into your script and call it how ever you want.  I use a menu

  #>
  [CmdletBinding()]
  param
  (
    [Switch]$Bombastic,
    [Object]$toggle
  )

  $Message = @{
    NormalOff    = 'Safety OFF - Script will run'
    NormalOn     = 'Safety ON'
    BombasticOff = 'Safety is OFF - Script is active and will make changes'
    BombasticOn  = 'Safety is ON - Script is TESTING MODE'
  }
  $MsgOn = $Message.NormalOn
  $MsgOff = $Message.NormalOff

  if ($Bombastic)
  {
    $MsgOn = $Message.BombasticOn
    $MsgOff = $Message.BombasticOff
  }

  If ($WhatIfPreference -eq $true)
  {
    $Script:WhatIfPreference = $false
    Write-Host $MsgOff -ForegroundColor Red
  }
  else
  {
    $Script:WhatIfPreference = $true
    Write-Host $MsgOn -ForegroundColor Green
  }
}

#Safety-Display

Function Show-MainMenu
{
  $NewLineHere = '`n'
Clear-Host
  Set-Safety
  Write-Host $NewLineHere
  Write-Host 'Welcome to the Maintenance Center' -BackgroundColor Yellow -ForegroundColor DarkBlue
  Write-Host $NewLineHere
  #Write-Host "Datastore to be written to: "(get-datastore).name #$DataStoreStore
  #Write-Host "VM Host to store COOPs: "$VMHostIP
  #Write-Host "Current File Location: " $local
  Write-Host $NewLineHere
  Write-Host '0 = Set Safety On/Off'
  Write-Host "1 = Move all VM's to one host"
  Write-Host '2 = Reboot Empty host'
  Write-Host "3 = Balance all VM's per 'tag'"
  Write-Host '4 = Move, Reboot and Balance VM environment'
  Write-Host '5 = VM/Host information'
  Write-Host 'E = to Exit'
  Write-Host $NewLineHere
}
#Show-MainMenu


function Move-VMsTo
{
  [CmdletBinding()]
  param
  (
    [Object]$HostOne,

    [Object]$HostTwo
  )
  do
  {
    $servers = get-vm | Where-Object -FilterScript {
      $_.vmhost.name -eq $HostOne
    }
    foreach($server in $servers)
    {
      #Moving $server from $HostOne to $HostTwo
      move-vm $server -Destination $HostTwo
    }
  }while((get-vm | Where-Object -FilterScript {
        $_.vmhost.name -eq $HostOne
  }).count -ne 0)

  Write-Host 'Moves Completed!' -ForegroundColor Green
}



function Move-VMsRebootHost
{
  [CmdletBinding()]
  param
  (
    [Object]$HostOne,

    [Object]$HostTwo
  )
  do
  {
    $servers = get-vm | Where-Object -FilterScript {
      $_.vmhost.name -eq $HostOne
    }
    foreach($server in $servers)
    {
      #Write-Host "Moving $server from $HostOne to $HostTwo"
      move-vm $server -Destination $HostTwo
    }
  }while((get-vm | Where-Object -FilterScript {
        $_.vmhost.name -eq $HostOne
  }).count -ne 0)

  if((get-vm | Where-Object -FilterScript {
        $_.vmhost.name -eq $HostOne
  }).count -eq 0)
  {
    $null = Set-VMHost $HostOne -State Maintenance
    $null = Restart-vmhost $HostOne -confirm:$false
  }
  do
  {
    Start-Sleep -Seconds 15
    $ServerState = (get-vmhost $HostOne).ConnectionState
    Write-Host ('Shutting Down {0}' -f $HostOne) -ForegroundColor Magenta
  }
  while ($ServerState -ne 'NotResponding')
  Write-Host ('{0} is Down' -f $HostOne) -ForegroundColor Magenta

  do
  {
    Start-Sleep -Seconds 60
    $ServerState = (get-vmhost $HostOne).ConnectionState
    Write-Host 'Waiting for Reboot ...'
  }
  while($ServerState -ne 'Maintenance')
  Write-Host ('{0} back online' -f $HostOne)
  $null = Set-VMHost $HostOne -State Connected
}
do 
{
  Start-Sleep -Seconds 15
  $ServerState = (get-vmhost $HostOne).ConnectionState
  Write-Host ('Shutting Down {0}' -f $HostOne) -ForegroundColor Magenta
}
while ($ServerState -ne 'NotResponding')
Write-Host ('{0} is Down' -f $HostOne) -ForegroundColor Magenta

do 
{
  Start-Sleep -Seconds 60
  $ServerState = (get-vmhost $HostOne).ConnectionState
  Write-Host 'Waiting for Reboot ...'
}
while($ServerState -ne 'Maintenance')
Write-Host ('{0} back online' -f $HostOne)
$null = Set-VMHost $HostOne -State Connected


function Start-BalanceVMs ()
{
  $host18 = '192.168.192.18'
  $host19 = '192.168.192.19'


  $tagged18 = get-vm -tag Host_18
  $tagged19 = get-vm -tag Host_19

  $servers = Get-VM

  foreach($server in $tagged18)
  {
    if($server.vmhost.name -ne $host18)
    {
      Write-Host ('Moving {0} to Host-18' -f $server) -ForegroundColor DarkYellow
      move-vm $server -Destination $host18 #-whatif
    }
  }

  foreach($server in $tagged19)
  {
    if($server.vmhost.name -ne $host19)
    {
      Write-Host ('Moving {0} to Host-19' -f $server) -ForegroundColor DarkMagenta
      move-vm $server -Destination $host19 #-whatif
    }
  }
}


# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^




$FolkMusicHost = Get-VMHost | Where-Object -FilterScript {
  $_.name -notlike '192.168.208.*'
}
$FolkMusicHost.name | Format-Table -Property Name


# Begin Script
$WhatIfPreference = $true <#This is a safety measure that I am working on.  My scripts will have a safety mode, or punch the monkey to actually execute.  You can thank Phil West for this idea, when he removed all of the printers on the print server when he double-clicked on a vbs script.#>
$MenuSelection = 0
$ServerList = '.\COOP-serverlist.csv'
$DataStoreStore = Get-Datastore | Where-Object -FilterScript {
  $_.name -like 'LOCALdatastore*'
}
$VMHostIP = '192.168.192.18'
$local = Get-Location


Set-Location -Path .\

# Begin Script
#Get list of Norfolk VM's under control of vCenter
$rebootOther = 'y'
$balance = 'y'
$FolkMusicHost = Get-VMHost | Where-Object -FilterScript {
  $_.name -notlike '192.168.208.*'
}




Do
{
  $MenuSelection = ''

  #Show-MainMenu
  CreateMenu -Title 'Welcome to the Maintenance Center' -MenuItems 'Set Safety On/Off', 'EXIT', "Move all VM's to one host", 'Reboot Empty host', "Balance all VM's per 'tag'", 'Move and Reboot and Balance VM environment', 'VM/Host information', 'Exit' -TitleColor Red -LineColor Cyan -MenuItemColor Yellow

  $MenuSelection = Read-Host -Prompt 'Enter a selection from above'
  if($MenuSelection -eq 1)
  {
    If ($WhatIfPreference -eq $true)
    {
      $WhatIfPreference = $false
    }
    else
    {
      $WhatIfPreference = $true
    }
  }
}Until ($MenuSelection -eq '1' <# Move all VM's to one host #> -or
  $MenuSelection -eq '2' <# Put host in Maintenance Mode #> -or
  $MenuSelection -eq '3' <# Reboot Empty host #> -or
  $MenuSelection -eq '4' <# Balance all VM's per 'tag' #> -or
  $MenuSelection -eq '5' <# Move, Reboot and Balance VM environment #> -or
$MenuSelection -eq 'E' <# Exit #> )



switch ($MenuSelection){
  3
  {
    Clear-Host
    $HostOne = Read-Host -Prompt 'Enter IP Address of host to move from'
    $HostTwo = Read-Host -Prompt 'Enter IP Address of host to move to'
    Write-Host "If this is taking to long to run, manually check status of servers by running 'get-vm | ft name, vmhost' from PowerCLI" -ForegroundColor DarkYellow
    Write-Host "This processes can be completed by using the following command in the PowerCLI: 'move-vm VM-SERVER -destination VM-HOST'" -ForegroundColor DarkYellow
    if($HostTwo -ne $HostOne)
    {
      Move-VMsTo $HostOne $HostTwo
    }
  }
  4
  {
    Clear-Host
    Remove-COOPs
  }
  5
  {
    Clear-Host
    Create-COOPs
  }
  6
  {
    Clear-Host
    Start-BalanceVMs
  }
  7
  {

  }
  Default
  {
    Write-Host 'Exit'
  }
}


Start-Sleep -Seconds 4
Clear-Host

$FolkMusicHost.name | Format-Table -Property Name
$HostOne = Read-Host -Prompt 'Enter the host IP Address you want to reboot'
$HostTwo = Read-Host -Prompt 'Enter other host' # $FolkMusicHost.name -ne $HostOne | Out-String
Move-VMsRebootHost $HostOne $HostTwo

$rebootOther = Read-Host -Prompt 'Would you like to reboot the other host [y]/n: '
if($rebootOther -eq 'y')
{
  Move-VMsRebootHost $HostTwo $HostOne
}

$balance = Read-Host -Prompt 'Would you like to balance the servers [y]/n: '
if($balance -eq 'y')
{
  Start-BalanceVMs
}
