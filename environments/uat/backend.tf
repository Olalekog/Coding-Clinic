# Bucket, key, and region are supplied at init time with -backend-config, so
# the same file works for every environment.
terraform {
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}
