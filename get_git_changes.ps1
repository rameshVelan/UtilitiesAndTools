#Modify the following details
$PROJECT_KEY = "" # Example 'DATA' (Usually JIRA ID is used for best practice)
$REPO_DIR = "" # Folder where code is present
$REPO_URL = "https://git/projects/$PROJECT_KEY/repos/$REPO_DIR"  # Sample; it differs for every project
$BRANCH_NAME = "" # Example: 'dev' or 'main'

# Get the path of the script's directory
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Construct the output file path with a timestamp
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFileName = "output_$Timestamp.txt"
$OutputFilePath = Join-Path -Path $ScriptDirectory -ChildPath $OutputFileName

# Store the original path
$OriginalPath = Get-Location


# Clone or update the repository
if (Test-Path -Path $REPO_DIR) {
  Set-Location -Path $REPO_DIR
  git pull origin $BRANCH_NAME
}
else {
  git clone $REPO_URL -b $BRANCH_NAME $REPO_DIR
  Set-Location -Path $REPO_DIR
}

#Provide the following inputs
Write-Output "This program is to get the list of PRs & modified files from the Repository:$REPO_DIR"
Write-Output "Serch can be performed based on JIRA ID or Start & End Dates or both" 

$JIRA_ID = ""
$START_DATE = ""
$END_DATE = ""

# Prompt for Jira ID until a valid one is provided or the user chooses to skip
while (-not ($JIRA_ID -eq "skip" -or $JIRA_ID.StartsWith("$PROJECT_KEY-"))) {
    $JIRA_ID = Read-Host "Enter Jira ID (optional, enter 'skip' to continue without Jira ID)"

# Note: Below condition may required changes. I coded with an assumption that branch name should starts with 'DATA' for checkout / checkin/ Pull requests.
# Modify if required.
   if (-not ($JIRA_ID -eq "skip" -or $JIRA_ID.StartsWith("$PROJECT_KEY-"))) {
      Write-Output "Invalid Jira ID. Jira ID should start with 'DATA'."
   }
}
#if ($JIRA_ID -nq "skip") {
    $START_DATE = Read-Host "Enter start date 'yyyy-mm-dd'(optional)"
    $END_DATE = Read-Host "Enter end date 'yyyy-mm-dd' (optional)"
#	Write-Output "$START_DATE"
#}
Write-Output "$START_DATE"

 
# Configure git to use the credential manager
git config --global credential.helper manager-core

# Get the commit hashes for the given Jira ID or date range
if ($JIRA_ID -and $JIRA_ID -ne "skip" -and $START_DATE -and $END_DATE) {
	Write-Output "Search based on JIRA-ID:$JIRA_ID and date range - from $START_DATE to $END_DATE"
    $COMMIT_HASHES = git log --merges --grep="$JIRA_ID[^0-9]" --after=$START_DATE --before=$END_DATE --pretty=format:%H
}
elseif ($JIRA_ID -and $JIRA_ID -ne "skip") {
	Write-Output "Search based on JIRA-ID:$JIRA_ID"
    $COMMIT_HASHES = git log --merges --grep="$JIRA_ID[^0-9]" --pretty=format:%H
}
elseif ($JIRA_ID -eq "skip" -and $START_DATE -and $END_DATE) {
    $COMMIT_HASHES = git log --merges --after=$START_DATE --before=$END_DATE --pretty=format:%H
	Write-Output "Search based on date range | $START_DATE to $END_DATE"
}
else {
	Write-Output "No JIRA ID / Start & End Dates Provided | Hence pulling all the changes"
    $COMMIT_HASHES = git log --merges --pretty=format:%H
}

# Output the list of pull requests with clickable links
$hasPullRequests = $false
$modifiedFiles = @()

# Initialize an empty array to store pull request titles
$pullRequestTitles = @()
$pullRequestLinks = @()
if ($COMMIT_HASHES) {
	
    foreach ($commitHash in $COMMIT_HASHES) {
        $pullRequestTitle = git show -s --format=%s $commitHash

        # Extract the pull request ID from the title 
	# Note:$PROJECT_KEY/$REPO_DIR - This may need some change as per project
        $pullRequestID = $pullRequestTitle -replace ".*pull request #(\d+).*", '$1'
	$branchDetails = $pullRequestTitle -replace ".*Merge pull request #[0-9]+ in $PROJECT_KEY/$REPO_DIR from (.*?) to .*", '$1'

        if ($pullRequestID) {
			$pullRequestTitles += $pullRequestTitle
            $pullRequestLink = "$REPO_URL/pull-requests/$pullRequestID/overview"
			$pullRequestLinks += $pullRequestLink
            #Write-Output "PR Details:$pullRequestTitle"
			Write-Output "Merge from - $branchDetails"
			Write-Output "PR ID:$pullRequestID"
			Write-Output "PR Link:$pullRequestLink"
            $hasPullRequests = $true

            # Get the modified files for the pull request
            $MODIFIED_FILES = git diff --name-only $commitHash^ $commitHash
            if ($MODIFIED_FILES) {
                Write-Output "Modified files:"
                foreach ($file in $MODIFIED_FILES) {
					Write-Output $file
                    if ($file -notin $modifiedFiles) {
                        
                        $modifiedFiles += $file
                    }
                }
            } else {
                Write-Output "No modified files found for this pull request."
            }

            Write-Output ""
        }
    }
	Write-Output "Consolidated list of changes:"
	foreach ($file in $modifiedFiles) {
		 $outputContent += "$file`n"
		Write-Output $file
	}
}

if (-not $hasPullRequests) {
    Write-Output "No pull requests found."
}

# Write the output to the file
$OutputContent = @"
Pull requests:
$(
    if ($pullRequestTitles) {
		$($pullRequestTitles -join "`n") 
		$("`n")
		$("`n")
		$($pullRequestLinks -join "`n")
    }
    else {
        "No pull requests found."
    }
)

Modified files:
$($modifiedFiles -join "`n")
"@

# Append the output to the file
$OutputContent | Out-File -FilePath $OutputFilePath -Append

# Display the path of the output file
Write-Output "Output written to: $OutputFilePath"

# Change directory back to the original path
Set-Location -Path $OriginalPath
