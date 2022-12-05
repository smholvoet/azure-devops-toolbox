# Generates work items and creates child-parent links (Agile process template):
# └── Epic
#     └── Feature
#         └── User Story
#             └── Task

$AZDO_ORG = "https://dev.azure.com/<org>"
$AZDO_PROJECT = "<team project>"
$WI_COUNT = 100 # Number of backlog items to create, setting this to 100 will create a total of 400 work items (100 * [Task / User Story / Feature / Epic])

# Configure default paramters and authenticate to Azure
az devops configure --defaults organization=$AZDO_ORG project=$AZDO_PROJECT
az devops configure --list
az login
az devops project show --project $AZDO_PROJECT

# Generate work items
for ($i = 1 ; $i -le $WI_COUNT ; $i++) {
    Write-Host "Creating dummy work items - run $i..."

    $Epic       = az boards work-item create --title "Epic $i" --type "Epic"
    $Feature    = az boards work-item create --title "Feature $i" --type "Feature"
    $UserStory  = az boards work-item create --title "User Story $i" --type "User Story"
    $Task       = az boards work-item create --title "Task $i" --type "Task"

    az boards work-item relation add --id ($Task | ConvertFrom-Json).id --relation-type parent --target-id ($UserStory | ConvertFrom-Json).id 
    az boards work-item relation add --id ($UserStory | ConvertFrom-Json).id --relation-type parent --target-id ($Feature | ConvertFrom-Json).id 
    az boards work-item relation add --id ($Feature | ConvertFrom-Json).id --relation-type parent --target-id ($Epic | ConvertFrom-Json).id
}
