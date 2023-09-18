# The Littlest JupyterHub deployment with Azure Developer CLI (azd)

A template for deploying the Littlest JupyterHub distribution on Azure using [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview) (azd), based on the [amazing ARM template](https://github.com/trallard/TLJH-azure-button) by [@trallard](https://github.com/trallard).

> Get your own JupyterHub going in with just `azd up` 💖

This repo contains:

- Infrastructure-as-code (IaC) Bicep files under the `infra` folder that demonstrate how to provision resources and setup resource tagging for azd.
- A [dev container](https://containers.dev) configuration file under the `.devcontainer` directory that installs infrastructure tooling by default. This can be readily used to create cloud-hosted developer environments such as [GitHub Codespaces](https://aka.ms/codespaces).
- Continuous deployment workflows for CI providers such as GitHub Actions under the `.github` directory.

## Deployment

Start by cloning the repo, and make sure you also log in to Azure with the azd cli tool.

In the directory, run `azd up` to run the end-to-end infrastructure provisioning (`azd provision`) and deployment (`azd deploy`) flow. Visit the service endpoints listed to see your application up-and-running!

## Local development with Docker

## Develop with Codespaces

## Configuration

The following section examines different concepts that help tie in application and infrastructure.

<!-- ### Application settings

It is recommended to have application settings managed in Azure, separating configuration from code. Typically, the service host allows for application settings to be defined.

- For `appservice` and `function`, application settings should be defined on the Bicep resource for the targeted host. Reference template example [here](https://github.com/Azure-Samples/todo-nodejs-mongo/tree/main/infra).
- For `aks`, application settings are applied using deployment manifests under the `<service>/manifests` folder. Reference template example [here](https://github.com/Azure-Samples/todo-nodejs-mongo-aks/tree/main/src/api/manifests).

### Managed identities

[Managed identities](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) allows you to secure communication between services. This is done without having the need for you to manage any credentials.

### Azure Key Vault

[Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/overview) allows you to store secrets securely. Your application can access these secrets securely through the use of managed identities.

### Host configuration

For `appservice`, the following host configuration options are often modified:

- Language runtime version
- Exposed port from the running container (if running a web service)
- Allowed origins for CORS (Cross-Origin Resource Sharing) protection (if running a web service backend with a frontend)
- The run command that starts up your service -->
