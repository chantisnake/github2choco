function Read-GTCProfile {
	<#
	.SYNOPSIS
		This cmdlet reads your local profile
	
	.DESCRIPTION
		This function reads your local profile and convert it from a json string to a psobject
		the profile is loacted in the module root, and the file name is `profile.json`
		when the profile does not exist, this function will return a empty psobject
	
	.EXAMPLE
		PS C:\> Read-GTCProfile
		This will give you a PSobject converted from profile data
	
	.NOTES
		The profile is in the form that the PackageName maps to package properties,
		the package property is also stored in a dictionary where property name maps to property value
		Here is an example:
		{
			'PackageName1': {
				'PackagePropertyName1': 'PackagePropertyValue1',
				'PackagePropertyName2' : 'PackagePropertyValue2'
			},

			'PackageName2': {
				'PackagePropertyName1': 'PackagePropertyValue1',
				'PackagePropertyName2' : 'PackagePropertyValue2'
			}
		}
	
	#>
	[CmdletBinding()]
	param(
		
	)
	
	begin 
	{
		Write-Host ''
		$profileFullName = Get-GTCProfileLocation
		Write-Verbose "The profile's full name is $profileFullName"

	}
	
	process
	{
		if (Test-Path $profileFullName) 
		{
			Write-Verbose 'profile found'
			$profile = Get-Content $profileFullName | ConvertFrom-Json
		}
		else 
		{
			Write-Verbose 'Profile Not Found, starting with an empty profile'
			$profile = New-Object -TypeName psobject
		}	
	}
	
	end
	{
		return $profile	
	}
}


function Save-GTCProfile {
	<#
	.SYNOPSIS
		This function takes a profile and save it
	
	.DESCRIPTION
		This cmdlet takes a profile object (PSCustomObject) and then convert it to json and save it in the profile file (ModuleRoot/profile.json)
	
	.PARAMETER localProfile
		the Profile Object (PSCustomObject) that is converted from profile file (a json file indicating all the property of the packages)

	.EXAMPLE
		PS C:\> Save-GTCProfile -localProfile $profile
		this converts the $profile to json and write to the profile file
	
	.NOTES
		
	
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[System.Object] $localProfile
	)
	
	begin 
	{
		$profileFullName = Get-GTCProfileLocation
		Write-Verbose "The profile's full name is $profileFullName"
	}
	
	process 
	{
		ConvertTo-Json $localProfile | Out-File $profileFullName -Encoding utf8
	}
	
	end 
	{
		Write-Host 'Profile Successfully saved' -ForegroundColor Yellow
	}
}


function New-ProfileItem 
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
        [string] $githubRepo,
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $packageType,
        [Parameter(Mandatory = $true)]
        [string] $packageName,
        [Parameter(Mandatory = $true)]
        [string] $packagePath,
        [Parameter(Mandatory = $true)]
        [string] $templatePath,
        [Parameter(Mandatory = $false)]
        [string] $Regex32Bit,
        [Parameter(Mandatory = $false)]
        [string] $Regex64Bit,
        [Parameter(Mandatory = $false)]
        [bool] $isSourceCode,
        [Parameter(Mandatory = $false)]
        [string] $installerType,
        [Parameter(Mandatory = $false)]
        [string] $silentArg
	)
	
	begin 
	{
		        # set the initial property
        $properties = 
        @{
            'githubRepo' = $githubRepo
            'packageType' = $packageType
            'version' = ''
			'packagePath' = $packagePath
			'templatePath'= $templatePath
        }

        $Owner, $RepoName = Split-GithubRepoName -GithubRepo $githubRepo

       
	}
	
	process 
	{

        # add others:
        if ($Regex32Bit) { $properties.Add('Regex32bit', $Regex32Bit) }
        if ($Regex64Bit) { $properties.Add('Regex64bit', $Regex64Bit) }
        if ($isSourceCode) {$properties.Add('sourceCode', $isSourceCode) }
        if ($installerType) { $properties.Add('installerType', $installerType) }
        if ($silentArg) { $properties.Add('silentArg', $silentArg) }

        # add package to profile 
        Add-Member -InputObject $GTCProfile -memberType NoteProperty -Name $packageName -Value $properties

	}
	
	end 
	{
        # save profile
        Save-GTCProfile -localProfile $GTCProfile
	}
}


function New-VersionLog {
	<#
	.SYNOPSIS
		This function saves the version number in a file
	
	.DESCRIPTION
		This cmdlet saves the version number of a package to that package's package path to make accessing the version package more easily

	.PARAMETER packagePath
		The path of the chocolatey package

	.PARAMETER VersionNumer
		The version number of the software

	.EXAMPLE
		PS C:\> New-VersionLog -PackagePath '~/packageName' -VersionNumber '1.0.0'
		This will create a file 'latestVersion' in path '~/packageName/' with content '1.0.0'
	
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[String] $PackagePath,
		[Parameter(Mandatory = $true)]
		[string] $VersionNumber
	)
	
	begin 
	{
		$LogPath = Join-Path -Path $packagePath -ChildPath 'latestVersion'
	}
	
	process
	{
		# log
		Write-Host 'logging the latest version in the folder for you to access the latest version programatically' -ForegroundColor Green
		Write-Host "version log location will be $LogPath" -ForegroundColor Green

		# create the version number log
		$newVersion | Out-File $LogPath -Encoding utf8
	
	}
	
	end
	{
		Write-Host 'log saved' -ForegroundColor Green	
	}
}

