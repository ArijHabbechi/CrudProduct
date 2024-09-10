pipeline {
    agent any
    environment {
        SONAR_HOST_URL = 'http://192.168.116.137:9000'
        DOCKER_IMAGE = 'arijhabbechi/spring-springapp:latest'
        MYSQL_CONTAINER_NAME = 'mysql-test'
        MYSQL_ROOT_PASSWORD = 'rootpassword'
        MYSQL_DATABASE = 'mydatabase'
        MYSQL_USER = 'jenkins'
        MYSQL_PASSWORD = 'rootpassword'
    }

    tools {
        maven '3.9.8'
    }

    stages {
        stage('Checkout Git') {
            steps {
                echo 'Pulling From Git'
                git branch: 'main', credentialsId: 'jenkins-personnal-token', url: 'https://github.com/ArijHabbechi/CrudProduct.git'
            }
        }

        stage('Start Database') {
            steps {
                script {
                    sh "docker run --name ${MYSQL_CONTAINER_NAME} -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} -e MYSQL_DATABASE=${MYSQL_DATABASE} -e MYSQL_USER=${MYSQL_USER} -e MYSQL_PASSWORD=${MYSQL_PASSWORD} -p 3306:3306 -d mysql:5.7"
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

        stage('Unit Tests') {
            steps {
                dir('Spring') {
                    sh "mvn test"  // Runs Surefire tests (unit tests)
                }
            }
            post {
                always {
                    junit 'Spring/target/surefire-reports/*.xml' 
                }
            }
        }

        stage('SonarQube test – SAST') {
            steps {
                withCredentials([string(credentialsId: 'Jenkins-auth', variable: 'SONAR_TOKEN')]) {
                    dir('Spring') {
                        withSonarQubeEnv('SonarQube') {
                            sh """
                                mvn clean verify sonar:sonar \
                                -Dsonar.projectKey=SpringBootApp \
                                -Dsonar.projectName='SpringBootApp' \
                                -Dsonar.host.url=${SONAR_HOST_URL} \
                                -Dsonar.token=${SONAR_TOKEN}
                            """
                        }
                        timeout(time: 2, unit: 'MINUTES') {
                            script {
                                waitForQualityGate abortPipeline: false
                            }
                        }
                    }
                }
            }
        }

        stage('Vulnerability tests') {
            steps {
                dir('Spring') {
                    sh "mvn dependency-check:check"
                }
            }
            post {
                always {
                    dependencyCheckPublisher pattern: 'Spring/target/dependency-check-report.xml'
                }
            }
        }

        stage('Vulnerability Scans ') {
            parallel {
                stage('Run Trivy Scan') {
                    steps {
                        script {
                            echo 'Running Trivy Scan'
                            sh './trivy-docker-scan.sh'
                        }
                    }
                }

                stage('OPA Scan') {
                    steps {
                        script {
                            echo 'Running OPA Scan'
                            sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker.rego Spring/Dockerfile'
                        }
                    }
                }

                stage('OWASP ZAP test - DAST') {
                    steps {
                        script {
                            echo 'Running OWASP ZAP Scan'
                            sh './zap_scan.sh'
                        }
                    }
                }
            }
        }

        stage('Remove Test Database') {
            steps {
                script {
                    sh "docker stop ${MYSQL_CONTAINER_NAME} && docker rm ${MYSQL_CONTAINER_NAME}"
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                dir('Spring') {
                    echo 'Building and Running Docker Image'
                    sh 'docker compose up -d --build'

                    script {
                        withCredentials([string(credentialsId: 'jenkins-docker-auth', variable: 'DOCKERHUB_TOKEN')]) {
                            // Tag the Docker image
                            sh "docker tag spring-springapp:latest ${DOCKER_IMAGE}"
                            // Push the Docker image to Docker Hub
                            sh "docker push ${DOCKER_IMAGE}"
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Archiving and publishing reports'

            // Publish Trivy, OPA, and OWASP ZAP reports
            archiveArtifacts artifacts: "*-trivy-report.html", allowEmptyArchive: false
            archiveArtifacts artifacts: 'zap_report.html', allowEmptyArchive: false

            publishHTML(target: [
                allowMissing: false,
                keepAll: true,
                reportDir: '.',
                reportFiles: '*-trivy-report.html',
                reportName: 'Trivy Vulnerability Report'
            ])

            publishHTML(target: [
                allowMissing: false,
                keepAll: true,
                reportDir: '.',
                reportFiles: 'zap_report.html',
                reportName: 'OWASP ZAP Report'
            ])

            // Publish status checks
            publishChecks name: 'Tests', summary: 'Test results', detailsURL: env.BUILD_URL

            // Clean up the workspace
            cleanWs()
        }

        failure {
            echo 'Pipeline failed. Check the logs for more details.'
        }
    }
}
