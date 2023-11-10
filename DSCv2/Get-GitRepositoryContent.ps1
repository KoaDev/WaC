<#
.SYNOPSIS
Downloads and extracts the content of a Git repository from GitHub or GitLab.

.DESCRIPTION
The Get-GitRepositoryContent function downloads the content of a specified Git repository from GitHub or GitLab and extracts it into the specified destination path. It can handle repositories from public instances and requires a personal access token for private repositories.

.PARAMETER RepositoryBaseUrl
The base URL of the Git repository to download.

.PARAMETER Branch
The branch of the repository to download. Defaults to 'main'.

.PARAMETER DestinationPath
The local file system path where the repository content should be extracted.

.PARAMETER PersonalAccessToken
A personal access token for accessing private repositories. Ensure to handle this securely.

.PARAMETER ServiceType
Explicitly specify the service type if the repository is hosted on a private instance. Valid options are 'GitHub' or 'GitLab'.

.EXAMPLE
Get-GitRepositoryContent -RepositoryBaseUrl "https://github.com/user/repo" -DestinationPath "C:\Path\To\Destination"

Downloads the main branch of the specified GitHub repository and extracts its content to the given destination path.

.EXAMPLE
Get-GitRepositoryContent -RepositoryBaseUrl "https://privategitinstance.com/user/repo" -ServiceType "GitLab" -Branch "develop" -DestinationPath "C:\Path\To\Destination" -PersonalAccessToken "your_token"

Downloads the develop branch of a GitLab repository hosted on a private instance and extracts it to the specified path using the provided personal access token.
#>
function Get-GitRepositoryContent
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RepositoryBaseUrl,

        [Parameter()]
        [string]$Branch = 'main',

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [Parameter()]
        [string]$PersonalAccessToken,

        [Parameter()]
        [ValidateSet('GitHub', 'GitLab')]
        [string]$ServiceType
    )

    # Determine service type from the base URL if not provided
    if (-not $ServiceType)
    {
        $ServiceType = switch -Regex ($RepositoryBaseUrl)
        {
            'github\.com'
            {
                'GitHub' 
            }
            'gitlab\.com'
            {
                'GitLab' 
            }
            default
            {
                throw 'Unable to determine service type from URL. Please specify the ServiceType parameter.' 
            }
        }
    }

    $archiveUrl = Get-DownloadUrl -BaseUrl $RepositoryBaseUrl -Service $ServiceType -BranchName $Branch

    # Call the download and extraction logic (implementation not shown here for brevity)
    DownloadAndExtractRepo -ArchiveUrl $archiveUrl -DestinationPath $DestinationPath -PersonalAccessToken $PersonalAccessToken -ServiceType $ServiceType
}

function Get-DownloadUrl
{
    param (
        [string]$BaseUrl,
        [string]$Service,
        [string]$BranchName
    )
    
    $repoName = ($BaseUrl -split '/')[-1]

    return switch ($Service) {
        'GitHub'
        { "$BaseUrl/archive/$BranchName.zip" }
        'GitLab'
        { "$BaseUrl/-/archive/$BranchName/$repoName-$BranchName.zip" }
        default
        { throw "Unsupported service type: $Service" }
    }
}

function DownloadAndExtractRepo
{
    param (
        [string]$ArchiveUrl,
        [string]$DestinationPath,
        [string]$PersonalAccessToken,
        [string]$ServiceType
    )

    $zipFilePath = Join-Path -Path $DestinationPath -ChildPath 'repo.zip'

    if (-not (Test-Path -Path $DestinationPath))
    {
        New-Item -ItemType Directory -Path $DestinationPath -Force
    }

    $headers = @{}
    if ($PersonalAccessToken)
    {
        $headers['Authorization'] = switch ($ServiceType)
        {
            'GitHub'
            {
                "token $PersonalAccessToken" 
            }
            'GitLab'
            {
                "Bearer $PersonalAccessToken" 
            }
        }
    }

    try
    {
        Invoke-WebRequest -Uri $ArchiveUrl -Headers $headers -OutFile $zipFilePath
        Expand-Archive -Path $zipFilePath -DestinationPath $DestinationPath -Force
        Remove-Item -Path $zipFilePath -Force
        Write-Host "Repository content downloaded and extracted to: $DestinationPath"
    }
    catch
    {
        Write-Error "An error occurred: $_"
    }
}
