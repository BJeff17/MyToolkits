# Generate-Tree PowerShell Script

A PowerShell script that generates an elegant ASCII tree representation of a project directory with optional file size and line count information.

## Features

- **ASCII Tree Format**: Clean, readable tree structure similar to the Unix `tree` command
- **File Information**: Optional display of file sizes and line counts
- **Customizable Exclusions**: Exclude specific files/folders using wildcard patterns
- **Depth Control**: Limit how deep the tree traversal goes
- **Default Exclusions**: Automatically skips common development directories (.git, node_modules, etc.)
- **Windows Compatible**: Works natively in PowerShell on Windows

## Usage

```powershell
# Basic usage (current directory)
.\Generate-Tree.ps1

# Specify a directory
.\Generate-Tree.ps1 -Path "C:\MyProject"

# Show file sizes
.\Generate-Tree.ps1 -IncludeSize

# Show file sizes and line counts
.\Generate-Tree.ps1 -IncludeSize -IncludeLineCount

# Custom exclusions
.\Generate-Tree.ps1 -Exclude @("*.log", "temp*", "node_modules", "dist")

# Limit tree depth to 2 levels
.\Generate-Tree.ps1 -Depth 2

# Combine options
.\Generate-Tree.ps1 -Path "./src" -IncludeSize -Exclude @("*.tmp", "bin") -Depth 3
```

## Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `Path` | String | Directory path to analyze | Current directory (`.`) |
| `Exclude` | String[] | Array of wildcard patterns to exclude | `.git`, `node_modules`, `__pycache__`, `*.pyc`, `*.pyo`, `*.pyd`, `.DS_Store`, `Thumbs.db` |
| `IncludeSize` | Switch | Display file sizes | `$false` |
| `IncludeLineCount` | Switch | Display line counts for text files | `$false` |
| `Depth` | Int | Maximum recursion depth (0 = unlimited) | `0` |

## Output Examples

### Basic Tree
```
C:\MyProject
README.md
src
|- main.cs
|- utils.cs
└- config.json
```

### With File Sizes
```
C:\MyProject
README.md [2 KB]
src
|- main.cs [15 KB]
|- utils.cs [8 KB]
└- config.json [1.2 KB]
```

### With Sizes and Line Counts
```
C:\MyProject
README.md [2 KB] [25 lines]
src
|- main.cs [15 KB] [120 lines]
|- utils.cs [8 KB] [45 lines]
└- config.json [1.2 KB] [18 lines]
```

## Default Exclusions

The script automatically excludes these common directories and files:
- Version control: `.git`, `.svn`, `.hg`
- Dependencies: `node_modules`, `bower_components`, `vendor`
- Python cache: `__pycache__`, `*.pyc`, `*.pyo`, `*.pyd`
- OS files: `.DS_Store`, `Thumbs.db`
- Build outputs: Can be added via `-Exclude` parameter

## Requirements

- PowerShell 5.1+ (built into Windows 10+)
- No external dependencies

## Installation

1. Save the script as `Generate-Tree.ps1` in your desired location
2. (Optional) Add the script directory to your PATH for easy access
3. Run using PowerShell:
   ```powershell
   powershell -ExecutionPolicy Bypass -Path\Generate-Tree.ps1
   ```

## Notes

- The script uses simple ASCII characters (`|-`, `+-`) to avoid encoding issues
- File sizes are displayed in human-readable format (B, KB, MB, GB, TB)
- Line counts only work for text files that can be read with UTF-8 or default encoding
- Large directories may take some time to process depending on depth and file count

## License

MIT License - Feel free to use, modify, and distribute as needed.

