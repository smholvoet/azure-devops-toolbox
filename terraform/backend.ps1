# Prerequisite - install jq
choco install jq

# Set environment variables
$TF_BACKEND_SUBSCRIPTION_ID     = "<...>"
$TF_BACKEND_RG_NAME             = "terraform-workspaces-rg"
$TF_BACKEND_STORAGEACCT_NAME    = "<...>"
$TF_BACKEND_CONTAINER_NAME      = "terraform"
$TF_BACKEND_LOCATION            = "westeurope"

# Create resource group
az group create `
    --subscription $TF_BACKEND_SUBSCRIPTION_ID `
    --name $TF_BACKEND_RG_NAME `
    --location $TF_BACKEND_LOCATION

# Create storage account
az storage account create `
    --name $TF_BACKEND_STORAGEACCT_NAME `
    --resource-group $TF_BACKEND_RG_NAME `
    --kind StorageV2 `
    --sku Standard_LRS `
    --https-only true `
    --allow-blob-public-access false

# Create container
az storage container create `
    --name $TF_BACKEND_CONTAINER_NAME `
    --account-name $TF_BACKEND_STORAGEACCT_NAME `
    --public-acces off `
    --auth-mode login

# Get storage account credentials
az storage account keys list `
	--resource-group $TF_BACKEND_RG_NAME `
	--account-name $TF_BACKEND_STORAGEACCT_NAME `
		| jq -r '.[0].value'