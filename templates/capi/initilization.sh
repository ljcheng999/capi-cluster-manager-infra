#/!/bin/bash

function download_file_based_checkOS () {
  case "$1" in
    darwin*)
      curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/$(uname -m)/kubectl"
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
      curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$(uname -m)/kubectl"
      chmod +x ./kubectl
      ./kubectl version --client

      curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/${clusterctl_version}/clusterctl-linux-$(uname -m) -o clusterctl
      chmod +x ./clusterctl
      ./clusterctl version

      curl -L https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/${clusterawsadm_version}/clusterawsadm-linux-$(uname -m) -o clusterawsadm
      chmod +x ./clusterawsadm
      ./clusterawsadm version
      ;;

    *)
      echo "Error - unknown OS: $OSTYPE"
      echo "Quit"
      exit 1
      ;;
  esac
}

download_file_based_checkOS $OSTYPE

cat << EOF > $PWD/eks.config
---
apiVersion: bootstrap.aws.infrastructure.cluster.x-k8s.io/v1alpha1
kind: AWSIAMConfiguration
spec:
  region: ${region}
  bootstrapUser:
    enable: true
  eks:
    enable: true
    defaultControlPlaneRole:
      disable: false # Set to false to enable creation of the default control plane role
    eventBridge:
      enable: true
    fargate:
      disable: false
    iamRoleCreation: false # Set to true if you plan to use the EKSEnableIAM feature flag to enable automatic creation of IAM roles
    managedMachinePool:
      disable: false
EOF


 
export CAPA_EKS_ADD_ROLES=true
export CAPA_EKS_IAM=true
export CLUSTER_TOPOLOGY=true
export EXP_CLUSTER_RESOURCE_SET=true
export EXP_EKS=true
export EXP_EKS_ADD_ROLES=true
export EXP_EKS_IAM=true
export EXP_MACHINE_POOL=true
export EKS_CONFIG_LOCATION="$PWD/eks.config"
export KUBECTL_FILENAME="kubectl"
export CLUSTERCTL_FILENAME="clusterctl"
export CLUSTER_AWS_ADM="clusterawsadm"
 
./clusterawsadm bootstrap iam create-cloudformation-stack --config $EKS_CONFIG_LOCATION
 
export AWS_B64ENCODED_CREDENTIALS="$(./clusterawsadm bootstrap credentials encode-as-profile)"
aws eks update-kubeconfig --name ${cluster_name} --region ${region}


./clusterctl init --infrastructure ${cloud_provider} || ./clusterctl upgrade apply \
 
if [[ -f $EKS_CONFIG_LOCATION ]]; then
  rm $EKS_CONFIG_LOCATION || true
fi
if [[ -f $KUBECTL_FILENAME ]]; then
  rm $KUBECTL_FILENAME || true
fi
if [[ -f $CLUSTERCTL_FILENAME ]]; then
  rm $CLUSTERCTL_FILENAME || true
fi
if [[ -f $CLUSTER_AWS_ADM ]]; then
  rm $CLUSTER_AWS_ADM || true
fi



# until kubectl apply -k https://github.com/christianh814/argocd-capi-demo/bootstrap/install/; do sleep 3; done