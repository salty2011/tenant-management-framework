﻿function Invoke-TmfGroup
{
	[CmdletBinding()]
	Param (
		[string[]] $specificResources,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
		
	
	begin
	{
		$resourceName = "groups"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "Group"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		if ($specificResources) {
        	$testResults = Test-TmfGroup -specificResources $specificResources -Cmdlet $Cmdlet
		}
		else {
			$testResults = Test-TmfGroup -Cmdlet $Cmdlet
		}

		foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
			switch ($result.ActionType) {
				"Create" {
					$requestUrl = "$script:graphBaseUrl/groups"
					$requestMethod = "POST"
					$requestBody = @{
						"description" = $result.DesiredConfiguration.description
						"displayName" = $result.DesiredConfiguration.displayName						
					}

					try {
						@("mailNickname", "groupTypes", "mailEnabled", "isAssignableToRole", "securityEnabled") | ForEach-Object {
							if ($result.DesiredConfiguration.Properties() -contains $_) {
								$requestBody[$_] = $result.DesiredConfiguration.$_
							}
						}

						if ($result.DesiredConfiguration.Properties() -contains "members") {
							if ($result.DesiredConfiguration.members.count -gt 0) {
								$requestBody["members@odata.bind"] = @($result.DesiredConfiguration.members | ForEach-Object {"$script:graphBaseUrl/users/{0}" -f (Resolve-User -InputReference $_ -Cmdlet $Cmdlet)})
							}
						}
						if ($result.DesiredConfiguration.Properties() -contains "owners") {
							if ($result.DesiredConfiguration.owners.count -gt 0) {
								$requestBody["owners@odata.bind"] = @($result.DesiredConfiguration.owners | ForEach-Object {"$script:graphBaseUrl/users/{0}" -f (Resolve-User -InputReference $_ -Cmdlet $Cmdlet)})
							}							
						}
						if ($result.DesiredConfiguration.Properties() -contains "membershipRule") {
							$requestBody["membershipRule"] = $result.DesiredConfiguration.membershipRule
							$requestBody["membershipRuleProcessingState"] = "On"
						}
						
						$requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
				}
				"Delete" {
					$requestUrl = "$script:graphBaseUrl/groups/{0}" -f $result.GraphResource.Id
					$requestMethod = "DELETE"
					try {
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $requestMethod, $requestUrl
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
				}
				"Update" {
					$requestUrl = "$script:graphBaseUrl/groups/{0}" -f $result.GraphResource.Id
					$requestMethod = "PATCH"
					$requestBody = @{}
					try {
						foreach ($change in $result.Changes) {						
							switch ($change.Property) {
								"members" {
									foreach ($action in $change.Actions.Keys) {
										switch ($action) {
											"Add" {
												$url = "$script:graphBaseUrl/groups/{0}/members/`$ref" -f $result.GraphResource.Id
												$method = "POST"
												$change.Actions[$action] | ForEach-Object {													
													$body = @{ "@odata.id" = "$script:graphBaseUrl/users/{0}" -f $_ } | ConvertTo-Json -ErrorAction Stop
													Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $method, $url, $body
													Invoke-MgGraphRequest -Method $method -Uri $url -Body $body
												}
											}
											"Remove" {												
												$method = "DELETE"
												$change.Actions[$action] | ForEach-Object {
													$url = "$script:graphBaseUrl/groups/{0}/members/{1}/`$ref" -f $result.GraphResource.Id, $_
													Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $method, $url
													Invoke-MgGraphRequest -Method $method -Uri $url
												}
											}
										}
									}
								}
								"owners" {
									foreach ($action in $change.Actions.Keys) {
										switch ($action) {
											"Add" {
												$url = "$script:graphBaseUrl/groups/{0}/owners/`$ref" -f $result.GraphResource.Id
												$method = "POST"
												$change.Actions[$action] | ForEach-Object {													
													$body = @{ "@odata.id" = "$script:graphBaseUrl/users/{0}" -f $_ } | ConvertTo-Json -ErrorAction Stop
													Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $method, $url, $body
													Invoke-MgGraphRequest -Method $method -Uri $url -Body $body
												}
											}
											"Remove" {												
												$method = "DELETE"
												$change.Actions[$action] | ForEach-Object {
													$url = "$script:graphBaseUrl/groups/{0}/owners/{1}/`$ref" -f $result.GraphResource.Id, $_
													Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $method, $url
													Invoke-MgGraphRequest -Method $method -Uri $url
												}
											}
										}
									}
								}
								default {
									foreach ($action in $change.Actions.Keys) {
										switch ($action) {
											"Set" { $requestBody[$change.Property] = $change.Actions[$action] }
										}
									}									
								}
							}							
						}

						if ($requestBody.Keys -gt 0) {
							$requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop
							Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
							Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody
						}
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
				}
				"NoActionRequired" { }
				default {
					Write-PSFMessage -Level Warning -String "TMF.Invoke.ActionTypeUnknown" -StringValues $result.ActionType
				}				
			}
			Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
		}		
	}
	end
	{
		Load-TmfConfiguration -Cmdlet $Cmdlet
	}
}
