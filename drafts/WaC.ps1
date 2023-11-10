# Activation des fonctionnalités Windows
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45 -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-BasicAuthentication -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CertProvider -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DirectoryBrowsing -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HealthAndDiagnostics -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HostableWebCore -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionDynamic -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIFilter -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementScriptingTools -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45 -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Performance -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerManagementTools -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebSockets -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WindowsAuthentication -All
Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All
Enable-WindowsOptionalFeature -Online -FeatureName NetFx4-AdvSrvs -All
Enable-WindowsOptionalFeature -Online -FeatureName NetFx4Extended-ASPNET45 -All
Enable-WindowsOptionalFeature -Online -FeatureName WCF-HTTP-Activation -All
Enable-WindowsOptionalFeature -Online -FeatureName WCF-HTTP-Activation45 -All
Enable-WindowsOptionalFeature -Online -FeatureName WCF-NonHTTP-Activation -All
Enable-WindowsOptionalFeature -Online -FeatureName WCF-Services45 -All

# Modification du registre
# Disable Loopback Check on a Server - to get around no local Logins on Windows Server
New-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa -Name 'DisableLoopbackCheck' -Value '1' -PropertyType dword
# Disable Hide file extensions for known file types
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced HideFileExt '0'

# Installation des applications dont on gère le cycle de mise à jour (sans intégration shell)
Invoke-RestMethod get.scoop.sh | Invoke-Expression
scoop bucket add extras
scoop bucket add versions
scoop bucket add nerd-fonts
scoop bucket add java
scoop install main/dotnet-sdk
scoop install main/gh
scoop install main/git
scoop install main/nvm
scoop install main/oh-my-posh
scoop install main/terraform
scoop install versions/dotnet3-sdk
scoop install versions/dotnet5-sdk
scoop install versions/dotnet6-sdk
scoop install extras/baretail
scoop install extras/mockoon
scoop install extras/nuget-package-explorer
scoop install extras/paint.net
scoop install extras/postman
scoop install extras/vlc
scoop install extras/wiztree
scoop install nerd-fonts/CascadiaCode-NF-Mono
scoop install nerd-fonts/FiraCode-NF
scoop install java/temurin-lts-jdk

# Installation des applications dont on gère le cycle de mise à jour (avec intégration shell)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install 7zip -y
choco install bulkrenameutility -y
choco install notepadplusplus -y
choco install urlrewrite -y
choco install webdeploy -y
choco install winmerge -y

# Installation des applications dont on ne gère pas le cycle de mise à jour
winget install -e -h --accept-package-agreements --accept-source-agreements --id Fork.Fork
winget install -e -h --accept-package-agreements --accept-source-agreements --id Microsoft.PowerShell
winget install -e -h --accept-package-agreements --accept-source-agreements --id Microsoft.PowerToys
winget install -e -h --accept-package-agreements --accept-source-agreements --id Microsoft.PowerBI
winget install -e -h --accept-package-agreements --accept-source-agreements --id Microsoft.VisualStudioCode
winget install -e -h --accept-package-agreements --accept-source-agreements --id Microsoft.VisualStudio.2022.Professionnal --override '--passive --config .vsconfig'
winget install -e -h --accept-package-agreements --accept-source-agreements --id Google.Chrome

# Node
nvm install lts
nvm use lts

# Certificats
Import-Certificate -CertStoreLocation Cert:\LocalMachine\Root -FilePath 'C:\...'

# Exclusions antivirus
Add-MpPreference -ExclusionPath 'C:\Projets'
Add-MpPreference -ExclusionPath 'C:\Users\%user%\.dotnet\tools'

# Lecteur réseau
New-PSDrive -Name O -Root \\cifs-hdr2\partagehdr-dfs$ -PSProvider FileSystem -Persist -Credential x.prestataire@maregionsud.fr
