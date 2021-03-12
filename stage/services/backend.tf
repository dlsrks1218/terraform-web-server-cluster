terraform {
 backend "s3" {
   bucket = "testing-dlsrks1218-tfstate"
   key = "tfstate/webserver/terraform.tfstate"
   region = "ap-northeast-2"
   encrypt = true
 }
}
