#!/bin/bash
 
download_file_based_checkOS() {
  case "$1" in
    darwin*)
      curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/$(uname -m)/kubectl
      chmod +x ./kubectl
      ./kubectl version --client
 
      curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/${clusterctl_version}/clusterctl-darwin-$(uname -m) -o clusterctl
      chmod +x ./clusterctl
      ./clusterctl version
 
      curl -L https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/${clusterawsadm_version}/clusterawsadm-darwin-$(uname -m) -o clusterawsadm
      chmod +x ./clusterawsadm
      ./clusterawsadm version
      ;;
 
    linux*)
 
      if [[ $(uname -m) == "x86_64" ]]; then
        curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${linux_arch_amd64}/kubectl
        chmod +x ./kubectl
        ./kubectl version --client
 
        curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/${clusterctl_version}/clusterctl-linux-${linux_arch_amd64} -o clusterctl
        chmod +x ./clusterctl
        ./clusterctl version
 
        curl -L https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/${clusterawsadm_version}/clusterawsadm-linux-${linux_arch_amd64} -o clusterawsadm
        chmod +x ./clusterawsadm
        ./clusterawsadm version
      else
        curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${linux_arch_arm64}/kubectl
        chmod +x ./kubectl
        ./kubectl version --client
 
        curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/${clusterctl_version}/clusterctl-linux-${linux_arch_arm64} -o clusterctl
        chmod +x ./clusterctl
        ./clusterctl version
 
        curl -L https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/${clusterawsadm_version}/clusterawsadm-linux-${linux_arch_arm64} -o clusterawsadm
        chmod +x ./clusterawsadm
        ./clusterawsadm version
      fi     
      ;;
 
    *)
      echo -e "\nError - unknown OS: $OSTYPE"
      echo "Quit"
      exit 1
      ;;
  esac
}
 
generateEKSConfig() {
  cat << EOF > $EKS_CONFIG_LOCATION
---
apiVersion: bootstrap.aws.infrastructure.cluster.x-k8s.io/v1beta1
kind: AWSIAMConfiguration
spec:
  region: ${region}
  bootstrapUser:
    enable: true
  eventBridge:
    enable: true
  allowAssumeRole: true
  eks:
    disable: false
    defaultControlPlaneRole:
      disable: false # Set to false to enable creation of the default control plane role
    fargate:
      disable: false
    managedMachinePool:
      disable: false
    iamRoleCreation: false # Set to true if you plan to use the EKSEnableIAM feature flag to enable automatic creation of IAM roles
  clusterAPIControllers: # This is the section that really matter
    disabled: false
    extraStatements:
    - Action:
      - "sts:AssumeRole"
      Effect: "Allow"
      Resource: ["arn:aws:iam::${aws_managed_account_id}:role/controllers.cluster-api-provider-aws.sigs.k8s.io"]
    trustStatements:
    - Action:
      - "sts:AssumeRoleWithWebIdentity"
      Effect: "Allow"
      Principal:
        Federated:
        - "${cluster_federate_arn}"
      Condition:
        "ForAnyValue:StringEquals":
          "${cluster_oidc_provider}:sub":
            - system:serviceaccount:capi-providers:capa-controller-manager
            - system:serviceaccount:capa-eks-control-plane-system:capa-eks-control-plane-controller-manager # Include if also using EKS
EOF
}
 

initializaCAPI() {
  ./clusterawsadm bootstrap iam create-cloudformation-stack --config $EKS_CONFIG_LOCATION --region ${region}
  export AWS_B64ENCODED_CREDENTIALS="$(./clusterawsadm bootstrap credentials encode-as-profile --region ${region})"
  aws eks update-kubeconfig --name ${cluster_name} --region ${region}
  ./clusterctl init --infrastructure ${cloud_provider} || true
 
  # ./clusterctl init --infrastructure ${cloud_provider} || \
  # ./clusterctl upgrade apply \
  #   --bootstrap capi-kubeadm-bootstrap-system/kubeadm:${clusterctl_version} \
  #   --control-plane capi-kubeadm-control-plane-system/kubeadm:${clusterctl_version} \
  #   --core capi-system/cluster-api:${clusterctl_version} \
  #   --infrastructure capa-system/aws:${clusterawsadm_version}
}
 

cleanup() {
  if [[ -f $EKS_CONFIG_LOCATION ]]; then
    rm -f $EKS_CONFIG_LOCATION || true
  fi
  if [[ -f $KUBECTL_FILENAME ]]; then
    rm -f $KUBECTL_FILENAME || true
  fi
  if [[ -f $CLUSTERCTL_FILENAME ]]; then
    rm -f $CLUSTERCTL_FILENAME || true
  fi
  if [[ -f $CLUSTER_AWS_ADM ]]; then
    rm -f $CLUSTER_AWS_ADM || true
  fi
}

output_variables() {
  echo "***************************************************"
  echo "cluster_name - ${cluster_name}"
  echo "region - ${region}"
  echo "clusterctl_version - ${clusterctl_version}"
  echo "clusterawsadm_version - ${clusterawsadm_version}"
  echo "***************************************************"
}



export CAPA_EKS_ADD_ROLES=true
export CAPA_EKS_IAM=true
export CLUSTER_TOPOLOGY=true
export EXP_CLUSTER_RESOURCE_SET=true
export EXP_EKS=true
export EXP_EKS_ADD_ROLES=true
export EXP_EKS_IAM=true
export EXP_MACHINE_POOL=true
export EKS_CONFIG_LOCATION="/tmp/eks.config"
export KUBECTL_FILENAME="kubectl"
export CLUSTERCTL_FILENAME="clusterctl"
export CLUSTER_AWS_ADM="clusterawsadm"
 

download_file_based_checkOS $OSTYPE
generateEKSConfig
initializaCAPI
cleanup
output_variables