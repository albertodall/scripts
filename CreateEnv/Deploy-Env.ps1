param(
    [Parameter(Mandatory=$true)] 
    [string] $EnvironmentDataFile,

    [bool] $UseHostsFile = $true
)

$ISOStoragePath = '\\ISARCHIVE-NAS2\SCVMM-Library\ISO'
$AdditionalComponentsFolder = 'D:\Install'
$GoldenImagePath = 'D:\VM\Hyper-V\GoldenImages'
$VMStorePath = 'D:\VM\Hyper-V'
$MOFOutputPath = 'D:\Temp\DSC'
$DeployUserName = 'Setup'
$DeployPassword = ConvertTo-SecureString -String "setup" -AsPlainText -Force
$VMAdministratorPassword = 'P@ssw0rd'

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    break
}

if ((Test-Path -Path $ISOStoragePath) -eq $false) {
    Write-Warning "ISO repository '$ISOStoragePath' not found, configuration cannot continue.`nPlease contact your network administrator."
    break
}

if ($UseHostsFile -and (-not (Get-Module -ListAvailable -Name PsHosts))) {
    Install-Module -Name PsHosts -Force
}

if (-not (Get-Module -ListAvailable -Name psTrustedHosts)) {
    Install-Module -Name psTrustedHosts -Force
}

. .\DSC\NetworkingSetup.ps1
. .\DSC\DatabaseServerSetup.ps1
. .\DSC\WebServerSetup.ps1
. .\DSC\EnvironmentSetup.ps1

$envDataFile = Import-PowerShellDataFile -Path $EnvironmentDataFile

$envDataFile.AllNodes | Where-Object { $_.NodeName -ne '*' } | ForEach-Object {
    $currentVMName = $_.NodeName

    # Create the VM and install prerequisites in it
    & .\Create-VM.ps1 -VMName $currentVMName -AdministratorPassword $VMAdministratorPassword -GoldenImagePath $GoldenImagePath -VMStorePath $VMStorePath -Verbose
    & .\Install-Prerequisites.ps1 -VMName $currentVMName -ISOStoragePath $ISOStoragePath -AdditionalComponentsFolder $AdditionalComponentsFolder -Verbose

    # Start VM if stopped, and waits for startup
    $VM = Get-VM -Name $currentVMName
    if ($VM.State -ieq 'Off') {
        Write-Verbose "Starting Virtual Machine $currentVMName..."
        $VM | Start-VM -Verbose
        Write-Verbose "Waiting for the VM $currentVMName to start up..."
        Start-Sleep -Seconds 90
        while ($VM.State -ine 'Running') { 
            Write-Information "Waiting for the VM $currentVMName to start up..."
            Start-Sleep -Seconds 5 
        }
    }
    
    $VMIPV4Address = (Get-VMNetworkAdapter -VMName $currentVMName).IpAddresses | Where-Object { $_ -match "\." }
    Add-HostEntry -Name $currentVMName -Address $VMIPV4Address -Verbose | Out-Null
    Add-TrustedHost $currentVMName -Verbose | Out-Null

    $DeployUserName = "$currentVMName\$DeployUserName"
    $DeployCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DeployUserName, $DeployPassword

    # Cleanup MOF target folder
    Get-ChildItem $MOFOutputPath -Include *.mof -Recurse | Remove-Item -Force -Verbose

    # Create MOF configuration files
    NetworkingSetup -OutputPath "$MOFOutputPath\Networking" -ConfigurationData $EnvironmentDataFile -Verbose
    DatabaseServerSetup -OutputPath "$MOFOutputPath\DatabaseServer" -ConfigurationData $EnvironmentDataFile -Verbose 
    WebServerSetup -OutputPath "$MOFOutputPath\WebServer" -ConfigurationData $EnvironmentDataFile -Verbose

    # Create DSC LCM Configuration MOF
    EnvironmentSetup -OutputPath "$MOFOutputPath\Config" -ConfigurationData $EnvironmentDataFile -Verbose

    # Configure LCM on target machine
    Set-DscLocalConfigurationManager -Path "$MOFOutputPath\Config" -Force -Verbose -Credential $DeployCredential -ComputerName $currentVMName

    # Publish DSC configurations on the target machine
    Publish-DscConfiguration -Path "$MOFOutputPath\Networking" -Force -Verbose -ComputerName $currentVMName -Credential $DeployCredential
    Publish-DscConfiguration -Path "$MOFOutputPath\DatabaseServer" -Force -Verbose -ComputerName $currentVMName -Credential $DeployCredential
    Publish-DscConfiguration -Path "$MOFOutputPath\WebServer" -Force -Verbose -ComputerName $currentVMName -Credential $DeployCredential

    Start-DscConfiguration -Force -Wait -UseExisting -ComputerName $currentVMName -Credential $DeployCredential -Verbose

    Remove-TrustedHost $currentVMName
    Remove-HostEntry $currentVMName
}