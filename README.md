# This is a test repo used for stashing my code for RX Savings Solutions' CodeSignal Terraform coding challenge

### To run:
* Ensure you are using terraform v0.15.0
    * Install `tfenv` with `brew install tfenv` if not already installed
    * `tfenv install 0.15.0`
    * `tfenv use 0.15.0`
* Export your AWS environment variables for terraform to use
    * export AWS_ACCESS_KEY_ID=""
    * export AWS_SECRET_ACCESS_KEY=""
    * export AWS_DEFAULT_REGION="us-east-1"
* Use terraform
    * `terraform init`
    * `terraform plan`
    * `terraform apply`
    * `terraform destroy`