/*
    Description:
    To use local to deploy sap library(s). 
    Specify the path of saplibrary.terraform.tfstate.
*/
terraform {
  backend "local" {
    path = "../../run/sap_library/terraform.tfstate"
  }
}
