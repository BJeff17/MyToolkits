param(
    [Parameter(Position=0)]
    [string]$InputDir,

    [Parameter(Position=1)]
    [string]$Extension,

    [Parameter(Position=2)]
    [string]$OutputName,

    [Parameter(Position=3)]
    [string]$OutputDir,

    [Parameter()]
    [int]$Depth = -1,

    [Parameter()]
    [switch]$NoHeader,

    [Parameter()]
    [string[]]$Exclude = @(),

    [Parameter()]
    [string[]]$ListOnly = @(),

    [Parameter()]
    [switch]$Help
)

# ── ANSI colors ───────────────────────────────────────────────────────────────
$ESC    = [char]27
$RESET  = "$ESC[0m"
$BOLD   = "$ESC[1m"
$DIM    = "$ESC[2m"
$CYAN   = "$ESC[36m"
$GREEN  = "$ESC[32m"
$RED    = "$ESC[31m"
$WHITE  = "$ESC[97m"
$GRAY   = "$ESC[90m"
$YELLOW = "$ESC[33m"

# ── UI helpers ────────────────────────────────────────────────────────────────
function Write-Banner {
    Write-Host ""
    Write-Host "  $BOLD$WHITE code2md$RESET  $DIM$GRAY--  codebase to markdown exporter$RESET"
    Write-Host "  $GRAY$([string][char]0x2500 * 38)$RESET"
    Write-Host ""
}

function Write-Row {
    param([string]$Label, [string]$Value, [string]$Color = $CYAN)
    $l = $Label.PadRight(12)
    Write-Host "    $GRAY$l$RESET  $Color$Value$RESET"
}

function Write-Step {
    param([string]$Icon, [string]$Msg)
    Write-Host "  $CYAN$Icon$RESET  $Msg"
}

function Write-FileRow {
    param([string]$Path, [string]$Size)
    $p = $Path.PadRight(55)
    Write-Host "    $GRAY+$RESET $WHITE$p$RESET $GRAY$Size$RESET"
}

function Write-ListOnlyRow {
    param([string]$Path)
    $p = $Path.PadRight(55)
    Write-Host "    $YELLOW*$RESET $YELLOW$p$RESET $GRAY(list-only)$RESET"
}

function Write-Success {
    param([string]$Msg)
    Write-Host ""
    Write-Host "  $GREEN$([char]0x25CF)$RESET $BOLD$Msg$RESET"
    Write-Host ""
}

function Write-Fail {
    param([string]$Msg)
    Write-Host ""
    Write-Host "  $RED$([char]0x25CF)$RESET $BOLD$RED$Msg$RESET"
    Write-Host ""
}

function Write-ProgressBar {
    param([int]$Current, [int]$Total, [string]$CurrentFile = "")

    $width   = 36
    $pct     = [math]::Round(($Current / $Total) * 100)
    $filled  = [math]::Round(($Current / $Total) * $width)
    $empty   = $width - $filled
    $bar     = "$GREEN$([string][char]0x2588 * $filled)$GRAY$([string][char]0x2591 * $empty)$RESET"
    $counter = "$GRAY[$Current/$Total]$RESET"
    $percent = "$WHITE$($pct.ToString().PadLeft(3))%$RESET"
    $maxName = 30
    $name    = if ($CurrentFile.Length -gt $maxName) { "..." + $CurrentFile.Substring($CurrentFile.Length - $maxName) } else { $CurrentFile }
    $namePad = $name.PadRight($maxName + 3)

    if ($Current -gt 1) { Write-Host -NoNewline "$ESC[2A" }

    Write-Host "  $bar $percent $counter"
    Write-Host "  $GRAY>$RESET $CYAN$namePad$RESET    "
}

