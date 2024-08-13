pipeline {
    agent any

    tools {
        maven '3.9.8'
    }

    stages {
        stage('Checkout Git') {
            steps {
                echo 'Pulling From Git'
                git credentialsId: 'jenkins-personnal-token', url: 'https://github.com/ArijHabbechi/CrudProduct.git'
            }
        }
        
        stage('Start Database') {
            steps {
                script {
                    sh 'docker run --name mysql-test -e MYSQL_ROOT_PASSWORD=rootpassword -e MYSQL_DATABASE=mydatabase -e MYSQL_USER=jenkins -e MYSQL_PASSWORD=rootpassword -p 3306:3306 -d mysql:5.7'
                }
            }
        }

        stage('Build Artifact') {
            steps {
                dir('Spring') {
                    sh "mvn clean package"
                    archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: true
                }
            }
        }
        
        stage('Test Maven – JUnit') {
            steps {
                dir('Spring') {
                    sh "mvn test"
                    sh "mvn surefire-report:report" 
                }
            }
            post {
                always {
                    junit 'Spring/target/surefire-reports/*.xml'  
                    archiveArtifacts artifacts: 'Spring/target/site/surefire-report.html', allowEmptyArchive: true
                }
            }
        }

        stage('SonarQube test – SAST') {
            steps {
                withCredentials([string(credentialsId: 'Jenkins-auth', variable: 'SONAR_TOKEN')]) { 
                    dir('Spring') {
                        sh "mvn clean verify sonar:sonar \
                            -Dsonar.projectKey=SpringBootApp \
                            -Dsonar.projectName='SpringBootApp' \
                            -Dsonar.host.url=http://192.168.116.134:9000 \
                            -Dsonar.token=${SONAR_TOKEN}"
                    }
                }

            }
        }



    }

    post {
        always {
            script {
                sh 'docker stop mysql-test && docker rm mysql-test'
            }
        }
    }
}

