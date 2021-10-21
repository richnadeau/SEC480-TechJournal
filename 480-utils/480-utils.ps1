Function Read-HostDefault([string]$prompt)
{
    if (!$prompt){
        Write-Host "You are using the default value."
    } else {
        Write-Host "You chose:" $prompt
    }

}

Function connect([string] $server)
{
    $conn = $global:DefaultVIServer
    # Test to see if already connected
    if ($conn){
        $msg = "Connected to: {0}" -f $conn

        Write-Host $msg
    }else 
    {     
        if (!$server){
            $server = $global:config.vcenter_server
        }
        $conn = Connect-VIServer -Server $server
    }
    return $conn
} 

Function pick_host()
{
    Get-VMHost | Select-Object Name
    $vspherehost = Read-Host "What server would you like to host this vm with? ["$global:config.vm_host"]"
    Read-HostDefault($vspherehost)
    if (!$vspherehost){
        $global:vmhost = Get-VMHost -Name $global:config.vm_host
    } else {
        $global:vmhost = Get-VMHost -Name $vspherehost
    }
}

Function pick_vm()
{
    Get-Folder -Type VM | Select-Object Name
    $folder = Read-Host "Which folder is the VM you want to clone in? ["$global:config.base_folder"]"
    Read-HostDefault($folder)
    if (!$folder){
        $basefolder = Get-Folder -Name $global:config.base_folder
    } else {
        $basefolder = Get-Folder -Name $folder
    }   
    $vmlist = $basefolder | Get-VM 
    $numba = -1
    foreach ($vm in $vmlist)
    {
        $numba = $numba + 1
        Write-Host "$numba. " $vm.Name
    }
    $clonevm = Read-Host "Which VM from those listed above do you want to clone?"
    $selectedvm = $vmlist[$clonevm]
    # Working on this
    $selectedvm = Get-VM $selectedvm
    Get-Snapshot -VM $selectedvm | Select-Object Name
    $snapshot = Read-Host "Which Snapshot do you want to make a clone from? ["$global:config.snapshot"]"
    if(!$snapshot){
        $snapshot = Get-Snapshot -VM $selectedvm -Name $global:config.snapshot
    }
    $clonesnapshot = Get-Snapshot -VM $selectedvm -Name $snapshot
    $vmname = Read-Host "What do you want your cloned VM to be named? ["$selectedvm.name".linked]"
    if (!$vmname){
        $vmname = "{0}.linked" -f $selectedvm.name
    }
    Read-HostDefault($vmname)
    $linked = Read-Host "[L]inked or [F]ull Clone"
    if ($linked -match "L"){
        Write-Host ("You have selected  to have a Linked Clone")
        $global:newvm = New-VM -Name $vmname -VM $selectedvm -LinkedClone -ReferenceSnapshot $clonesnapshot -VMHost $global:vmhost -Datastore $global:datastore -Location $basefolder 
    } elseif ($linked -match "F") {
        Write-Host ("You have selected  to have a Full Clone")
        $fullclonename = Read-Host "What do you want your fully cloned VM to be called? ["$selectedvm.name".base]"
        Read-HostDefault($fullclonename)
        if (!$fullclonename){
            $fullclonename = "{0}.base" -f $selectedvm.name
        }
        $linkedvm = New-VM -Name $vmname -VM $selectedvm -LinkedClone -ReferenceSnapshot $clonesnapshot -VMHost $global:vmhost -Datastore $global:datastore -Location $basefolder
        $global:newvm = New-VM -Name $fullclonename -VM $linkedvm -VMHost $global:vmhost -Datastore $global:datastore -Location $basefolder
    } else {
        Write-Host ("Sorry that was not a valid option, please run the script again.") -BackgroundColor Red
        Break
    }
}

Function pick_datastore()
{
    Get-Datastore | Select-Object Name
    $dstore = Read-Host "What datastore would you like the vm to be hosted on? ["$global:config.datastore"]"
    Read-HostDefault($dstore)
    if (!$dstore){
        $global:datastore = Get-DataStore $global:config.datastore
    } else {
        $global:datastore = Get-DataStore $dstore
    }
}

Function pick_network()
{
    $network = Read-Host "What network would you like the vm to be on? ["$global:config.network"]"
    Read-HostDefault($network)
    if (!$network){
        $network = $global:config.network
    }
    $global:newvm | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $network -Confirm:$false
}

Function get-config([string] $config_path)
{
    $global:config = (get-content $config_path) | ConvertFrom-Json
}

Function cloner ($config_path)
{
    get-config($config_path)
    $server = Read-Host "What vCenter server would you like to connect to? ["$global:config.vcenter_server"]"
    Read-HostDefault($server)
    connect($server)
    pick_host
    pick_datastore
    pick_vm
    pick_network
}

Function createNetwork ([string] $networkName, [string] $esxi_host_name, [string] $vcenter_server) {
    if(!$networkName) {
        Write-Host -BackgroundColor Red "Please put in a value for the -networkName parameter!"
        Break
    }
    get-config("480-utils.json")
    connect($vcenter_server)
    if(!$esxi_host_name){
        New-VirtualSwitch -Name $networkName -VMHost $global:config.vm_host
    } elseif($esxi_host_name) {
        New-VirtualSwitch -Name $networkName -VMHost $esxi_host_name
    }
    New-VirtualPortGroup -Name $networkName -VirtualSwitch $networkName
    

}

Function startVMs ([string] $Name, [string] $vcenter_server, [Boolean] $Force) {
    if(!$Name) {
        Write-Host -BackgroundColor Red "Please put in a value for the -Name parameter!"
        Break
    }
    get-config("480-utils.json")
    connect($vcenter_server)
    if ($Force -match $true){
        Start-VM -VM $Name 
    }
    else {
        Start-VM -VM $Name -Confirm
    }
}

# Temporary Main, Remove before making a module
# createNetwork -networkName "BLUE1-WAN" -esxi_host_name "super8.cyber.local" -vcenter_server "vcenter.nadeau.local"
# cloner -config_path "480-utils.json"
# startVMs -Name blue8-fw -vcenter_server "vcenter.nadeau.local" -Force $true