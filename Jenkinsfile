pipeline {
    agent any
    stages {
        stage('Build Docker images') {
            steps {
                sh 'docker build -t myregistry.azurecr.io/myapp-backend:latest ./backend'
            }
        }

        stage('Push Docker images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'acr-creds', usernameVariable: 'ACR_USERNAME', passwordVariable: 'ACR_PASSWORD')]) {
                    script {
                        docker.withRegistry('https://myregistry.azurecr.io', 'acr-creds') {
                            sh 'docker push myregistry.azurecr.io/myapp-frontend:latest'
                            sh 'docker push myregistry.azurecr.io/myapp-backend:latest'
                        }
                    }
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