terraform {
    backend "s3" { 
        bucket = "orderly-k8s-buck"
        key     = "orderly/terraform.tfstate"
        dynamodb_table = "orderly-platform-lock"
        region = "eu-central-1"
        encrypt = true
        use_lockfile = false
    }
}