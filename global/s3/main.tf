provider "aws" {
	region = "ap-northeast-2"
}

resource "aws_s3_bucket" "tfstate" {
	bucket = "${var.bucket_name}-seoul-tfstate"
	versioning {
		enabled = true
	}
}

