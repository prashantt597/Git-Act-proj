terraform {
     required_version = ">= 1.3.0"
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = ">= 5.0.0"
       }
       kubernetes = {
         source  = "hashicorp/kubernetes"
         version = ">= 2.20.0"
       }
       helm = {
         source  = "hashicorp/helm"
         version = ">= 2.9.0"
       }
     }
     backend "s3" {
       bucket         = "tfstate-prashant597"
       key            = "terraform.tfstate"
       region         = "ap-south-1"
       dynamodb_table = "terraform-lock"
     }
   }

   provider "aws" {
     region = "ap-south-1"
   }

   provider "kubernetes" {
     host                   = aws_eks_cluster.eks.endpoint
     cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
     token                  = data.aws_eks_cluster_auth.eks.token
   }

   provider "helm" {
     kubernetes {
       host                   = aws_eks_cluster.eks.endpoint
       cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
       token                  = data.aws_eks_cluster_auth.eks.token
     }
   }

   data "aws_availability_zones" "available" {}

   data "aws_eks_cluster_auth" "eks" {
     name = aws_eks_cluster.eks.name
   }

   resource "aws_vpc" "eks_vpc" {
     cidr_block = "10.0.0.0/16"
     enable_dns_hostnames = true
     enable_dns_support   = true
     tags = { Name = "eks-vpc" }
   }

   resource "aws_subnet" "eks_subnet" {
     count                   = 2
     vpc_id                  = aws_vpc.eks_vpc.id
     cidr_block              = "10.0.${count.index}.0/24"
     availability_zone       = data.aws_availability_zones.available.names[count.index]
     map_public_ip_on_launch = true
     tags = {
       Name                        = "eks-subnet-${count.index}"
       "kubernetes.io/cluster/eks-github" = "shared"
       "kubernetes.io/role/elb"    = "1"
     }
   }

   resource "aws_internet_gateway" "eks_igw" {
     vpc_id = aws_vpc.eks_vpc.id
     tags = { Name = "eks-igw" }
   }

   resource "aws_route_table" "eks_rt" {
     vpc_id = aws_vpc.eks_vpc.id
     route {
       cidr_block = "0.0.0.0/0"
       gateway_id = aws_internet_gateway.eks_igw.id
     }
     tags = { Name = "eks-rt" }
   }

   resource "aws_route_table_association" "eks_rta" {
     count          = 2
     subnet_id      = aws_subnet.eks_subnet[count.index].id
     route_table_id = aws_route_table.eks_rt.id
   }

   resource "aws_iam_role" "eks_role" {
     name = "eks-role"
     assume_role_policy = jsonencode({
       Version = "2012-10-17"
       Statement = [{
         Action = "sts:AssumeRole"
         Effect = "Allow"
         Principal = { Service = "eks.amazonaws.com" }
       }]
     })
   }

   resource "aws_iam_role_policy_attachment" "eks_policy" {
     role       = aws_iam_role.eks_role.name
     policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
   }

   resource "aws_eks_cluster" "eks" {
     name     = "eks-github"
     role_arn = aws_iam_role.eks_role.arn
     vpc_config {
       subnet_ids         = aws_subnet.eks_subnet[*].id
       endpoint_public_access = true
     }
     depends_on = [aws_iam_role_policy_attachment.eks_policy]
   }

   resource "aws_iam_role" "node_role" {
     name = "eks-node-role"
     assume_role_policy = jsonencode({
       Version = "2012-10-17"
       Statement = [{
         Action = "sts:AssumeRole"
         Effect = "Allow"
         Principal = { Service = "ec2.amazonaws.com" }
       }]
     })
   }

   resource "aws_iam_role_policy_attachment" "node_policy" {
     role       = aws_iam_role.node_role.name
     policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
   }

   resource "aws_iam_role_policy_attachment" "node_cni_policy" {
     role       = aws_iam_role.node_role.name
     policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
   }

   resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
     role       = aws_iam_role.node_role.name
     policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
   }

   resource "aws_eks_node_group" "node_group" {
     cluster_name    = aws_eks_cluster.eks.name
     node_group_name = "eks-node-group"
     node_role_arn   = aws_iam_role.node_role.arn
     subnet_ids      = aws_subnet.eks_subnet[*].id
     scaling_config {
       desired_size = 2
       max_size     = 2
       min_size     = 2
     }
     instance_types = ["t3.medium"]
     depends_on = [
       aws_iam_role_policy_attachment.node_policy,
       aws_iam_role_policy_attachment.node_cni_policy,
       aws_iam_role_policy_attachment.node_ecr_policy
     ]
   }

   resource "aws_iam_policy" "alb_controller_policy" {
     name   = "AWSLoadBalancerControllerIAMPolicy"
     policy = jsonencode({
       Version = "2012-10-17"
       Statement = [
         {
           Effect = "Allow"
           Action = [
             "iam:CreateServiceLinkedRole",
             "ec2:Describe*",
             "elasticloadbalancing:*",
             "tag:GetResources",
             "waf-regional:*",
             "wafv2:*",
             "acm:ListCertificates",
             "acm:DescribeCertificate"
           ]
           Resource = "*"
         }
       ]
     })
   }

   resource "aws_iam_role" "alb_controller_role" {
     name = "eks-alb-controller-role"
     assume_role_policy = jsonencode({
       Version = "2012-10-17"
       Statement = [{
         Effect = "Allow"
         Principal = {
           Federated = aws_iam_openid_connect_provider.eks_oidc.arn
         }
         Action = "sts:AssumeRoleWithWebIdentity"
         Condition = {
           StringEquals = {
             "${replace(aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
           }
         }
       }]
     })
   }

   resource "aws_iam_role_policy_attachment" "alb_controller_policy_attachment" {
     role       = aws_iam_role.alb_controller_role.name
     policy_arn = aws_iam_policy.alb_controller_policy.arn
   }

   resource "aws_iam_openid_connect_provider" "eks_oidc" {
     url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
     client_id_list  = ["sts.amazonaws.com"]
     thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
   }

   resource "kubernetes_service_account" "alb_controller" {
     metadata {
       name      = "aws-load-balancer-controller"
       namespace = "kube-system"
       annotations = {
         "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller_role.arn
       }
     }
   }

   resource "helm_release" "alb_controller" {
     name       = "aws-load-balancer-controller"
     repository = "https://aws.github.io/eks-charts"
     chart      = "aws-load-balancer-controller"
     namespace  = "kube-system"
     set {
       name  = "clusterName"
       value = aws_eks_cluster.eks.name
     }
     set {
       name  = "serviceAccount.create"
       value = "false"
     }
     set {
       name  = "serviceAccount.name"
       value = kubernetes_service_account.alb_controller.metadata[0].name
     }
     depends_on = [aws_eks_node_group.node_group]
   }