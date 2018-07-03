
function Set-KnownFolderPath {
    Param (
            [Parameter(Mandatory = $true)]
            [ValidateSet('AddNewPrograms', 'AdminTools', 'AppUpdates', 'CDBurning', 'ChangeRemovePrograms', 'CommonAdminTools', 'CommonOEMLinks', 'CommonPrograms', 'CommonStartMenu', 'CommonStartup', 'CommonTemplates', 'ComputerFolder', 'ConflictFolder', 'ConnectionsFolder', 'Contacts', 'ControlPanelFolder', 'Cookies', 'Desktop', 'Documents', 'Downloads', 'Favorites', 'Fonts', 'Games', 'GameTasks', 'History', 'InternetCache', 'InternetFolder', 'Links', 'LocalAppData', 'LocalAppDataLow', 'LocalizedResourcesDir', 'Music', 'NetHood', 'NetworkFolder', 'OriginalImages', 'PhotoAlbums', 'Pictures', 'Playlists', 'PrintersFolder', 'PrintHood', 'Profile', 'ProgramData', 'ProgramFiles', 'ProgramFilesX64', 'ProgramFilesX86', 'ProgramFilesCommon', 'ProgramFilesCommonX64', 'ProgramFilesCommonX86', 'Programs', 'Public', 'PublicDesktop', 'PublicDocuments', 'PublicDownloads', 'PublicGameTasks', 'PublicMusic', 'PublicPictures', 'PublicVideos', 'QuickLaunch', 'Recent', 'RecycleBinFolder', 'ResourceDir', 'RoamingAppData', 'SampleMusic', 'SamplePictures', 'SamplePlaylists', 'SampleVideos', 'SavedGames', 'SavedSearches', 'SEARCH_CSC', 'SEARCH_MAPI', 'SearchHome', 'SendTo', 'SidebarDefaultParts', 'SidebarParts', 'StartMenu', 'Startup', 'SyncManagerFolder', 'SyncResultsFolder', 'SyncSetupFolder', 'System', 'SystemX86', 'Templates', 'TreeProperties', 'UserProfiles', 'UsersFiles', 'Videos', 'Windows')]
            [string]$KnownFolder,

            [Parameter(Mandatory = $true)]
            [string]$Path
    )

    # Define known folder GUIDs
    $KnownFolders = @{
        
        'Desktop' = @('B4BFCC3A-DB2C-424C-B029-7FE99A87C641');
        'Documents' = @('FDD39AD0-238F-46AF-ADB4-6C85480369C7','f42ee2d3-909f-4907-8871-4c22fc0bf756');
        'Downloads' = @('374DE290-123F-4565-9164-39C4925E467B','7d83ee9b-2244-4e70-b1f5-5393042af1e4');
        'Favorites' = '1777F761-68AD-4D8A-87BD-30B759FA33DD';
        'Music' = @('4BD8D571-6D19-48D3-BE97-422220080E43','a0c69a99-21c8-4671-8703-7934162fcf1d');
        'Pictures' = @('33E28130-4E1E-4676-835A-98395C3BC3BB','0ddd015d-b06c-45d5-8c4c-f59713854639');
        'Videos' = @('18989B1D-99B5-455B-841C-AB7C74E4DDFC','35286a68-3c57-41a1-bbb1-0eae73d76c95');

    }


    # Define SHSetKnownFolderPath if it hasn't been defined already
    $Type = ([System.Management.Automation.PSTypeName]'KnownFolders').Type
    if (-not $Type) {
        $Signature = @'
[DllImport("shell32.dll")]
public extern static int SHSetKnownFolderPath(ref Guid folderId, uint flags, IntPtr token, [MarshalAs(UnmanagedType.LPWStr)] string path);
'@
        $Type = Add-Type -MemberDefinition $Signature -Name 'KnownFolders' -Namespace 'SHSetKnownFolderPath' -PassThru
    }

       # Make path, if doesn't exist
       if(!(Test-Path $Path -PathType Container)) {
             New-Item -Path $Path -type Directory -Force
    }

    # Validate the path
    if (Test-Path $Path -PathType Container) {
        # Call SHSetKnownFolderPath
        
        $KnownFolders[$KnownFolder] | ForEach-Object {
            return $Type::SHSetKnownFolderPath([ref]$_, 0, 0, $Path)
        } 
    } else {
        throw New-Object System.IO.DirectoryNotFoundException "Could not find part of the path $Path."
    }
       
       # Fix up permissions, if we're still here
       attrib +r $Path

       $Leaf = Split-Path -Path "$Path" -Leaf
}

