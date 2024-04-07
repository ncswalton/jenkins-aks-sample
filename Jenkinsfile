pipeline {
    agent any
    stages {
        stage('Build Docker images') {
            steps {
                withCredentials ([string(credentialsId: 'acr-repo', variable: 'ACR_REPO')]) {
                    sh "docker build -t ${ACR_REPO}.azurecr.io/myapp-backend:latest ./backend"
                }
            }   
        }
        stage('Push Docker images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'acr-creds', usernameVariable: 'ACR_USERNAME', passwordVariable: 'ACR_PASSWORD'),
                                string(credentialsId: 'acr-repo', variable: 'ACR_REPO')]) {
                    script {
                        docker.withRegistry("https://${ACR_REPO}.azurecr.io", 'acr-creds') {
                            sh "docker push ${ACR_REPO}.azurecr.io/myapp-backend:latest"
                        }
                    }
                }
            }
        }
        stage('Deploy to AKS') {
            steps {
                withKubeConfig([credentialsId: 'kubeconfig']) {
                    sh 'curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.20.5/bin/linux/amd64/kubectl"'  
                    sh 'chmod u+x ./kubectl'
                    sh './kubectl apply -f ./frontend/kubernetes-deployment.yaml'
                    sh './kubectl apply -f ./backend/kubernetes-deployment.yaml'
                    sh './kubectl apply -f ./mongo/kubernetes-deployment.yaml'
                }
            }
        }
    }
}
