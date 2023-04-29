eksclustername=$(aws eks list-clusters | jq -r ".clusters[0]")
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster $eksclustername \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole
awscbsarn=$(aws iam get-role --role-name AmazonEKS_EBS_CSI_DriverRole | jq -r ".Role.Arn")
eksctl create addon --name aws-ebs-csi-driver --cluster $eksclustername --service-account-role-arn $awscbsarn --force
