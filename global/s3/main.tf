provider "aws" {
	region = "ap-northeast-2"
}


// S3 Bucket for backend
resource "aws_s3_bucket" "tfstate" {
	bucket = "${var.bucket_name}-tfstate"
	versioning {
		enabled = true
	}
}

// DynamoDB for tfstate locking
resource "aws_dynamodb_table" "tfstate_lock" {
	hash_key = "LockID" # Primary Key is Lock ID
	name = "terraform_lock"
	read_capacity = 1
	write_capacity = 1

	attribute {
		name = "LockID"
		type = "S"
	}
}
