scoop update *
scoop cleanup * -k
choco upgrade all -y
winget upgrade -e -h --accept-package-agreements --accept-source-agreements --id Microsoft.PowerShell
winget upgrade -e -h --accept-package-agreements --accept-source-agreements --id Microsoft.PowerToys
winget upgrade -e -h --accept-package-agreements --accept-source-agreements --id Microsoft.PowerBI
