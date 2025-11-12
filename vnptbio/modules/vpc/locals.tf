locals {
  common_tags = merge(
    {
      ManagedBy = "Terraform"
    },
    var.tags
  )
}
