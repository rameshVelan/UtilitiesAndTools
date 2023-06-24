Contains the utilities created using various scripts
1. JSONFlattening
Nested Data (JSON) Flattening using Spark
Implementation steps:
Read JSON file using spark dataframe.
Iterate each nodes / fields and find datatype (Array / Struct) and flatten the records.

2. get_git_changes.ps1
power shell & git need to be installed windows system.
Provide the following as per your need $PROJECT_KEY - Used for creating branch name from main branch for checkout & check-in
 $REPO_DIR - Folder that have the code or config files $REPO_URL - Repository URL $BRANCH_NAME - branch name Create a folder in system. Please the file 'github_get_changes.ps1' and run using power shell.
  Open Power shell & change directory where utility is present
Run using .\github_get_changes.ps1 & output will be shown & output file will be created in same path
For more info, Demo: Watch Youtube Channel -
