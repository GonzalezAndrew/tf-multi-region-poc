## Verify the Makefile has the correct environment variables set before running
ifndef DEPLOY
$(error DEPLOY variable was not set.)
else ifndef AWS_REGION
$(error AWS_REGION variable was not set.)
endif

## Set variables based on the environment we are deploying to.
region=${AWS_REGION}
key="tf-multi-region-poc"

## we need to formulate the region prefix i.e us-east-1 => use1, eu-west-1 => euw1
region_prefix_=$(shell r='$(region)'; echo $${r//-})
region_prefix=$(shell rp='$(region_prefix_)'; echo $${rp[@]:0:3}$${rp[@]:1,-1})

## verify a correct DEPLOY var was given
ifeq "$(DEPLOY)" "production"
	s3_bucket="prod-$(region_prefix)-tf-terraform-states"
	dynamodb_table="prod-tf-remote"
else ifeq "$(DEPLOY)" "demo"
	s3_bucket="demo-$(region_prefix)-tf-terraform-states"
	dynamodb_table="demo-$(region_prefix)-tf-remote"
else ifeq "$(DEPLOY)" "staging"
	s3_bucket="staging-$(region_prefix)-tf-terraform-states"
	dynamodb_table="staging-$(region_prefix)-tf-remote"
else ifeq "$(DEPLOY)" "develop"
	s3_bucket="develop-$(region_prefix)-tf-terraform-states"
	dynamodb_table="develop-$(region_prefix)-tf-remote"
else
$(error invalid DEPLOY variable: $(DEPLOY))
endif

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

init: ## Initializes the terraform remote state backend and pulls the correct deploy state.
	@if [ -z $(DEPLOY) ]; then echo "DEPLOY was not set" ; exit 10 ; fi
	@rm -rf .terraform/*.tf*
	@terraform init \
        -backend-config="bucket=${s3_bucket}" \
        -backend-config="key=${key}/terraform.tfstate" \
        -backend-config="dynamodb_table=${dynamodb_table}" \
        -backend-config="region=${region}"

update: ## Gets any module updates
	@terraform get -update=true &>/dev/null

plan: init update ## Runs a plan. Note that in Terraform < 0.7.0 this can create state entries.
	@terraform plan \
		-input=false \
		-refresh=true \
		-var-file=deploy/globals/inputs.tfvars \
		-var-file=deploy/$(DEPLOY)/globals.tfvars \
		-var-file=deploy/$(DEPLOY)/${region}.tfvars

plan-out: init update ## Runs a plan. Note that in Terraform < 0.7.0 this can create state entries.
	@terraform plan \
		-input=false \
		-out=plan.hcl \
		-refresh=true \
		-var-file=deploy/globals/inputs.tfvars \
		-var-file=deploy/$(DEPLOY)/globals.tfvars \
		-var-file=deploy/$(DEPLOY)/${region}.tfvars

plan-show: plan-out
	@terraform show -json plan.hcl | jq '.' > plan.json

plan-destroy: init update ## Shows what a destroy would do.
	@terraform plan -input=false \
		-refresh=true \
		-module-depth=-1 \
		-destroy \
		-var-file=deploy/globals/inputs.tfvars \
		-var-file=deploy/$(DEPLOY)/globals.tfvars \
		-var-file=deploy/$(DEPLOY)/${region}.tfvars

show: init ## Shows a module
	@terraform show -module-depth=-1

graph: ## Runs the terraform grapher
	@rm -f graph.png
	@terraform graph -draw-cycles -module-depth=-1 | dot -Tpng > graph.png
	@open graph.png

apply: init update ## Run terraform apply.
	@terraform apply \
		-input=true \
		-refresh=true \
		-var-file=deploy/globals/inputs.tfvars \
		-var-file=deploy/$(DEPLOY)/globals.tfvars \
		-var-file=deploy/$(DEPLOY)/${region}.tfvars

validate: init update ## Run terraform validate.
	@terraform validate

output: update ## Show outputs of a module or the entire state.
	@if [ -z $(MODULE) ]; then terraform output ; else terraform output -module=$(MODULE) ; fi

destroy: init update ## Run terraform destroy.
	@terraform destroy \
		-var-file=deploy/globals/inputs.tfvars \
		-var-file=deploy/$(DEPLOY)/globals.tfvars \
		-var-file=deploy/$(DEPLOY)/${region}.tfvars

lint: ## Run pre-commit against the repository
	@pre-commit run -a

docs: ## Generate terraform-docs for README.md file
	@terraform-docs markdown table . --output-file README.md
