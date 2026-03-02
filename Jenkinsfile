pipeline {
    agent any

    tools {
        terraform 'terraform'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 60, unit: 'MINUTES')
    }

    parameters {
        string(name: 'ACR_NAME', defaultValue: 'prodacr12345')
        string(name: 'RESOURCE_GROUP', defaultValue: 'prod-rg')
        string(name: 'CLUSTER_NAME', defaultValue: 'prod-aks')
        string(name: 'IMAGE_NAME', defaultValue: 'myapp')
        booleanParam(name: 'AUTO_APPROVE_TERRAFORM', defaultValue: false)
    }

    environment {
        ARM_CLIENT_ID       = credentials('azure-client-id')
        ARM_CLIENT_SECRET   = credentials('azure-client-secret')
        ARM_TENANT_ID       = credentials('azure-tenant-id')
        ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
    }

    stages {

        stage('Validate Tools') {
            steps {
                bat 'terraform -version'
                bat 'az version'
                bat 'docker --version'
                bat 'helm version'
                bat 'kubectl version --client'
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                dir('infra') {
                    bat 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('infra') {
                    bat """
                    terraform plan -out=tfplan ^
                      -var="acr_name=${params.ACR_NAME}" ^
                      -var="rg_name=${params.RESOURCE_GROUP}" ^
                      -var="cluster_name=${params.CLUSTER_NAME}" ^
                      -var-file=../environments/prod.tfvars
                    """
                }
            }
        }

        stage('Manual Approval') {
            when {
                expression { !params.AUTO_APPROVE_TERRAFORM }
            }
            steps {
                input message: 'Approve Terraform Apply?', ok: 'Apply'
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('infra') {
                    bat 'terraform apply tfplan'
                }
            }
        }

        stage('Azure Login') {
            steps {
                retry(3) {
                    bat """
                    az login --service-principal ^
                      -u %ARM_CLIENT_ID% ^
                      -p %ARM_CLIENT_SECRET% ^
                      --tenant %ARM_TENANT_ID%

                    az account set --subscription %ARM_SUBSCRIPTION_ID%
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                bat "docker build -t ${params.IMAGE_NAME}:latest .\\app"
            }
        }

        stage('Push Image to ACR') {
            steps {
                bat "az acr login --name ${params.ACR_NAME}"
                bat "docker tag ${params.IMAGE_NAME}:latest ${params.ACR_NAME}.azurecr.io/${params.IMAGE_NAME}:latest"
                bat "docker push ${params.ACR_NAME}.azurecr.io/${params.IMAGE_NAME}:latest"
            }
        }

        stage('Get AKS Credentials') {
            steps {
                bat """
                az aks get-credentials ^
                  --resource-group ${params.RESOURCE_GROUP} ^
                  --name ${params.CLUSTER_NAME} ^
                  --overwrite-existing
                """
            }
        }

        stage('Deploy Helm Chart') {
            steps {
                bat """
                helm upgrade --install myapp helm/myapp ^
                  --set image.repository=${params.ACR_NAME}.azurecr.io/${params.IMAGE_NAME} ^
                  --set image.tag=latest ^
                  --wait --timeout 5m
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                bat 'kubectl rollout status deployment/myapp'
            }
        }
    }

    post {
        success {
            echo 'AKS deployment successful 🚀'
        }
        failure {
            echo 'Deployment failed ❌'
        }
        always {
            cleanWs()
        }
    }
}
