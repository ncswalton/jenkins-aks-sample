pipeline {
    agent any

    stages {
        stage('Build Docker images') {
            steps {
                sh 'docker build -t myregistry.azurecr.io/myapp-frontend:latest ./frontend'
                sh 'docker build -t myregistry.azurecr.io/myapp-backend:latest ./backend'
            }
        }

        stage('Push Docker images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'acrCredentials', usernameVariable: 'ACR_USERNAME', passwordVariable: 'ACR_PASSWORD')]) {
                    docker.withRegistry('https://myregistry.azurecr.io', 'acrCredentials') {
                        sh 'docker push myregistry.azurecr.io/myapp-frontend:latest'
                        sh 'docker push myregistry.azurecr.io/myapp-backend:latest'
                }
            }
        }

        stage('Deploy to AKS') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh 'kubectl apply -f ./frontend/kubernetes-deployment.yaml'
                    sh 'kubectl apply -f ./backend/kubernetes-deployment.yaml'
                    sh 'kubectl apply -f ./mongo/kubernetes-deployment.yaml'
                }
            }
        }
    }
}