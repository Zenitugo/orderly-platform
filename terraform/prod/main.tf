module "vpc" {
    source                                      = "../modules/vpc"
    vpc_cidr                                    = var.vpc_cidr
    project_name                                = var.project_name
    subnet_cidr_private_1                       = var.subnet_cidr_private_1
    subnet_cidr_private_2                       = var.subnet_cidr_private_2
    subnet_cidr_public_1                        = var.subnet_cidr_public_1
    subnet_cidr_public_2                        = var.subnet_cidr_public_2     
}

module "sg" {
    source                                      = "../modules/sg"
    project_name                                = var.project_name 
    vpc_id                                      = module.vpc.vpc_id
}

module "ecr" {
    source                                      = "../modules/ecr"
    project_name                                = var.project_name
}

module "iam" {
    source                                      = "../modules/iam"
    eks_cluster_role_name                       = var.eks_cluster_role_name
    node_group_role_name                        = var.node_group_role_name
}

module "eks" {
    source                                      = "../modules/eks"
    cluster_name                                = var.cluster_name
    eks_cluster_role_arn                        = module.iam.eks_cluster_role_arn
    kubernetes_version                          = var.kubernetes_version
    private_subnet_1_id                         = module.vpc.private_subnet_1_id
    private_subnet_2_id                         = module.vpc.private_subnet_2_id
    node_group_name                             = var.node_group_name
    node_group_role_arn                         = module.iam.node_group_role_arn
    instance_type                               = var.instance_type 
}
