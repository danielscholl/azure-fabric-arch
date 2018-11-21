#######################################################################################################
# Environment Settings ################################################################################

$Env:AZURE_TENANT = "<your_tenant_id>"                            # Tenant ID of the subscription
$Env:AZURE_SUBSCRIPTION = "<your_subscription_id>"                # Subscription ID to own the resources
$Env:AZURE_PRINCIPAL = "<your_principal_id>"                      # Principal ID with rights to the KV
$Env:AZURE_LOCATION = "eastus2"                                   # Region Location

$Env:AZURE_USERNAME = "<your_admin_name>"                         # RDP UserName
$Env:AZURE_PASSWORD = "<your_admin_pwd>"                          # RDP Password

$Env:AZURE_GROUP = "fabric"                                       # Group Name
$Env:AZURE_RANDOM = "999"                                         # Unique 3 Digit Identifier
$Env:FABRIC_TIER = "bronze"                                       # Durability Level
$Env:FABRIC_NODE_COUNT = 1                                        # Instance Count
