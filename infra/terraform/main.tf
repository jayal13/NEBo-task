module "vpc"{
    source = "./modules/vpc"
}

module "securiy-groups"{
    source = "./modules/security-groups"
    vpc_id = module.vpc.vpc_id
}

module "iam"{
    source = "./modules/iam"
}
