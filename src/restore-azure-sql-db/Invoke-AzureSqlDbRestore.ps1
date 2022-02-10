# -------------
# Source params
# -------------
$SourceSubscription     = ""
$SourceResourceGroup    = ""
$SourceServer           = ""
$SourceDatabase         = ""
$SourceAdminUser        = ""
$SourceAdminPassword    = (az keyvault secret show --name "" `
                                                   --vault-name "" `
                                                   --query "")

# -------------
# Target params
# -------------
$TargetResourceGroup    = ""
$TargetSubscription     = ""
$TargetServer           = ""
$TargetAdminUser        = ""
$SourceAdminPassword    = (az keyvault secret show --name "" `
                                                   --vault-name "" `
                                                   --query "")

# ----------------------
# Storage account params
# ----------------------
$StorageAccountName     = ""
$StorageContainerName   = ""

# Uncomment the lines below When running this script locally, authenticate to Azure and verify you have access to both the source and target subscriptions
# az login
# az account list --all --output table

# ------
# Export
# ------

# Verify source db exists
az sql db show --subscription $SourceSubscription `
               --resource-group $SourceResourceGroup `
               --server $SourceServer `
               --name $SourceDatabase `
               --output json 
if($LASTEXITCODE -ne 0 ) { exit }

# Get storage account key
$StorageAccountKey = (az storage account show-connection-string --subscription $TargetSubscription `
                                                                --resource-group $TargetResourceGroup `
                                                                --name $StorageAccountName `
                                                                --query connectionString `
                                                                --output tsv).Split("AccountKey=")[-1]

# Construct bacpac filename
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$BackupFileName="$($SourceDatabase)-backup-$($Timestamp).bacpac"

# Export bacpac to storage account
az sql db export --subscription $SourceSubscription `
                 --resource-group $SourceResourceGroup `
                 --server $SourceServer `
                 --name $SourceDatabase `
                 --admin-user $SourceAdminUser `
                 --admin-password $SourceAdminPassword `
                 --storage-key $StorageAccountKey `
                 --storage-key-type StorageAccessKey `
                 --storage-uri "https://$($StorageAccountName).blob.core.windows.net/$($StorageContainerName)/$($BackupFileName)"

# Verify bacpac has been uploaded to storage account
az storage blob list --subscription $TargetSubscription `
                     --account-name $StorageAccountName `
                     --container-name $StorageContainerName `
                     --auth-mode key `
                     --account-key $StorageAccountKey `
                     --output table

# ------
# Restore
# ------

# Create empty database
az sql db create --subscription $TargetSubscription `
                 --resource-group $TargetResourceGroup `
                 --server $TargetServer `
                 --name "$($SourceDatabase)-new" `
                 --service-objective Basic 

# Import bacpac into empty database
az sql db import --subscription $TargetSubscription `
                 --resource-group $TargetResourceGroup `
                 --server $TargetServer `
                 --name "$($SourceDatabase)-new" `
                 --admin-user $TargetAdminUser `
                 --admin-password $TargetAdminPassword `
                 --storage-key $StorageAccountKey `
                 --storage-key-type StorageAccessKey `
                 --storage-uri "https://$($StorageAccountName).blob.core.windows.net/$($StorageContainerName)/$($BackupFileName)"

# Rename databases
# "<db-name>" ---> "<db-name>-old"
az sql db rename --subscription $TargetSubscription `
                 --resource-group $TargetResourceGroup `
                 --server $TargetServer `
                 --name "$($SourceDatabase)" `
                 --new-name "$($SourceDatabase)-old"

# "<db-name-new>" ---> "<db-name>"
az sql db rename --subscription $TargetSubscription `
                 --resource-group $TargetResourceGroup `
                 --server $TargetServer `
                 --name "$($SourceDatabase)-new" `
                 --new-name "$($SourceDatabase)"
# --------
# Clean-up
# --------

# Remove old db
az sql db delete --subscription $TargetSubscription `
                 --resource-group $TargetResourceGroup `
                 --server $TargetServer `
                 --name "$($SourceDatabase)-old" `
                 --yes

# Remove .bacpac from storage account
az storage blob delete --subscription $TargetSubscription `
                       --container-name $StorageContainerName `
                       --name $BackupFileName `
                       --account-name $StorageAccountName `
                       --auth-mode key `
                       --account-key $StorageAccountKey
