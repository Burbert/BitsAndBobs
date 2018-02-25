Function Invoke-PSModuleInstallation{
    <#
        .SYNOPSIS
            Installs or Updates a Powershell Module from PS Gallery
        .DESCRIPTION
            Installs or Updates a Powershell Module from PS Gallery.
            If there are multiple versions of the same module installed, this will remove all versions before it installs the desired one (use -Force).

            Requirements
                PS Version 5 or hihger
                RunAs Administrator

            by Christoph Burmeister - Twitter: @_Burbert - Github: Burbert
            Version: 1.1 - 02-25-2018
        .Parameter Name
            Name of the Powershell Module in PS Gallery.
        .Parameter Version
            Use either "Newest" or the Version Number - e.g. "2.7.0".
        .Parameter InstalledModules
            You can pass all currently installed modules to the function in order to safe some execution time - for example in a loop.
        .Parameter Scope
            Specifies the Modulescope - "Currentuser" or "AllUsers"
        .Parameter Force
            Use the Force-Parameter to remove multiple installed versions in order to install the desired one (only one will be left).
        .EXAMPLE
            Invoke-PSModuleInstallation -Name AzureRM -Version "Newest" -InstalledModules $InstalledModules -Scope AllUsers -Force -Verbose
        .EXAMPLE
            Invoke-PSModuleInstallation -Name vCloudDirector -Version "0.0.2" -InstalledModules (Get-Module -ListAvailable) -Force -Verbose
    #>
    #Requires -Version 5
    #Requires -RunAsAdministrator
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $false)]$Version = "Newest",
        [Parameter(Mandatory = $false)]$InstalledModules,
        [Parameter(Mandatory = $false)][ValidateSet("CurrentUser","AllUsers")]$Scope = "AllUsers",
        [Parameter(Mandatory = $false)][Switch]$Force
    )

    # check if the $InstalledModules Variable is filled
    if(-not($InstalledModules)){
        try{
            $InstalledModules = Get-Module -ListAvailable -ErrorAction Stop -Verbose:$False
        }catch{
            throw "$($($_.Exception).Message)"
        }
    }

    Write-Verbose "Scope: $Scope"

    # Check if Module is installed already and how often
    if($Name -in $($InstalledModules.Name)){
        Write-Verbose "Module $Name is installed"
        $CurrentModuleInstalled = $InstalledModules | Where-Object {$_.Name -eq $Name}
        if($CurrentModuleInstalled.Count -ne 1){
            if($Force.IsPresent){
                Write-Verbose "more than one version of Module $Name installed - uninstalling all versions"
                try{
                    Uninstall-Module -Name $Name -AllVersions -Force -Confirm:$False -ErrorAction Stop -Verbose:$False | Out-Null
                    Write-Verbose "All Version of Module $Name removed"
                }catch{
                    throw "$($($_.Exception).Message)"
                }
                # install Module
                if($Version -eq "newest"){
                    try{
                        Write-Verbose "installing latest Version of Module $Name"
                        Install-Module -Name $Name -Scope $Scope -SkipPublisherCheck -Force -ErrorAction Stop -Verbose:$False -AllowClobber | Out-Null
                        Write-Verbose "Module $Name installed"
                    }catch{
                        throw "$($($_.Exception).Message)"
                    }
                }else{
                    try{
                        Write-Verbose "installing required Version of Module $Name (Version :$Version)"
                        Install-Module -Name $Name -Scope $Scope -SkipPublisherCheck -Force -RequiredVersion $Version -AllowClobber -ErrorAction Stop -Verbose:$False | Out-Null
                        Write-Verbose "Module $Name installed"
                    }catch{
                        throw "Probably Version not found - Error: $($($_.Exception).Message)"
                    }
                }
            }else{
                throw "too many Versions of Module $Name - use the Force Parameter to uninstall all versions in order to install the one you desire"
            }
        }else{
            Write-Verbose "Only one Version of Module $Name is installed"
            Write-Verbose "Current Version: $($CurrentModuleInstalled.Version)"
            # find latest version in Gallery
            try{
                $LatestVersion = Find-Module -Name $Name -ErrorAction Stop -Verbose:$False
                Write-Verbose "Lates Version in PS Gallery: $($LatestVersion.Version)"
            }catch{
                Write-Verbose "Could not retrieve Moduleinfo from PS Gallery"
                throw "$($($_.Exception).Message)"
            }

            if($($CurrentModuleInstalled.Version) -eq $Version){
                Write-Verbose "Desired Version of Module $Name is already installed"
            }elseif( ($Version -ne "Newest") -and ($Version -ne $($CurrentModuleInstalled.Version)) ){
                Write-Verbose "Desired Version of Module $Name is not installed yet"
                try{
                    Write-Verbose "Starting removal of currently installed Module $Name (Version: $($CurrentModuleInstalled.Version))"
                    Uninstall-Module -Name $Name -AllVersions -Force -Confirm:$False -ErrorAction Stop -Verbose:$False | Out-Null
                    Write-Verbose "Module $Name successfully removed"
                }catch{
                    throw "$($($_.Exception).Message)"
                }

                try{
                    Write-Verbose "installing required Version of Module $Name (Version :$Version)"
                    Install-Module -Name $Name -Scope $Scope -SkipPublisherCheck -Force -RequiredVersion $Version -AllowClobber -ErrorAction Stop -Verbose:$False | Out-Null
                    Write-Verbose "Module $Name installed"
                }catch{
                    throw "Probably Version not found - Error: $($($_.Exception).Message)"
                }
            }elseif(($Version -eq "Newest") -and ($($LatestVersion.Version) -gt $($CurrentModuleInstalled.Version))){
                Write-Verbose "Newer Version is available - current: $($CurrentModuleInstalled.Version) - Gallery: $($LatestVersion.Version)"

                try{
                    Write-Verbose "Starting removal of currently installed Module $Name"
                    Uninstall-Module -Name $Name -AllVersions -Force -Confirm:$False -ErrorAction Stop -Verbose:$False | Out-Null
                    Write-Verbose "Module $Name successfully removed"
                }catch{
                    throw "$($($_.Exception).Message)"
                }
                
                try{
                    Write-Verbose "installing latest Version of Module $Name"
                    Install-Module -Name $Name -Scope $Scope -SkipPublisherCheck -Force -ErrorAction Stop -Verbose:$False -AllowClobber | Out-Null
                    Write-Verbose "Module $Name installed"
                }catch{
                    throw "$($($_.Exception).Message)"
                }
            }else{
                Write-Verbose "No Update required"
            }
        }
    }else{
        Write-Verbose "Module $Name is not installed yet"

        if($Version -eq "Newest"){
            try{
                Write-Verbose "installing latest Version of Module $Name"
                Install-Module -Name $Name -Scope $Scope -SkipPublisherCheck -Force -AllowClobber -ErrorAction Stop -Verbose:$False | Out-Null
                Write-Verbose "Module $Name installed"
            }catch{
                throw "$($($_.Exception).Message)"
            }
        }else{
            try{
                Write-Verbose "installing required Version of Module $Name (Version :$Version)"
                Install-Module -Name $Name -Scope $Scope -SkipPublisherCheck -Force -AllowClobber -RequiredVersion $Version -ErrorAction Stop -Verbose:$False | Out-Null
                Write-Verbose "Module $Name installed"
            }catch{
                throw "Probably Version not found - Error: $($($_.Exception).Message)"
            }
        }
    }
}
