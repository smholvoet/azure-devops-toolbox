# Sample PowerShell script demoing Azure DevOps CLI capabilities
# JMESpath expressions: https://jmespath.org/

# Configure defaults
# 📖 https://learn.microsoft.com/en-us/cli/azure/devops?view=azure-cli-latest#az-devops-configure
$env:AZURE_DEVOPS_ORG = "https://dev.azure.com/fabrikamfiber"
az devops configure --defaults organization=$env:AZURE_DEVOPS_ORG
az devops configure --list

# Sample user
$TargetUserEmail = "john.doe@pfabrikamfiber.com"

# One-liner to get last accessed date of a specific user in local timezone format
# 📖 https://learn.microsoft.com/en-us/dotnet/api/system.timezoneinfo#methods
[System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime](az devops user show --user $TargetUserEmail --query "{lastAccessedDate:lastAccessedDate}" --output tsv), [System.TimeZoneInfo]::Local.Id)

# Show user details in colorized YAML
az devops user show --user $TargetUserEmail --output yamlc

# Export all users to JSON
az devops user list --top 1000 --output json >> az-devops-users.json

# Select specific properties
az devops user list --query "totalCount"
az devops user list --top 1000 --query "items | length(@)"
az devops user list --top 1000 --query "members | length(@)"
az devops user list --query "items[*]" | Format-Table
az devops user list --query "items[1]"
az devops user list --query "items[5:10]"
az devops user list --query "items[:5]"
az devops user list --query "items[*].*"
az devops user list --query "items[*].user.displayName"
az devops user list --query "items[*].[id,lastAccessedDate]"

# Filter by license
az devops user list --top 1000 --query "items[?accessLevel.licenseDisplayName=='Visual Studio Enterprise subscription'].user.displayName"

# Filter by email
az devops user list --top 1000 --query "items[?contains(user.mailAddress, $TargetUserEmail) == ``true``]"

# Sort by property (e.g. last accessed date)
az devops user list --top 1000 --query "reverse(sort_by(items[].{email:user.mailAddress, lastAccessedDate:lastAccessedDate},&lastAccessedDate))" --output table
