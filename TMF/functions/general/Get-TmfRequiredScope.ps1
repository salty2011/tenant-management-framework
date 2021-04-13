﻿function Get-TmfRequiredScope
{
	<#
		.SYNOPSIS
			Returns required Microsoft Graph permission scopes.

		.DESCRIPTION
			Depending on the resources you want to configure, different Microsoft Graph
			permission scopes are required. This command returns the required scopes.

		.PARAMETER All
			Return all scopes that TMF requires.

		.PARAMETER Groups
			Return all scopes required for managing group-resources.

		.PARAMETER Users
			Return all scopes required for managing user-resources.
		
		.PARAMETER NamedLocations
			Return all scopes required for managing namedLocation-resources.
		
		.PARAMETER Agreements
			Return all scopes required for managing agreement-resources.
		
		.PARAMETER ConditionalAccessPolicies
			Return all scopes required for managing conditionalAccessPolicy-resources.
		
		.EXAMPLE
			PS> Connect-MgGraph -Scopes (Get-TMFRequiredScope -Groups)

			Requests access to Microsoft Graph with all required scopes for changes to group-resources.
		
		.EXAMPLE
			PS> Connect-MgGraph -Scopes (Get-TMFRequiredScope -All)

			Requests access to Microsoft Graph with access to all resources the TMF can handle.
	#>
	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $Groups,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $Users,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $NamedLocations,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $Agreements,
		[Parameter(ParameterSetName = "SpecifiedComponents")]
		[switch] $ConditionalAccessPolicies,
		[Parameter(ParameterSetName = "All")]
		[switch] $All
	)
	
	begin
	{		
		[string[]] $scopes = @()		
	}
	process
	{		
		if ($Groups -or $All) {
			$scopes += "Group.ReadWrite.All", "GroupMember.ReadWrite.All"
		}
		if ($Users -or $All) {
			$scopes += "User.ReadWrite.All"
		}
		if ($NamedLocations -or $All) {
			$scopes += "Policy.ReadWrite.ConditionalAccess"
		} 
		if ($Agreements -or $All) {
			$scopes += "Agreement.ReadWrite.All"
		}
		if ($ConditionalAccessPolicies -or $All) {
			$scopes += "Policy.ReadWrite.ConditionalAccess", "Policy.Read.All", "RoleManagement.Read.Directory", "Application.Read.All", "Agreement.Read.All"
		}
		
		return ($scopes | Sort-Object -Unique)
	}
}
