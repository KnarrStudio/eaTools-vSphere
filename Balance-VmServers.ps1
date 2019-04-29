$host18 = "192.168.1.18"
$host19 = "192.168.1.19"


$tagged18 = get-vm -tag "host_18"
$tagged19 = get-vm -tag "host_19"

$servers = Get-VM

foreach($server in $tagged18){
    if($server.vmhost.name -ne $host18){
        Write-Host "Moving $server to Host-18"
        move-vm $server -Destination $host18 #-whatif
       }
    }
    
    foreach($server in $tagged19){
       if($server.vmhost.name -ne $host19){
       Write-Host "Moving $server to Host-19"
       move-vm $server -Destination $host19 #-whatif
        }
    }
