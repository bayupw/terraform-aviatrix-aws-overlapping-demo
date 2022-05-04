# Terraform AWS Overlapping IP Aviatrix Demo 

Terraform code to demonstrate how Aviatrix can be used to solve overlapping IP in AWS.
![Terraform AWS Overlapping IP Aviatrix Demo](images/terraform-aviatrix-aws-overlapping-demo.png "Terraform AWS Overlapping Aviatrix Demo")

## Prerequisites

Please make sure you have:
- Aviatrix Controller 6.6+
- AWS access accounts are onboarded. 

## Environment Variables

To run this project, you will need to set the following environment variables

Variables | Description
--- | ---
AVIATRIX_CONTROLLER_IP | Aviatrix Controller IP or FQDN 
AVIATRIX_USERNAME | Aviatrix Controller Username
AVIATRIX_PASSWORD | Aviatrix Controller Password
TF_VAR_aws_account | AWS Aviatrix Account 
TF_VAR_azure_account | Azure Aviatrix Account
TF_VAR_gcp_account | GCP Aviatrix Account

## Run Locally

Clone the project

```bash
git clone https://github.com/bayupw/terraform-aviatrix-aws-overlapping-demo.git
```

Go to the project directory

```bash
cd terraform-aviatrix-aws-overlapping-demo
```

Set environment variables

```bash
export AWS_ACCESS_KEY_ID="A1b2C3d4E5"
export AWS_SECRET_ACCESS_KEY="A1b2C3d4E5"
export AWS_DEFAULT_REGION="ap-southeast-2"
export AVIATRIX_CONTROLLER_IP="aviatrixcontroller.aviatrix.lab"
export AVIATRIX_USERNAME="admin"
export AVIATRIX_PASSWORD="aviatrix123"
export TF_VAR_aws_account="aws-account"
```

Terraform workflow

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

## Contributing

Report issues/questions/feature requests on in the [issues](https://github.com/bayupw/terraform-aviatrix-aws-overlapping-demo/issues/new) section.

## License

Apache 2 Licensed. See [LICENSE](https://github.com/bayupw/terraform-aviatrix-aws-overlapping-demo/tree/master/LICENSE) for full details.