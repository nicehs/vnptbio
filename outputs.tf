output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "bastion_public_ip" {
  value = module.ec2.bastion_public_ip
}

output "nlb_dns_name" {
  value = module.nlb.nlb_dns_name
}
