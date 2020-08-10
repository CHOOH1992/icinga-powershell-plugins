function Get-IcingaNetworkSpeedChecks()
{
    param (
        $Name,
        $LinkSpeed,
        $LinkSpeedWarning,
        $LinkSpeedCritical
    );

    [hashtable]$NetworkChecks = @{};
    $InterfaceSpeed           = Get-IcingaNetworkInterfaceUnits -Value $LinkSpeed;

    $NetworkChecks.Add(
        'CheckLinkSpeed',
        (
            New-IcingaCheck `
                -Name ([string]::Format('{0}: LinkSpeed', $Name)) `
                -Value $InterfaceSpeed `
                -NoPerfData
        ).WarnIfMatch(
            $LinkSpeedWarning
        ).CritIfMatch(
            $LinkSpeedCritical
        )
    );

    $NetworkChecks.Add(
        'PerfDataLinkSpeed',
        (
            New-IcingaCheck `
                -Name ([string]::Format('{0}: LinkSpeed', $Name)) `
                -Value $LinkSpeed `
        )
    );

    return $NetworkChecks;
}
