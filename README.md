## Ephemeral Infrastructure with Azure VMS as GitHub Action Runners

_Run VMs and make them connect to the Azure cloud_

### Create a Personal Access Token (PAT)

The access token will need to be added as an Action secret. [Create one](https://github.com/settings/tokens/new?description=Azure+GitHub+Runner&scopes=repo) with enough permissions to write to packages.

## Create an Azure Service Principal

You'll need the following:

1. An Azure subscription ID [find it here](https://portal.azure.com/#view/Microsoft_Azure_Billing/SubscriptionsBlade) or [follow this guide](https://docs.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id)
1. A Service Principal with the following details the AppID, password, and tenant information. Create one with: `az ad sp create-for-rbac -n "REST API Service Principal"` and assign the IAM role for the subscription. Alternatively set the proper role access using the following command (use a real subscription id and replace it):

```
az ad sp create-for-rbac --name "CICD" --role contributor --scopes /subscriptions/$AZURE_SUBSCRIPTION_ID --sdk-auth


## Create an Azure Resource Group

A resource group is a way to group services together so that you can keep track of them and delete them later with ease. Use the `az` CLI to accomplish this:

```
az group create --location eastus --name "github-vms"
```

Keep that resource group name handy for other operations. In this repository the `"github-vms"` resource group is used throughout. Note the location as well. Make sure that the location (region) maps to the resources you want to create.

## Create an Azure Key Vault

You will store your GitHub PAT here so that it can later be retrieved by the VM.

```
az keyvault create --name github-vms --resource-group github-vms --location eastus
az keyvault secret set --vault-name github-vms --name "GitHubPAT" --value $GITHUB_PAT
```

Replace `$GITHUB_PAT` with the value of the `PAT` created earlier


## Assign an identity with permissions for Key Vault

Now that the key vault is created, you need to create an identity and then allow resources in the resource group to be able to access it. You must give this identity a name, in this case we use `GitHubVMs`. Note this name will be used in other steps.

```
az identity create --name GitHubVMs --resource-group github-vms --location eastus
```

Capture the Principal ID which will be used for the value for `--object-id` later. You can retrieve it again by using:

```
az identity show --name GitHubVMs --resource-group github-vms
```

Use the object id to set the policy, replace `$OBJECT_ID` with the one you found in the previous command:

```
az keyvault set-policy --name github-vms --object-id $OBJECT_ID --secret-permissions get
```

## Verify you can get the PAT with the following command:

```
az keyvault secret show --name "GitHubPAT" --vault-name github-vms --query value -o tsv
```

## Provide a role to VMs

Assign a role to the VMs so that they have enough permissions to write the image when getting created. Start by finding the `principalId` which will then be needed for the next step:

```
az identity show --name GitHubVMs --resource-group github-vms --query principalId
```

With the `principalId` you can assign it to the VMs now:

```
az role assignment create --assignee $PRINCIPAL_ID --role Contributor --resource-group github-vms
```

## Trigger the create image run

Now you are ready to create the image. Run it manually and make sure it works correctly. If succesful, an image will be created for you which you can query with the following command:

```
az image list --resource-group github-vms --output table
```

Note the hypervisor version, you might get into trouble if you need one image to work with a different hypervisor.


## Errors

There are plenty of errors that may come up with this sort of setup. You should expect errors which can be transient, caused from typos, or because of changes to image types, destinations, or permissions.

### Look at Packer logs

Packer logs will provide you log output of your customization script if it fails. This is useful in case you want to add debug information from the script. Any `stdout` output will be captured and shown in the logs. Common error string to expect is `During the image build a failure has occurred. Packer build logs are at location`. Find the storage account so that you can browse the right one to download the file in the container browser in the portal:

```
/subscriptions/***/resourceGroups/IT_github-vms_imagebuilderTemplate_16974568_cf08115f-6172-43db-b07b-6fceb1788c7a/providers/Microsoft.Storage/storageAccounts/z3hdpy5u8lhsw1gurjzvr2h6/blobServices/default/containers/packerlogs/[...]
```

In that case, it would be storage `z3hdpy5u8lhsw1gurjzvr2h6` that you would need to find to get to the packer logs
