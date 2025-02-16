<#
.SYNOPSIS
   Check whether a certificate is still trusted and when it runs out or starts.
.DESCRIPTION
   Invoke-IcingaCheckCertificate returns either 'OK', 'WARNING' or 'CRITICAL', based on the thresholds set.
   e.g a certificate will run out in 30 days, WARNING is set to '20d:', CRITICAL is set to '50d:'. In this case the check will return 'WARNING'.

   More Information on https://github.com/Icinga/icinga-powershell-plugins
.FUNCTIONALITY
   This module is intended to be used to check if a certificate is still valid or about to become valid.
.EXAMPLE
   You can check certificates in the local certificate store of Windows:

   PS> Invoke-IcingaCheckCertificate -CertStore 'LocalMachine' -CertStorePath 'My' -CertSubject '*' -WarningEnd '30d:' -CriticalEnd '10d:'
   [OK] Check package "Certificates" (Match All)
   \_ [OK] Certificate 'test.example.com' (valid until 2033-11-19 : 4993d) valid for: 431464965.59
.EXAMPLE
   Also a directory with a file name pattern is possible:

   PS> Invoke-IcingaCheckCertificate -CertPaths "C:\ProgramData\icinga2\var\lib\icinga2\certs" -CertName '*.crt' -WarningEnd '10000d:'
   [WARNING] Check package "Certificates" (Match All) - [WARNING] Certificate 'test.example.com' (valid until 2033-11-19 : 4993d) valid for, Certificate 'Icinga CA' (valid until 2032-09-18 : 4566d) valid for
   \_ [WARNING] Certificate 'test.example.com' (valid until 2033-11-19 : 4993d) valid for: Value "431464907.76" is lower than threshold "864000000"
   \_ [WARNING] Certificate 'Icinga CA' (valid until 2032-09-18 : 4566d) valid for: Value "394583054.72" is lower than threshold "864000000"
.EXAMPLE
   The checks can be combined into a single check:

   PS> Invoke-IcingaCheckCertificate -CertStore 'LocalMachine' -CertStorePath 'My' -CertThumbprint '*'-CertPaths "C:\ProgramData\icinga2\var\lib\icinga2\certs" -CertName '*.crt' -Trusted
   [CRITICAL] Check package "Certificates" (Match All) - [CRITICAL] Certificate 'test.example.com' trusted, Certificate 'Icinga CA' trusted
   \_ [CRITICAL] Check package "Certificate 'test.example.com'" (Match All)
      \_ [OK] Certificate 'test.example.com' (valid until 2033-11-19 : 4993d) valid for: 431464853.88
      \_ [CRITICAL] Certificate 'test.example.com' trusted: Value "False" is not matching threshold "True"
   \_ [CRITICAL] Check package "Certificate 'Icinga CA'" (Match All)
      \_ [OK] Certificate 'Icinga CA' (valid until 2032-09-18 : 4566d) valid for: 394583000.86
      \_ [CRITICAL] Certificate 'Icinga CA' trusted: Value "False" is not matching threshold "True"

.PARAMETER Trusted
   Used to switch on trusted behavior. Whether to check, If the certificate is trusted by the system root.
   Will return Critical in case of untrusted.

   Note: it is currently required that the root and intermediate CA is known and trusted by the local system.

.PARAMETER CriticalStart
   Used to specify a date. The start date of the certificate has to be past the date specified, otherwise the check results in critical. Use carefully.
   Use format like: 'yyyy-MM-dd'

.PARAMETER WarningEnd
   Used to specify a Warning range for the end date of an certificate. In this case a string.
   Allowed units include: ms, s, m, h, d, w, M, y

.PARAMETER CriticalEnd
   Used to specify a Critical range for the end date of an certificate. In this case a string.
   Allowed units include: ms, s, m, h, d, w, M, y

.PARAMETER CertStore
   Used to specify which CertStore to check. Valid choices are 'None', '*', 'LocalMachine', 'CurrentUser'.
   Use 'None' if you do not want to check the certificate store (Default)

 .PARAMETER CertThumbprint
   Used to specify an array of Thumbprints, which are used to determine what certificate to check, within the CertStore.

.PARAMETER CertSubject
   Used to specify an array of Subjects, which are used to determine what certificate to check, within the CertStore.

.PARAMETER CertStorePath
   Used to specify which path within the CertStore should be checked.

.PARAMETER CertPaths
   Used to specify an array of paths on your system, where certificate files are. Use with CertName.

.PARAMETER CertName
   Used to specify an array of certificate names of certificate files to check. Use with CertPaths.

.PARAMETER Recurse
    Includes sub-directories and entries while looking for certificates on a given path

.PARAMETER IgnoreEmpty
    Will return `OK` instead of `UNKNOWN`, in case no certificates for the given filter and path were found

.PARAMETER Verbosity
    Changes the behavior of the plugin output which check states are printed:
    0 (default): Only service checks/packages with state not OK will be printed
    1: Only services with not OK will be printed including OK checks of affected check packages including Package config
    2: Everything will be printed regardless of the check state
    3: Identical to Verbose 2, but prints in addition the check package configuration e.g (All must be [OK])