# ── HELP ─────────────────────────────────────────────────────────────────────
function Write-Help {
    Write-Banner
    Write-Host "  ${BOLD}${WHITE}USAGE$RESET"
    Write-Host ""
    Write-Host "    $CYAN code2md$RESET $WHITE<InputDir> <Extension>$RESET $GRAY[OutputName] [OutputDir] [options]$RESET"
    Write-Host ""
    Write-Host "  ${BOLD}${WHITE}ARGUMENTS$RESET"
    Write-Host ""
    Write-Host "    $WHITE InputDir   $RESET  $GRAY(required)$RESET  Root folder to scan"
    Write-Host "    $WHITE Extension  $RESET  $GRAY(required)$RESET  File extension without dot  $GRAY# ts, js, py ...$RESET"
    Write-Host "    $WHITE OutputName $RESET  $GRAY(optional)$RESET  Output filename             $GRAY# default: <InputDir>.md$RESET"
    Write-Host "    $WHITE OutputDir  $RESET  $GRAY(optional)$RESET  Output folder               $GRAY# default: same as InputDir$RESET"
    Write-Host ""
    Write-Host "  ${BOLD}${WHITE}OPTIONS$RESET"
    Write-Host ""
    Write-Host "    $CYAN -Depth$RESET $WHITE<int>$RESET"
    Write-Host "        How many folder levels deep to scan."
    Write-Host "        $GRAY -1$RESET  unlimited $GRAY(default)$RESET"
    Write-Host "        $GRAY  0$RESET  root folder only"
    Write-Host "        $GRAY  N$RESET  N levels deep"
    Write-Host ""
    Write-Host "    $CYAN -Exclude$RESET $WHITE<string[]>$RESET"
    Write-Host "        Skip files or folders matching these patterns."
    Write-Host "        $GRAY example :$RESET  $WHITE-Exclude @(`"*.spec.ts`", `"__tests__`")$RESET"
    Write-Host ""
    Write-Host "    $CYAN -ListOnly$RESET $WHITE<string[]>$RESET"
    Write-Host "        For these folder names, only list their direct subfolders"
    Write-Host "        in the markdown -- no file content is exported."
    Write-Host "        Useful for $YELLOW node_modules$RESET, $YELLOW vendor$RESET, $YELLOW dist$RESET, etc."
    Write-Host "        $GRAY example :$RESET  $WHITE-ListOnly @(`"node_modules`", `"vendor`")$RESET"
    Write-Host ""
    Write-Host "    $CYAN -NoHeader$RESET"
    Write-Host "        Skip the $GRAY## filename$RESET header above each code block."
    Write-Host ""
    Write-Host "    $CYAN -Help$RESET"
    Write-Host "        Show this help."
    Write-Host ""
    Write-Host "  ${BOLD}${WHITE}EXAMPLES$RESET"
    Write-Host ""
    Write-Host "    $GRAY # Basic export$RESET"
    Write-Host "    $WHITE code2md .\src\ ts$RESET"
    Write-Host ""
    Write-Host "    $GRAY # Export with output path$RESET"
    Write-Host "    $WHITE code2md .\src\ ts bundle.md .\exports\$RESET"
    Write-Host ""
    Write-Host "    $GRAY # Limit depth, exclude test files$RESET"
    Write-Host "    $WHITE code2md .\src\ ts -Depth 2 -Exclude @(`"*.spec.ts`")$RESET"
    Write-Host ""
    Write-Host "    $GRAY # List node_modules without their code$RESET"
    Write-Host "    $WHITE code2md .\ ts -ListOnly @(`"node_modules`")$RESET"
    Write-Host ""
    Write-Host "    $GRAY # Combine everything$RESET"
    Write-Host "    $WHITE code2md .\jobkan-web\ ts out.md .\docs\ ``$RESET"
    Write-Host "        $WHITE -Depth 4 -Exclude @(`"*.spec.ts`") -ListOnly @(`"node_modules`")$RESET"
    Write-Host ""
    Write-Host "  $GRAY$([string][char]0x2500 * 38)$RESET"
    Write-Host ""
}

# ── Show help if requested or no args ────────────────────────────────────────
if ($Help -or (-not $InputDir) -or (-not $Extension)) {
    Write-Help
    exit 0
}

# ── Banner ────────────────────────────────────────────────────────────────────
Write-Banner

