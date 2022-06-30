function Compare-PolicyProperties {
    Param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $ReferenceObject,
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $DifferenceObject,
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $PSCmdlet
    )

    begin {
        $same = $true
    }
    process {
        $properties = $ReferenceObject.GetEnumerator() | Where-Object {$_.Name -notin @('target','@odata.type')}
        foreach ($reference in $properties) {            
            if ($DifferenceObject.ContainsKey($reference.Key)) {     
                if ($null -eq $reference.Value) {
                    if ($null -ne $DifferenceObject[$reference.Key]) {
                        $same = $false
                    }
                }
                elseif ($reference.Value.GetType().Name -eq "Hashtable") {
                    if ($DifferenceObject[$reference.Key]) {
                        if (-Not (Compare-PolicyProperties -ReferenceObject $reference.Value -DifferenceObject ($DifferenceObject[$reference.Key] | ConvertTo-PSFHashtable))) {
                            $same = $false
                        }
                    }
                    else {
                        $same = $false
                    }
                }
                elseif ($reference.Value.GetType() -in @("System.Object[]", "string[]")) {
                    if ($null -eq ($reference.Value | ConvertTo-PSFHashtable)) {
                        if ($null -ne ($DifferenceObject[$reference.Key] | ConvertTo-PSFHashtable)) {
                            $same = $false
                        }
                    }
                    else {
                        if (-Not (Compare-PolicyProperties -ReferenceObject ($reference.Value | ConvertTo-PSFHashtable) -DifferenceObject ($DifferenceObject[$reference.Key] | ConvertTo-PSFHashtable))) {
                            $same = $false
                        }
                    }
                }
                else {
                    if ($reference.Value -ne $DifferenceObject[$reference.Key]) {
                        $same = $false
                    }
                }
            }
            else {
                Write-Host "Line 50: $($reference.Key)"
            }            
        }
    }
    end {
        return $same
    }
}