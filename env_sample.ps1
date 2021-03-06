#######################################################################################################
# Environment Settings ################################################################################

$Env:AZURE_TENANT = "<your_tenant_id>"                            # Tenant ID of the subscription
$Env:AZURE_SUBSCRIPTION = "<your_subscription_id>"                # Subscription ID to own the resources
$Env:AZURE_PRINCIPAL = "<your_principal_id>"                      # Principal ID with rights to the KV
$Env:AZURE_LOCATION = "eastus2"                                   # Region Location
$Env:AZURE_ANALYTICS = "<your_oms_name>"                          # OMS Workspace Name
$Env:AZURE_ANALYTICS_KEY = "<your_oms_key>"                       # OMS Workspace Key

$Env:AZURE_USERNAME = "<your_admin_name>"                         # RDP UserName
$Env:AZURE_PASSWORD = "<your_admin_pwd>"                          # RDP Password

$Env:AZURE_GROUP = "fabric"                                       # Group Name
$Env:AZURE_RANDOM = "999"                                         # Unique 3 Digit Identifier
$Env:FABRIC_TIER = "bronze"                                       # Durability Level
$Env:FABRIC_NODE_COUNT = 1                                        # Instance Count

$Env:Endpoint = "<your_sf_endpoint>"                              # Service Fabric FQDN and Port
$Env:ThumbPrint = "<your_x509_thumbprint>"                        # x509 Certificate Thumbnail
$Env:CLUSTER_APP = "<ad_app_cluster>"                             # Web Appliation
$Env:CLIENT_APP = "<ad_app_client>"                               # Native Client Application
