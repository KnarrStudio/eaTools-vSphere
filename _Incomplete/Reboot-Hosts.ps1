
# This Script migrates all machines to one host so you can reboot the empty one.

# Functions 

function script:MoveVMsRebootHost{

  [CmdletBinding()]
  param
  (
    [Object]$HostOne,

    [Object]$HostTwo
  )
  do{
    $servers = get-vm | Where-Object {$_.vmhost.name -eq $HostOne}
    foreach($server in $servers){
      #Write-Host "Moving $server from $HostOne to $HostTwo"
      move-vm $server -Destination $HostTwo
    }
  }while((get-vm | Where-Object {$_.vmhost.name -eq $HostOne}).count -ne 0)

  if((get-vm | Where-Object {$_.vmhost.name -eq $HostOne}).count -eq 0){
    Set-VMHost $HostOne -State Maintenance | Out-Null
    Restart-vmhost $HostOne -confirm:$false | Out-Null  
  }
  do {Start-Sleep -Seconds 15
    $ServerState = (get-vmhost $HostOne).ConnectionState
    Write-Verbose -Message ('Shutting Down {0}' -f $HostOne)
  } while ($ServerState -ne 'NotResponding')
  Write-Verbose -Message ('{0} is Down' -f $HostOne)
    
  do {Start-Sleep -Seconds 60
    $ServerState = (get-vmhost $HostOne).ConnectionState
    Write-Verbose -Message 'Waiting for Reboot ...'
  } while($ServerState -ne 'Maintenance')
  Write-Verbose -Message ('{0} back online' -f $HostOne)
  Set-VMHost $HostOne -State Connected | Out-Null 
}

function script:BalanceVMs (){
  $host18 = '214.54.192.18'
  $host19 = '214.54.192.19'


  $tagged18 = get-vm -tag Host_18
  $tagged19 = get-vm -tag Host_19

  $servers = Get-VM

  foreach($server in $tagged18){
    if($server.vmhost.name -ne $host18){
      Write-Verbose -Message ('Moving {0} to Host-18' -f $server)
      move-vm $server -Destination $host18 #-whatif
    }
  }

  foreach($server in $tagged19){
    if($server.vmhost.name -ne $host19){
      Write-Verbose -Message ('Moving {0} to Host-19' -f $server)
      move-vm $server -Destination $host19 #-whatif
    }
  }

}



# Begin Script

#Get list of Norfolk VM's under control of vCenter
$rebootOther = 'y'
$balance = 'y'
$NorfolkHosts = Get-VMHost | Where-Object {$_.name -notlike '214.54.208.*'}

Clear-Host
Write-Verbose -Message 'Welcome to the Reboot and Balance Center'
Start-Sleep -Seconds 4
Clear-Host

$NorfolkHosts.name | Format-Table Name
$HostOne = Read-Host -Prompt 'Enter the host IP Address you want to reboot'
$HostTwo = Read-Host -Prompt 'Enter other host'   # $NorfolkHosts.name -ne $HostOne | Out-String
MoveVMsRebootHost -HostOne $HostOne -HostTwo $HostTwo

$rebootOther = Read-Host -Prompt 'Would you like to reboot the other host [y]/n: '
if($rebootOther -eq 'y'){
  MoveVMsRebootHost $HostTwo $HostOne
}

$balance = Read-Host -Prompt 'Would you like to balance the servers [y]/n: '
if($balance -eq 'y'){
  BalanceVMs
}



