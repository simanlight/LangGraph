$fileName = "contribution.txt"
$dateFile = "date.txt" # Define the date file name

# Resolve full paths against the current PowerShell location
# (.NET file APIs use the process working directory, which can differ)
$filePath = Join-Path (Get-Location) $fileName
$datePath = Join-Path (Get-Location) $dateFile

if (-not (Test-Path $datePath)) {
    Write-Host "Date file not found: $datePath"
    exit 1
}

# UTF-8 without BOM so git and other tools read the files cleanly
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Read all dates (split on any whitespace, same as the bash for loop)
$dateData = ([System.IO.File]::ReadAllText($datePath) -split '\s+') | Where-Object { $_ -ne "" }

foreach ($date in $dateData) {
    $commitDate = "${date}T12:00:00"

    Write-Host "Processing commit for date: $commitDate"

    # Append content to the contribution file
    [System.IO.File]::AppendAllText($filePath, "Commit on $commitDate`n", $utf8NoBom)

    # Add the file to the staging area
    git add $fileName

    # Commit with the specific message and date
    git commit -m "Commit on $commitDate" --date="$commitDate"

    # Push the changes
    git push

    # Check if the push was successful before removing the date
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully committed and pushed for $commitDate. Removing date from $dateFile."

        # Remove the processed date from date.txt (exact line match, like the sed command)
        $remaining = [System.IO.File]::ReadAllLines($datePath) | Where-Object { $_.Trim() -ne $date }
        if ($null -eq $remaining) { $remaining = @() }
        [System.IO.File]::WriteAllLines($datePath, [string[]]$remaining, $utf8NoBom)
    }
    else {
        Write-Host "Push failed for $commitDate. Date will remain in $dateFile."
        # Stop here to allow manual intervention
        exit 1
    }
}

Write-Host "Script finished."
