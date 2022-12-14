# Terraform Multi Region & Environment POC

This repository is an attempt to use Terraform to deploy cloud resources to multiple environments and regions.

## The problem

The aim of this repository is to understand how to create and manage multi-account and multi-region cloud resources using Terraform?

### Possible Solutions

#### Utilizing input variables

- Input varialbe file for each region, i.e `us-east-1.tfvars` will deploy cloud resources to the `us-east-1` AWS region.
- This could be useful for deploying cloud resources to multiple regions that do not need to be deployed all at once.
- This is also usefule when deploying the same cloud resources to multiple regions in one account but another account could only need the same resource deployed in a single region.

Example:

```
.
├── Makefile
├── README.md
├── deploy
│   ├── demo
│   │   ├── eu-west-1.tfvars
│   │   ├── globals.tfvars
│   │   ├── us-east-1.tfvars
│   │   └── us-west-2.tfvars
│   ├── develop
│   │   ├── eu-west-1.tfvars
│   │   ├── globals.tfvars
│   │   └── us-east-1.tfvars
│   ├── globals
│   │   └── inputs.tfvars
│   ├── production
│   │   ├── eu-west-1.tfvars
│   │   ├── globals.tfvars
│   │   ├── us-east-1.tfvars
│   │   └── us-west-2.tfvars
│   └── staging
│       ├── globals.tfvars
│       └── us-east-1.tfvars
├── main.tf
├── outputs.tf
├── variables.tf
└── versions.tf

```

The repository structure above demonstrates how someone could use input variable files to deploy cloud resources to a specific account and region. The Makefile is included to easily deploy by just setting the `DEPLOY` and `AWS_REGION` environment variable. The `DEPLOY` environment variable represents the account (or environment) you will be deploying to. You can think of this as production, staging, demo, etc. The `AWS_REGION` will of course represent the region you will be deploying cloud resources to and the input variable files to be used during a `terraform plan` and/or `terraform apply`. The `deploy/globals` directory will be used to store global input variables used across all environments and regions.

#### Provider blocks in conjuction with input variables

- Instead of having unique input variable files for each region, you can utilize provider blocks and set the parameter, `region` and alias to define the region you wish to deploy cloud resources. 
- This is useful for when a cloud resource needs to be deployed to multiple regions for each of your accounts or environments.

Example:

```
# define our US app deployment provider
provider "aws" {
  region = "us-east-1"
  alias = "us-east-1"
}

# define our EU app deployment provider
provider "aws" {
  region = "eu-west-1"
  alias  = "eu-west-1"
}

# let's pretend we have a module which we defines our app
# we can pass a provider block to define the region where
# we would like our app to be deployed!
module "eu-app" {
    source = "../"

    providers = {
        aws.eu-west-1
    }
}

module "us-app" {
    source = "../"

    providers = {
        aws.us-east-1
    }
}
```

By using and defining unique provider blocks for each region, this will help reduce having many input variable files for when you are deploying the same cloud resources across the same accounts and regions. Also, by taking advantage of using modules, you can further define and configure how you would like to deploy your cloud resources. One great example of this would be by using the `depends_on = [module.app1]` meta argument on one of your app deployments which relies on the same app deployed in a different region.

An example directory structure could look like so:

```
.
├── deploy/
│   ├── globals/
│   │   └── inputs.tfvars
│   ├── production/
│   │   └── inputs.tfvars
│   ├── demo/
│   │   └── inputs.tfvars
│   └── staging/
│       └── inputs.tfvars
├── .pre-commit-config.yaml
├── .gitignore
├── main.tf
├── variables.tf
├── versions.tf
├── outputs.tf
├── README.md
└── Makefile
```

Note that we will still be utilizing input variable files for each unique account (environmnt). Just like the example above, the `deploy/globals` directory will store all input variables which will be global across all environments and regions.
