terraform {
    backend "s3" { 
        bucket = "ugochi-orderly"
        key     = "orderly/terraform.tfstate"
        dynamodb_table = "orderly-platform-lock"
        region = "eu-central-1"
        encrypt = true
        use_lockfile = false
    }
}