pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    parameters {
        string(name: 'ACR_NAME', defaultValue: 'prodacr12345', description: 'Azure Container Registry name')
        string(name: 'RESOURCE_GROUP', defaultValue: 'prod-rg', description: 'Azure Resource Group')
        string(name: 'CLUSTER_NAME', defaultValue: 'prod-aks', description: 'AKS Cluster Name')
        string(name: 'IMAGE_NAME', defaultValue: 'myapp', description: 'Docker image name')
        booleanParam(name: 'AUTO_APPROVE_TERRAFORM', defaultValue: false, description: 'Skip manual approval for Terraform apply')
    }

    environment {
        ARM_CLIENT_ID       = credentials('azure-client-id')
        ARM_CLIENT_SECRET   = credentials('azure-client-secret')
        ARM_TENANT_ID       = credentials('azure-tenant-id')
        ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
    }

    stages {

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
                    terraform plan ^
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
                expression { return !params.AUTO_APPROVE_TERRAFORM }
            }
            steps {
                input message: 'Approve Terraform Apply?', ok: 'Apply'
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('infra') {
                    bat """
                    terraform apply -auto-approve ^
                      -var="acr_name=${params.ACR_NAME}" ^
                      -var="rg_name=${params.RESOURCE_GROUP}" ^
                      -var="cluster_name=${params.CLUSTER_NAME}" ^
                      -var-file=../environments/prod.tfvars
                    """
                }
            }
        }

        stage('Azure Login') {
            steps {
                bat """
                az login --service-principal ^
                  -u %ARM_CLIENT_ID% ^
                  -p %ARM_CLIENT_SECRET% ^
                  --tenant %ARM_TENANT_ID%
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                bat "docker build -t ${params.IMAGE_NAME}:latest app"
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
                  --set image.tag=latest
                """
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
