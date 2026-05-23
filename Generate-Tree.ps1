<#
.SYNOPSIS
    Generates a project tree in ASCII format with detailed information

.DESCRIPTION
    This script recursively walks through a directory and generates a tree representation
    in ASCII format similar to the 'tree' command, with options to display file sizes,
    line counts, and customize exclusions.

.PARAMETER Path
    Path of the directory to analyze (default: current directory)

.PARAMETER Exclude
    Array of patterns to exclude (supporting wildcards)

.PARAMETER IncludeSize
    Display file sizes

.PARAMETER IncludeLineCount
    Display line counts of text files

.PARAMETER Depth
    Maximum analysis depth (0 = unlimited)

.EXAMPLE
    .\Generate-Tree.ps1 -Path .\myproject -IncludeSize -Exclude @("*.log", "temp*", "node_modules")

.NOTES
    Author: Generated for the user
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Path = ".",
    
    [Parameter(Mandatory=$false)]
    [string[]]$Exclude = @(),
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeSize,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeLineCount,
    
    [Parameter(Mandatory=$false)]
    [int]$Depth = 0
)

# Add default exclusions if none specified
if (-not $Exclude) {
    $Exclude = @(".git", "node_modules", "__pycache__", "*.pyc", "*.pyo", "*.pyd", ".DS_Store", "Thumbs.db")
}

# Function to check if a file/folder should be excluded
function Should-Exclude {
    param([string]$ItemName, [string]$ItemPath)
    
    foreach ($pattern in $Exclude) {
        if ($ItemName -like $pattern) {
            return $true
        }
        # Also check the full path for some patterns
        if ($ItemPath -like $pattern) {
            return $true
        }
    }
    return $false
}

# Function to format file size
function Format-Size {
    param([long]$Bytes)
    
    if ($Bytes -eq 0) { return "0 B" }
    
    $Sizes = @("B", "KB", "MB", "GB", "TB")
    $i = [Math]::Floor([Math]::Log($Bytes, 1024))
    $i = [Math]::Min($i, $Sizes.Length - 1)
    
    $size = [Math]::Round($Bytes / [Math]::Pow(1024, $i), 2)
    return "$size $($Sizes[$i])"
}

# Function to count lines in a text file
function Get-LineCount {
    param([string]$FilePath)
    
    try {
        # Try to read as UTF-8 text
        $content = Get-Content -Path $FilePath -Encoding UTF8 -ErrorAction Stop
        return $content.Length
    } catch {
        try {
            # Try with default encoding
            $content = Get-Content -Path $FilePath -ErrorAction Stop
            return $content.Length
        } catch {
            # If we can't read as text, return 0
            return 0
        }
    }
}

# Recursive function to generate the tree
function Get-Tree {
    param(
        [string]$CurrentPath,
        [string]$Prefix = "",
        [bool]$IsLast = $true,
        [int]$CurrentDepth = 0
    )
    
    # Check maximum depth
    if ($Depth -gt 0 -and $CurrentDepth -ge $Depth) {
        return
    }
    
    try {
        # Get list of items
        $items = Get-ChildItem -Path $CurrentPath -ErrorAction Stop | 
                 Where-Object { -not (Should-Exclude -ItemName $_.Name -ItemPath $_.FullName) } |
                 Sort-Object {
                     # Sort directories first, then files
                     if ($_.PSIsContainer) { 0 } else { 1 }
                 } |
                 Sort-Object Name
        
        # Display root path only at first level
        if ($CurrentDepth -eq 0) {
            Write-Host $CurrentPath
        }
        
        for ($i = 0; $i -lt $items.Length; $i++) {
            $item = $items[$i]
            
            # Skip if item is null or invalid
            if (-not $item) {
                continue
            }
            
            $isLastItem = ($i -eq $items.Length - 1)
            
            # Determine tree characters (simple ASCII to avoid encoding issues)
            if ($CurrentDepth -eq 0) {
                $treeChar = ""
                $newPrefix = ""
            } else {
                if ($isLastItem) {
                    $treeChar = "+- "
                    $newPrefix = $Prefix + "    "
                } else {
                    $treeChar = "|- "
                    $newPrefix = $Prefix + "|   "
                }
            }
            
            # Build display name for the item
            $displayName = $item.Name
            
            if (-not $item.PSIsContainer) { # It's a file
                $sizeInfo = ""
                $lineInfo = ""
                
                if ($IncludeSize) {
                    $size = $item.Length
                    $sizeInfo = " [$(Format-Size -Bytes $size)]"
                }
                
                if ($IncludeLineCount) {
                    $lineCount = Get-LineCount -FilePath $item.FullName
                    $lineInfo = " [$lineCount lines]"
                }
                
                $displayName += $sizeInfo + $lineInfo
            }
            
            # Display current item
            Write-Host ("{0}{1}{2}" -f $Prefix, $treeChar, $displayName)
            
            # Recursively process subdirectories
            if ($item.PSIsContainer) {
                Get-Tree -CurrentPath $item.FullName -Prefix $newPrefix -IsLast $isLastItem -CurrentDepth ($CurrentDepth + 1)
            }
        }
    } catch {
        Write-Warning "Error accessing $CurrentPath : $_"
    }
}

# Main entry point
try {
    # Resolve the path
    $resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
    
    # Generate the tree
    Get-Tree -CurrentPath $resolvedPath.ProviderPath
} catch {
    Write-Error "Unable to access specified path: $Path"
    exit 1
}