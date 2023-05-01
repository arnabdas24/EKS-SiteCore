eksclustername=$(aws eks list-clusters | jq -r ".clusters[0]")
region=$(aws configure get region)
eksvpc=$(aws eks describe-cluster --name kubemaster | jq -r ".cluster.resourcesVpcConfig.vpcId")
eksctl utils associate-iam-oidc-provider --region $region --cluster $eksclustername --approve
curl -o iam_policy_latest.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
ingresspolicy=$(aws --region $region iam create-policy --query Policy.Arn --output text \
--policy-name "AWSLoadBalancerControllerIAMPolicy" \
--policy-document file://iam_policy_latest.json)

eksctl create iamserviceaccount \
  --cluster $eksclustername \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn $ingresspolicy \
  --override-existing-serviceaccounts \
  --approve
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$eksclustername \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=$ingresspolicy \
  --set vpcId=$eksvpc