param(
    [ValidateSet("android", "ios", "all")]
    [string]$Platform = "all",
    [switch]$SkipPubGet,
    [switch]$BuildApk
)

$ErrorActionPreference = "Stop"

function Require-Env {
    param([string]$Name)

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Fehlende Environment-Variable: $Name"
    }
    return $value
}

function Invoke-FlutterBuild {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Args
    )

    Write-Host ""
    Write-Host ">> flutter $($Args -join ' ')" -ForegroundColor Cyan
    & flutter @Args
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter-Build fehlgeschlagen (ExitCode: $LASTEXITCODE)."
    }
}

$buildAndroid = $Platform -eq "android" -or $Platform -eq "all"
$buildIos = $Platform -eq "ios" -or $Platform -eq "all"

if (-not $SkipPubGet) {
    Write-Host ">> flutter pub get" -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw "flutter pub get fehlgeschlagen."
    }
}

if ($buildAndroid) {
    $androidGameIdRelease = Require-Env "UNITY_ADS_ANDROID_GAME_ID_RELEASE"
    $androidPlacementRelease = Require-Env "UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_RELEASE"

    $androidDefines = @(
        "--dart-define=UNITY_ADS_TEST_MODE=false",
        "--dart-define=UNITY_ADS_ANDROID_GAME_ID_RELEASE=$androidGameIdRelease",
        "--dart-define=UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_RELEASE=$androidPlacementRelease"
    )

    $androidBundleArgs = @("build", "appbundle") + $androidDefines
    Invoke-FlutterBuild -Args $androidBundleArgs

    if ($BuildApk) {
        $androidApkArgs = @("build", "apk") + $androidDefines
        Invoke-FlutterBuild -Args $androidApkArgs
    }
}

if ($buildIos) {
    if (-not $IsMacOS) {
        Write-Warning "iOS-Build uebersprungen: iOS-Release-Builds sind nur auf macOS moeglich."
    } else {
        $iosGameIdRelease = Require-Env "UNITY_ADS_IOS_GAME_ID_RELEASE"
        $iosPlacementRelease = Require-Env "UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_RELEASE"

        $iosDefines = @(
            "--dart-define=UNITY_ADS_TEST_MODE=false",
            "--dart-define=UNITY_ADS_IOS_GAME_ID_RELEASE=$iosGameIdRelease",
            "--dart-define=UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_RELEASE=$iosPlacementRelease"
        )

        $iosIpaArgs = @("build", "ipa") + $iosDefines
        Invoke-FlutterBuild -Args $iosIpaArgs
    }
}

Write-Host ""
Write-Host "Release-Build abgeschlossen." -ForegroundColor Green
