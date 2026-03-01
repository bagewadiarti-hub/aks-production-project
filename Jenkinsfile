pipeline {
agent any

parameters {
    string(name: 'ACR_NAME', defaultValue: 'prodacr12345', description: 'Azure Container Registry Name')
    string(name: 'RESOURCE_GROUP', defaultValue: 'prod-rg', description: 'Azure Resource Group')
    string(name: 'AKS_NAME', defaultValue: 'prod-aks', description: 'AKS Cluster Name')
    string(name: 'IMAGE_NAME', defaultValue: 'myapp', description: 'Docker Image Name')
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
                bat '''
                terraform plan ^
                  -var="acr_name=%ACR_NAME%" ^
                  -var="rg_name=%RESOURCE_GROUP%" ^
                  -var="aks_name=%AKS_NAME%" ^
                  -var-file=../environments/prod.tfvars
                '''
            }
        }
    }

    stage('Terraform Apply') {
        steps {
            dir('infra') {
                bat '''
                terraform apply -auto-approve ^
                  -var="acr_name=%ACR_NAME%" ^
                  -var="rg_name=%RESOURCE_GROUP%" ^
                  -var="aks_name=%AKS_NAME%" ^
                  -var-file=../environments/prod.tfvars
                '''
            }
        }
    }

    stage('Azure Login') {
        steps {
            bat '''
            az login --service-principal ^
              -u %ARM_CLIENT_ID% ^
              -p %ARM_CLIENT_SECRET% ^
              --tenant %ARM_TENANT_ID%
            '''
        }
    }

    stage('Build Docker Image') {
        steps {
            bat 'docker build -t %IMAGE_NAME%:latest app'
        }
    }

    stage('Push Image to ACR') {
        steps {
            bat '''
            az acr login --name %ACR_NAME%
            docker tag %IMAGE_NAME%:latest %ACR_NAME%.azurecr.io/%IMAGE_NAME%:latest
            docker push %ACR_NAME%.azurecr.io/%IMAGE_NAME%:latest
            '''
        }
    }

    stage('Get AKS Credentials') {
        steps {
            bat '''
            az aks get-credentials ^
              --resource-group %RESOURCE_GROUP% ^
              --name %AKS_NAME% ^
              --overwrite-existing
            '''
        }
    }

    stage('Deploy Helm Chart') {
        steps {
            bat '''
            helm upgrade --install myapp helm/myapp ^
              --set image.repository=%ACR_NAME%.azurecr.io/%IMAGE_NAME% ^
              --set image.tag=latest
            '''
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
}
```

}
