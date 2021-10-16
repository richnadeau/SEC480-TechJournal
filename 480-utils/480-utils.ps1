Function Read-HostDefault([string]$prompt, [string]$default)
{
    if (!$prompt) 
    {
        Write-Host "Using default: "$default
    } else {
        Write-Host "Using: "$prompt 
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
        $server = Read-Host "What vCenter server would you like to connect to? ["$global:config.vcenter_server"]"
        Read-HostDefault($vspherehost,$global:config.vcenter_server)
        if (!$server){
            $server = $global:config.vcenter_server
        }
        $conn = Connect-VIServer -Server $server
    }
    return $conn
} 

Function check_index ([int]$selection,[int]$max)
{

}

Function pick_host()
{
    $vspherehost = Read-Host "What server would you like to host this vm with? ["$global:config.vm_host"]"
    Read-HostDefault($vspherehost,$global:config.vm_host)
    if (!$vspherehost){
        $global:vmhost = Get-VMHost -Name $global:config.vm_host
    } else {
        $global:vmhost = Get-VMHost -Name $vspherehost
    }
}

Function pick_vm([string] $folder)
{
    $folder = Read-Host "Which folder is the VM you want to clone in? ["$global:config.base_folder"]"
    Read-HostDefault($vspherehost,$global:config.base_folder)
    if (!$folder){
        $basefolder = Get-Folder -Name $global:config.base_folder
    } else {
        $basefolder = Get-Folder -Name $folder
    }   
    $vmlist = $basefolder | Get-VM | Select-Object Name
    $vmlist
    $clonevm = Read-Host "Which VM from those listed above do you want to clone?"
    # Working on this
    $chosenvm = Get-VM $clonevm
    Get-Snapshot -VM $clonevm 
    $snapshot = Read-Host "Which Snapshot do you want to make a clone from?"
    $clonesnapshot = Get-Snapshot -VM $clonevm -Name $snapshot
    $linked = Read-Host "[L]inked or [F]ull Clone"
    $vmname = Read-Host "What do you want your cloned VM to be named?"
    if ($linked = "L"){
        $newvm = New-VM -Name $vmname -VM $chosenvm -LinkedClone -ReferenceSnapshot $clonesnapshot -VMHost $global:vmhost -Datastore $global:datastore
    } elseif ("F") {
        $newvm = New-VM -Name $vmname -VM $chosenvm - -ReferenceSnapshot $clonesnapshot -
    }
    $newvm
}

Function pick_datastore()
{
    $dstore = Read-Host "What datastore would you like the vm to be hosted on? ["$global:config.datastore"]"
    Read-HostDefault($dstore,$global:config.datastore)
    if (!$dstore){
        $global:datastore = Get-DataStore $global:config.datastore
    } else {
        $global:datastore = Get-DataStore $dstore
    }
}

Function pick_network([string] $vmhost_name)
{
    $network = Read-Host "What network would you like the vm to be on? ["$global:config.network"]"
    Read-HostDefault($network,$global:config.network)
    if (!$network){
        $network = $global:config.network
    }
    $vmhost_name | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $network -Confirm:$false
}

Function get-config([string] $config_path)
{
    $global:config = (get-content $config_path) | ConvertFrom-Json
}

Function cloner ($config_path)
{
    get-config($config_path)
    connect
    pick_host
    pick_datastore
    pick_vm
    
}

# Temporary Main, Remove before making a module
cloner -config_path "480-utils.json"