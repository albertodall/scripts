Configuration WebServerSetup {
    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName StorageDsc

    Node $AllNodes.NodeName 
    {
        WindowsFeature WebServer {
            Name = 'Web-Server'
        }

        WindowsFeature WebServerASPNet45 {
            Name = 'Web-Asp-Net45'
            DependsOn = '[WindowsFeature]WebServer'
        }

        WindowsFeatureSet WebServerHealthPerfSec {
            Name = @("Web-Health", "Web-Security", "Web-Performance", "Web-Http-Redirect", "Web-AppInit", "Web-WebSockets", "Web-Mgmt-Service", "NET-WCF-HTTP-Activation45")
            IncludeAllSubFeature = $true
            DependsOn = '[WindowsFeature]WebServerASPNet45'
        }

        WaitforDisk WaitForWebSitesDisk {
            DiskId = 1
            RetryIntervalSec = 60
            RetryCount = 60
        }

        Disk WebSitesDisk {
            DiskId = 1
            DriveLetter = 'D'
            FSFormat = 'NTFS'
            DependsOn = '[WaitForDisk]WaitForWebSitesDisk'
        }

        File ISBetsWebSitesFolder {
           DestinationPath = 'D:\ISBets'
           Type            = 'Directory'
           DependsOn       = '[Disk]WebSitesDisk'
        }

        File ISBetsWebFolder {
            DestinationPath = 'D:\ISBets\ISBetsWeb'
            Type            = 'Directory'
            DependsOn       = '[File]ISBetsWebSitesFolder'
        }

        xWebsite StopDefaultSite {
            Name            = 'Default Web Site'
            State           = 'Stopped'
            PhysicalPath    = 'C:\inetpub\wwwroot'
            DependsOn       = '[WindowsFeature]WebServer'
        }

        xWebAppPool CreateISBetsAppPool {
            Name = 'ISBetsWeb'
            State = 'Started'
            autoStart = $true
            managedRuntimeVersion = 'v4.0'
            queueLength = 5000
            DependsOn = '[WindowsFeature]WebServer'
        }
    }
}