.PARAMETER ExcludePattern
   Used to specify an array of exclusions, tested against Subject, Subject Alternative Name and Issuer.

.INPUTS
   System.String
.OUTPUTS
   System.String
.LINK
   https://github.com/Icinga/icinga-powershell-plugins
.NOTES
#>

function Invoke-IcingaCheckCertificate()
{
    param(
        #Checking
        [switch]$Trusted       = $FALSE,
        $CriticalStart         = $null,
        $WarningEnd            = '30d:',
        $CriticalEnd           = '10d:',
        #CertStore-Related Param
        [ValidateSet('None', '*', 'LocalMachine', 'CurrentUser')]
        [string]$CertStore     = 'None',
        [array]$CertThumbprint = $null,
        [array]$CertSubject    = $null,
        [array]$ExcludePattern = $null,
        $CertStorePath         = '*',
        #Local Certs
        [array]$CertPaths      = $null,
        [array]$CertName       = $null,
        [switch]$Recurse       = $FALSE,
        [switch]$IgnoreEmpty   = $FALSE,
        #Other
        [ValidateSet(0, 1, 2, 3)]
        [int]$Verbosity        = 0
    );

    $CertData    = Get-IcingaCertificateData `
        -CertStore $CertStore -CertThumbprint $CertThumbprint -CertSubject $CertSubject -ExcludePattern $ExcludePattern `
        -CertPaths $CertPaths -CertName $CertName -CertStorePath $CertStorePath -Recurse $Recurse;
    $CertPackage = New-IcingaCheckPackage -Name 'Certificates' -OperatorAnd -Verbose $Verbosity -IgnoreEmptyPackage:$IgnoreEmpty -AddSummaryHeader;

    if ($null -ne $CriticalStart) {
        try {
            [datetime]$CritDateTime = $CriticalStart;
        } catch {
            Exit-IcingaThrowException -ExceptionType 'Custom' -CustomMessage 'DateTimeParseError' -InputString (
                [string]::Format('The provided value "{0}" for argument "CriticalStart" could not be parsed as DateTime.', $CriticalStart)
            ) -Force;
        }
    }

    foreach ($data in $CertData) {
        $Cert = $data.Cert;

        if ($null -eq $Cert) {
            # Not a valid cert file - unknown check
            $CertPackage.AddCheck(
                (New-IcingaCheck -Name ([string]::Format("Not a certificate: {0}", $data.Path))).SetUnknown()
            );
            continue;
        }

        $SpanTilAfter = (New-TimeSpan -Start (Get-Date) -End $Cert.NotAfter);
        if ($Cert.Subject.Contains(',')) {
            [string]$CertName = $Cert.Subject.Split(",")[0];
        } else {
            [string]$CertName = $Cert.Subject;
        }

        $CertName = $CertName -ireplace '(cn|ou)=', '';
        if (($CertName -eq '') -or ($CertName -eq '')) {
            $CertName = $Cert.DnsNameList.Unicode.Split([System.Environment]::NewLine)[0]
        }
        $CheckNamePrefix = "Certificate '${CertName}'";
        if ($data.ContainsKey('Path')) {
            $CheckNamePrefix += (" at " + $data.Path)
        }

        $checks = @();

        if ($Trusted) {
            $CertValid   = Test-Certificate $cert -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
            $IcingaCheck = New-IcingaCheck -Name "${CheckNamePrefix} trusted" -Value $CertValid;
            $IcingaCheck.CritIfNotMatch($TRUE) | Out-Null;
            $checks += $IcingaCheck;
        }

        if ($null -ne $CriticalStart) {
            $CritStart   = ((New-TimeSpan -Start $Cert.NotBefore -End $CritDateTime) -gt 0)
            $IcingaCheck = New-IcingaCheck -Name "${CheckNamePrefix} already valid" -Value $CritStart;
            $IcingaCheck.CritIfNotMatch($TRUE) | Out-Null;
            $checks += $IcingaCheck;
        }

        if (($null -ne $WarningEnd) -Or ($null -ne $CriticalEnd)) {
            $ValidityInfo = ([string]::Format('valid until {0} : {1}d', $Cert.NotAfter.ToString('yyyy-MM-dd'), $SpanTilAfter.Days));
            $IcingaCheck  = New-IcingaCheck -Name "${CheckNamePrefix} ($ValidityInfo) valid for" -Value (New-TimeSpan -End $Cert.NotAfter.DateTime).TotalSeconds;
            $IcingaCheck.WarnOutOfRange($WarningEnd).CritOutOfRange($CriticalEnd) | Out-Null;
            $checks += $IcingaCheck;
        }

        if ($checks.Length -eq 1) {
            # Only add one check instead of the package
            $CertPackage.AddCheck($checks[0])
        } else {
            $CertCheck = New-IcingaCheckPackage -Name $CheckNamePrefix -OperatorAnd;
            foreach ($check in $checks) {
                $CertCheck.AddCheck($check)
            }
            $CertPackage.AddCheck($CertCheck)
        }
    }

    return (New-IcingaCheckResult -Name 'Certificates' -Check $CertPackage -NoPerfData $TRUE -Compile);
}