Function Log {
	<#
	.EXAMPLE
		Log -Message "Test server" -Type "i"
#>
	 [CmdletBinding()]
        param(
            [parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage='Line to write to log file.')][string]$Message,
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage='<e/i/s Trace Type ERROR, INFO or SUCCESS')][ValidateSet('error','ok')][string]$Type
        )
		
        $objDateTime = Get-Date -Format ("yyyy-MM-dd hh:mm:ss")
		switch ($Type) {
			'error'{"ERROR,$objDateTime,$Message" >> $strPPC_LOG_Onedrive
            throw [System.IO.FileNotFoundException] "$Message"}
			'ok'{"OK,$objDateTime,$Message" >> $strPPC_LOG_Onedrive}
		}
}


############################################ VERSIONING, LOGGING - IMPORTANT! ####################################################
#Wordt gebruikt om regkey te plaatsen zodat we kunnen sturen op wanneer een script moet draaien of niet.

#Aanmaken van map C:\PPC_Logs (als deze nog niet bestaat) waar de logs worden weggeschreven.
$strPPC_LOG = "C:\Program Files\PeopleWare\PPC_Logs"
$strPPC_LOG_Onedrive = $strPPC_LOG + "\" + "OneDrive Install.txt" 
$strPPC_LOG_PPC_configuratie = $strPPC_LOG + "\" + "_PPC configuratie voltooid.txt" #Dit wordt gebruikt om te laten weten dat alle scripts zijn voltooid aangezien dit de laatste is die klaar is.

if(-not(Test-Path $strPPC_LOG)) {
    New-Item $strPPC_LOG -ItemType container
}



    #Kijken of OneDrive al is ingericht d.m.v. de andere scriptjes. Als dat niet zo is dan failed hij waardoor Intune hem later weer opnieuw afvuurt aangezien dan wellicht wel de andere scriptjes hebben gedraaid.
    $Notdone = $true

    DO {
        $ONEDRIVESYNC = Get-ItemPropertyValue -Path 'HKCU:\Software\Microsoft\OneDrive\Accounts\Business1' -Name 'UserFolder'

        if ($ONEDRIVESYNC)  {
            $Notdone = $false
        }
    } While ($Notdone)


    if ($ONEDRIVESYNC) {
        #Als de gebruiker al een keer succesvol OneDrive heeft ingericht en dus de mappen al heeft met eventueel data erin dan zou hij normaal gesproken failen. Maar door onderstaande stuk code 
        #zal hij de bestaande mappen renamen naar MAPNAAM1 zodat hij opnieuw de Folder Redirection kan koppelen en dus de mappen kan aanmaken. 
    
        Try {
            #Aanmaken van de mappen in OneDrive
            Set-KnownFolderPath -KnownFolder 'Desktop' -Path "$ONEDRIVESYNC\Desktop"
            Set-KnownFolderPath -KnownFolder 'Documents' -Path "$ONEDRIVESYNC\Documents"
            Set-KnownFolderPath -KnownFolder 'Pictures' -Path "$ONEDRIVESYNC\Pictures"
            Set-KnownFolderPath -KnownFolder 'Favorites' -Path "$ONEDRIVESYNC\Favorites"
            Set-KnownFolderPath -KnownFolder 'Videos' -Path "$ONEDRIVESYNC\Videos"

            Log -Message "Default folders zijn succesvol aangemaakt" -Type "ok"
        } Catch {
            $strFoutmelding = $error[0]
            Log -Message "Fout bij het aanmaken van de default folders. Foutmelding: $strFoutmelding" -Type "error" 
        } 

        Log -Message "OneDrive folder redirection is succesvol ingericht." -Type "ok"
        New-Item $strPPC_LOG_PPC_configuratie -ItemType file

    } else {
        $strFoutmelding = $error[0]
        Log -Message "OneDrive map niet gevonden in het register, enable OneDrive script heeft hoogstwaarschijnlijk niet gedraaid. Foutmelding: $strFoutmelding" -Type "error"
    }

