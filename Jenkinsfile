pipeline {
    agent any
    tools {
        nodejs '20.15.0'    
    }
    
    
    stages {
        stage('Checkout Git') {
            steps {
                echo 'Pulling From Git'
                git credentialsId: 'jenkins-personnal-token', url: 'https://github.com/ArijHabbechi/CrudProduct.git'
            }
        }
        stage('Build and Test Angular') {
            steps {
                dir('Angular') {
                    script {
                        sh 'npm install --force'
                        sh 'npm run build'
                    }
                }
            }
        }
    }
}