# ── Path resolution ───────────────────────────────────────────────────────────
$InputDir = (Resolve-Path $InputDir).Path.TrimEnd('\').TrimEnd('/')

if (-not $OutputName) { $OutputName = (Split-Path $InputDir -Leaf) + ".md" }

if (-not $OutputDir) {
    $OutputDir = $InputDir
} else {
    if (!(Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
}

$OutputFile    = Join-Path $OutputDir $OutputName
$depthLabel    = if ($Depth -ge 0) { "$Depth level(s)" } else { "unlimited" }
$excludeLabel  = if ($Exclude.Count  -gt 0) { $Exclude  -join ", " } else { "none" }
$listOnlyLabel = if ($ListOnly.Count -gt 0) { $ListOnly -join ", " } else { "none" }

Write-Row "source"    $InputDir
Write-Row "output"    $OutputFile
Write-Row "extension" ".$Extension"
Write-Row "depth"     $depthLabel
Write-Row "exclude"   $excludeLabel
Write-Row "list-only" $listOnlyLabel $YELLOW
Write-Host ""

# ── Helper: is this path inside a list-only folder? ──────────────────────────
function Get-ListOnlyAncestor {
    param([string]$FullPath, [string]$Base, [string[]]$Patterns)
    if ($Patterns.Count -eq 0) { return $null }
    $relative = $FullPath.Substring($Base.Length).TrimStart('\').TrimStart('/')
    $parts    = $relative -split '[/\\]'
    # Check every segment except the last one (which is the file itself)
    for ($i = 0; $i -lt $parts.Count - 1; $i++) {
        foreach ($pattern in $Patterns) {
            if ($parts[$i] -like $pattern) { return $parts[$i] }
        }
    }
    return $null
}

# ── File collection ───────────────────────────────────────────────────────────
Write-Step "~" "Scanning files..."
Write-Host ""

$files = Get-ChildItem -Path $InputDir -Filter "*.$Extension" -Recurse -File |
    Sort-Object FullName |
    Where-Object {
        $file = $_

        # Depth filter
        $depthOk = $true
        if ($Depth -ge 0) {
            $rel    = $file.FullName.Substring($InputDir.Length).TrimStart('\').TrimStart('/')
            $levels = ($rel -split '[/\\]').Count - 1
            $depthOk = $levels -le $Depth
        }

        # Exclude filter
        $excluded = $false
        foreach ($pattern in $Exclude) {
            if ($file.FullName -like "*$pattern*") { $excluded = $true; break }
        }

        # Skip files inside list-only folders
        $inListOnly = $null -ne (Get-ListOnlyAncestor $file.FullName $InputDir $ListOnly)

        $depthOk -and -not $excluded -and -not $inListOnly
    }

# Collect list-only folder entries
$listOnlyEntries = [ordered]@{}
if ($ListOnly.Count -gt 0) {
    $matchedRoots = Get-ChildItem -Path $InputDir -Directory -Recurse |
        Where-Object {
            $dir = $_
            $matched = $false
            foreach ($pattern in $ListOnly) {
                if ($dir.Name -like $pattern) { $matched = $true; break }
            }
            $matched
        } |
        Sort-Object FullName

    foreach ($root in $matchedRoots) {
        $relRoot  = $root.FullName.Substring($InputDir.Length).TrimStart('\').TrimStart('/')
        $children = Get-ChildItem -Path $root.FullName -Directory | Sort-Object Name | Select-Object -ExpandProperty Name
        $listOnlyEntries[$relRoot] = $children
        Write-ListOnlyRow $relRoot
    }
}

foreach ($file in $files) {
    $relative = $file.FullName.Substring($InputDir.Length).TrimStart('\').TrimStart('/')
    $kb       = [math]::Round($file.Length / 1KB, 1)
    Write-FileRow $relative "${kb}kb"
}

if ($files.Count -eq 0 -and $listOnlyEntries.Count -eq 0) {
    Write-Fail "No .$Extension files found and no list-only folders matched."
    exit 0
}

Write-Host ""
Write-Step ">" "Building markdown..."
Write-Host ""

# ── Markdown generation ───────────────────────────────────────────────────────
$fence = '```'

$lines = @()
$lines += "<!-- Generated by code2md.ps1 on $(Get-Date -Format 'yyyy-MM-dd HH:mm') -->"
$lines += "<!-- Source: $InputDir -->"
$lines += ""
$lines += "## Table of contents"
$lines += ""
foreach ($key in $listOnlyEntries.Keys) {
    $anchor = $key.ToLower() -replace '[\\/ .\[\]]', '-' -replace '[^a-z0-9\-]', ''
    $lines += "- [$key (directory listing)](#$anchor)"
}
foreach ($file in $files) {
    $relative = $file.FullName.Substring($InputDir.Length).TrimStart('\').TrimStart('/')
    $anchor   = $relative.ToLower() -replace '[\\/ .\[\]]', '-' -replace '[^a-z0-9\-]', ''
    $lines   += "- [$relative](#$anchor)"
}
$lines += ""
$lines += "---"
$lines += ""
$lines | Set-Content $OutputFile -Encoding UTF8

# Write list-only sections
foreach ($key in $listOnlyEntries.Keys) {
    $anchor   = $key.ToLower() -replace '[\\/ .\[\]]', '-' -replace '[^a-z0-9\-]', ''
    $children = $listOnlyEntries[$key]
    $block    = @()
    $block   += "## $key  [directory listing] {#$anchor}"
    $block   += ""
    $block   += "> This folder was set to **list-only** mode. No source code is exported."
    $block   += ""
    if ($children.Count -gt 0) {
        $block += "| Package / Subfolder |"
        $block += "|---|"
        foreach ($child in $children) { $block += "| $child |" }
    } else {
        $block += "_No subfolders found._"
    }
    $block += ""
    $block += "---"
    $block += ""
    $block | Add-Content $OutputFile -Encoding UTF8
}

# Write file sections with progress bar
$total = $files.Count
$i     = 0

foreach ($file in $files) {
    $i++
    $relative = $file.FullName.Substring($InputDir.Length).TrimStart('\').TrimStart('/')
    $anchor   = $relative.ToLower() -replace '[\\/ .\[\]]', '-' -replace '[^a-z0-9\-]', ''

    Write-ProgressBar -Current $i -Total $total -CurrentFile $relative

    $block = @()
    if (-not $NoHeader) {
        $block += "## $relative {#$anchor}"
        $block += ""
    }
    $block += "$fence$Extension"

    # FIX: -Raw and -Encoding cannot be combined on PS5 — read lines then join
    $content = (Get-Content $file.FullName -Encoding UTF8) -join "`n"
    $block  += $content.TrimEnd()
    $block  += $fence
    $block  += ""
    $block  += "---"
    $block  += ""

    $block | Add-Content $OutputFile -Encoding UTF8
}

# Final bar
if ($total -gt 0) {
    Write-Host -NoNewline "$ESC[2A"
    $bar = "$GREEN$([string][char]0x2588 * 36)$RESET"
    Write-Host "  $bar $WHITE100%$RESET $GRAY[$total/$total]$RESET"
    Write-Host "  $GREEN$([char]0x2714)$RESET $CYAN$("complete".PadRight(33))$RESET    "
}

# ── Summary ───────────────────────────────────────────────────────────────────
$totalKb    = [math]::Round((Get-Item $OutputFile).Length / 1KB, 1)
$totalLines = (Get-Content $OutputFile).Count

Write-Host ""
Write-Host "  $GRAY$([string][char]0x2500 * 38)$RESET"
Write-Row "files"   "$($files.Count) exported"         $GREEN
Write-Row "listed"  "$($listOnlyEntries.Count) dir(s)" $YELLOW
Write-Row "size"    "${totalKb} KB"                    $GREEN
Write-Row "lines"   "$totalLines lines"                $GREEN
Write-Row "output"  $OutputFile                        $CYAN
Write-Success "Done"