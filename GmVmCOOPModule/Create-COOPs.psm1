Function New-DRclone 
{
  <#
      .SYNOPSIS
      Short Description
      .DESCRIPTION
      Detailed Description
      .EXAMPLE
      Get-DRclone
      explains how to use the command
      can be multiple lines
      .EXAMPLE
      Get-DRclone
      another example
      can have as many examples as you like
  #>
  param
  (
    
    [Parameter(Position=0)]
    [string]
    $VmName = '*',
    
    [Parameter(Position=1)]
    [string]
    $VmTag = 'COOPdr',
    
    [Parameter(Position=2)]
    [string]
    $VMHostNameOrIp = '192.168.0.11',
    
    [Parameter(Position=3)]
    [string]
    $DataStoreStore = 'AllDRClones',
    
    [Parameter(Position=4)]
    [Object]
    $COOPPrefix = ('{0}{1}' -f $(Get-Date -UFormat '%Y%m%d'), '-COOP.')
  )
  
  # Variables
  $DoubleBoarderLine = '============================='
  $PrintNewLine = "`n"
  
  #get-vm *gm* -tag "COOPdr" | where {$_.powerstate -eq "PoweredOn"} | ft Name, ResourcePool -AutoSize
  #$VMServer  = get-vm *gm* | where {($_.powerstate -eq "PoweredOn") -and ($_.ResourcePool -like "Standard Server*") -and ($_.name -ne "rsrcngmfs02") -and ($_.name -ne "RSRCNGMNB01") -and ($_.name -ne "rsrcngmfs01") -and ($_.name -ne "rsrcngmcmps01")} | select Name, ResourcePool
  #get-vm *gm* | where {($_.powerstate -eq "PoweredOn") -and ($_.ResourcePool -like "Standard Server*") -and ($_.name -ne "rsrcngmfs02") -and ($_.name -ne "RSRCNGMNB01") -and ($_.name -ne "rsrcngmfs01") -and ($_.name -ne "rsrcngmcmps01")} | ft Name, ResourcePool -AutoSize
  
   
  function Get-NewClonedVms
  {
    param
    (
      [Parameter(Mandatory, ValueFromPipeline, HelpMessage='Data to filter')]
      [Object]$InputObject
    )
    process
    {
      if ($InputObject.Name -like $COOPPrefix)
      {
        $InputObject
      }
    }
  }
  
  function Get-OnlyPoweredOnVms
  {
    param
    (
      [Parameter(Mandatory, ValueFromPipeline, HelpMessage='Data to filter')]
      [Object]$InputObject
    )
    process
    {
      if ($InputObject.powerstate -eq 'PoweredOn')
      {
        $InputObject
      }
    }
  }
  
  
  $VMServerList  = get-vm $VmName -tag $VmTag | Get-OnlyPoweredOnVms
  
  Write-Host -Separator $PrintNewLine 
  Write-Host 'Information to be used to create the COOPs: ' -foregroundcolor black -backgroundcolor white #
  Write-Host -Separator $PrintNewLine $VMServerList | Format-Table -Property Name, ResourcePool -AutoSize 
  Write-Host -Separator $PrintNewLine 
  Write-Host $DoubleBoarderLine -foregroundcolor Yellow
  Write-Host 'Writing to: '$DataStoreStore -foregroundcolor Yellow
  Write-Host 'On VM Host: '$VMHostNameOrIp -foregroundcolor Yellow
  Write-Host 'Example of COOP file name: '$COOPPrefix$($VMServerList.Name[1]) -foregroundcolor Yellow
  Write-Host -Separator $PrintNewLine 
  
  Start-Sleep -Seconds $($VMServerList.count)
  
  foreach ($server in $VMServerList) 
  {
    Clear-Host
    Write-Host -Separator $PrintNewLine 'Completed'
    Write-Host $DoubleBoarderLine -foregroundcolor Yellow
    get-vm |
    Get-NewClonedVms |
    Select-Object -Property Name
    Write-Host 'New COOP Name: '$COOPPrefix$($server) 'In ResourcePool: '$server.ResourcePool -foregroundcolor Green -backgroundcolor black
    #Create the COOP copies with the information assigned to these var ($COOPPrefix, $VMserver, $dataStoreStore)
    #Write-Host "-name $COOPPrefix$($server) -vm $server -datastore $DataStoreStore -VMHost $VMHostIP -Location COOP -ResourcePool"$Server.ResourcePool
    New-vm -name $COOPPrefix$($server) -vm $server -datastore $DataStoreStore -VMHost $VMHostNameOrIp -Location COOP -ResourcePool $server.ResourcePool -Confirm
    
    # if(Get-Process -Name ApplicationFrameHost){}
  }
}

Export-ModuleMember -Function New-DRclone 

<#
    $server = Read-Host -Prompt 'Single COOP (ServerName) ' 
    $COOPPrefix+$server
    New-vm -name $COOPPrefix$($server) -vm $server -datastore $DataStoreStore -VMHost $VMHostNameOrIp -Location COOP -whatif

  
    $cntdwn = 5
    Write-Host ('Paused for {0} seconds.  Press CTRL+C to cancel' -f $cntdwn)
    for($i=$cntdwn;$i -ne 0;$i--){
    Write-Host ('.') -NoNewline
    Start-Sleep -Seconds 1
    }
#>