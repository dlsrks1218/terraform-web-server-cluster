terraform {
 backend "s3" {
   bucket = "testing-dlsrks1218-tfstate"
   # key = "eks/elk/terraform.tfstate"
   key = "tfstate/vpc/terraform.tfstate" 
   region = "ap-northeast-2"
   encrypt = true
 }
}
