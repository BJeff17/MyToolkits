<#
.SYNOPSIS
    Génère une arborescence du projet au format ASCII avec des informations détaillées

.DESCRIPTION
    Ce script parcourt récursivement un répertoire et génère une représentation 
    arborescente au format ASCII similaire à la commande 'tree', avec des options
    pour afficher la taille des fichiers, le nombre de lignes, et personnaliser les exclusions.

.PARAMETER Path
    Chemin du répertoire à analyser (par défaut : répertoire courant)

.PARAMETER Exclude
    Tableau de patterns à exclure (supportant les wildcards)

.PARAMETER IncludeSize
    Afficher la taille des fichiers

.PARAMETER IncludeLineCount
    Afficher le nombre de lignes des fichiers texte

.PARAMETER Depth
    Profondeur maximale d'analyse (0 = illimitée)

.EXAMPLE
    .\Generate-Tree.ps1 -Path .\monprojet -IncludeSize -Exclude @("*.log", "temp*", "node_modules")

.NOTES
    Auteur: Généré pour l'utilisateur
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

# Ajouter les exclusions par défaut si aucune n'est spécifiée
if (-not $Exclude) {
    $Exclude = @(".git", "node_modules", "__pycache__", "*.pyc", "*.pyo", "*.pyd", ".DS_Store", "Thumbs.db")
}

# Fonction pour vérifier si un fichier/dossier doit être exclu
function Should-Exclude {
    param([string]$ItemName, [string]$ItemPath)
    
    foreach ($pattern in $Exclude) {
        if ($ItemName -like $pattern) {
            return $true
        }
        # Vérifier aussi le chemin complet pour certains patterns
        if ($ItemPath -like $pattern) {
            return $true
        }
    }
    return $false
}

# Fonction pour formater la taille des fichiers
function Format-Size {
    param([long]$Bytes)
    
    if ($Bytes -eq 0) { return "0 B" }
    
    $Sizes = @("B", "KB", "MB", "GB", "TB")
    $i = [Math]::Floor([Math]::Log($Bytes, 1024))
    $i = [Math]::Min($i, $Sizes.Length - 1)
    
    $size = [Math]::Round($Bytes / [Math]::Pow(1024, $i), 2)
    return "$size $($Sizes[$i])"
}

# Fonction pour compter les lignes d'un fichier texte
function Get-LineCount {
    param([string]$FilePath)
    
    try {
        # Essayer de lire comme texte UTF-8
        $content = Get-Content -Path $FilePath -Encoding UTF8 -ErrorAction Stop
        return $content.Length
    } catch {
        try {
            # Essayer avec l'encodage par défaut
            $content = Get-Content -Path $FilePath -ErrorAction Stop
            return $content.Length
        } catch {
            # Si on ne peut pas lire comme texte, retourner 0
            return 0
        }
    }
}

# Fonction récursive pour générer l'arborescence
function Get-Tree {
    param(
        [string]$CurrentPath,
        [string]$Prefix = "",
        [bool]$IsLast = $true,
        [int]$CurrentDepth = 0
    )
    
    # Vérifier la profondeur maximale
    if ($Depth -gt 0 -and $CurrentDepth -ge $Depth) {
        return
    }
    
    try {
        # Obtenir la liste des éléments
        $items = Get-ChildItem -Path $CurrentPath -ErrorAction Stop | 
                 Where-Object { -not (Should-Exclude -ItemName $_.Name -ItemPath $_.FullName) } |
                 Sort-Object {
                     # Trier les dossiers en premier, puis les fichiers
                     if ($_.PSIsContainer) { 0 } else { 1 }
                 } |
                 Sort-Object Name
        
        # Afficher le chemin racine uniquement au premier niveau
        if ($CurrentDepth -eq 0) {
            Write-Host $CurrentPath
        }
        
        for ($i = 0; $i -lt $items.Length; $i++) {
            $item = $items[$i]
            $isLastItem = ($i -eq $items.Length - 1)
            
            # Déterminer les caractères de l'arbre (version ASCII simple pour éviter les problèmes d'encodage)
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
            
            # Construire l'affichage de l'élément
            $displayName = $item.Name
            
            if (-not $item.PSIsContainer) { # C'est un fichier
                $sizeInfo = ""
                $lineInfo = ""
                
                if ($IncludeSize) {
                    $size = $item.Length
                    $sizeInfo = " [$(Format-Size -Bytes $size)]"
                }
                
                if ($IncludeLineCount) {
                    $lineCount = Get-LineCount -FilePath $item.FullName
                    $lineInfo = " [$lineCount lignes]"
                }
                
                $displayName += $sizeInfo + $lineInfo
            }
            
            # Afficher l'élément actuel
            Write-Host ("{0}{1}{2}" -f $Prefix, $treeChar, $displayName)
            
            # Récursivement traiter les sous-dossiers
            if ($item.PSIsContainer) {
                Get-Tree -CurrentPath $item.FullName -Prefix $newPrefix -IsLast $isLastItem -CurrentDepth ($CurrentDepth + 1)
            }
        }
    } catch {
        Write-Warning "Erreur lors de l'accès à $CurrentPath : $_"
    }
}

# Point d'entrée principal
try {
    # Résoudre le chemin
    $resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
    
    # Générer l'arborescence
    Get-Tree -CurrentPath $resolvedPath.ProviderPath
} catch {
    Write-Error "Impossible d'accéder au chemin spécifié : $Path"
    exit 1
}