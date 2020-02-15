[DSCLocalConfigurationManager()]
Configuration EnvironmentSetup
{  
    Node $AllNodes.NodeName
    {
        Settings
        {
            RefreshMode = 'Push'
            RebootNodeIfNeeded = $false
        }
        
        PartialConfiguration NetworkingSetup
        {
            Description = 'Configurazione della rete e del firewall'
            RefreshMode = 'Push'
        }

        PartialConfiguration DatabaseServerSetup
        {
            Description = 'Configurazione del Database SQL Server'
            RefreshMode = 'Push'
        }
        
        PartialConfiguration WebServerSetup
        {
            Description = 'Configurazione del Web Server IIS'
            RefreshMode = 'Push'
            DependsOn   = '[PartialConfiguration]DatabaseServerSetup'
        }
    }
}