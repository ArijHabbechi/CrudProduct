pipeline {
    agent any

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
                        withSonarQubeEnv('SonarQube') {
                            sh """
                                mvn clean verify sonar:sonar \
                                -Dsonar.projectKey=SpringBootApp \
                                -Dsonar.projectName='SpringBootApp' \
                                -Dsonar.host.url=http://192.168.116.137:9000 \
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

        stage('Run Trivy Scan') {
            steps {
                script {
                    echo 'Running Trivy Scan'
                    sh './trivy-docker-scan.sh'
                }
            }
        }

        stage('Opa Scan') {
            steps {
                script {
                    echo 'Running OPA Scan'
                    sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker.rego Spring/Dockerfile'
                }
            }
        }

        stage('Remove Test Database') {
            steps {
                script {
                    sh 'docker stop mysql-test && docker rm mysql-test'
                }
            }
        }

        // Build Docker image after tests
        stage('Build and Push Docker Image') {
            steps {
                dir('Spring') {
                    echo 'Building and Running Docker Image'
                    sh 'docker compose up -d --build'

                    script {
                        withCredentials([string(credentialsId: 'jenkins-docker-auth', variable: 'DOCKERHUB_TOKEN')]) {
                            // Tag the Docker image
                            sh 'docker tag spring-springapp:latest arijhabbechi/spring-springapp:latest'
                            // Push the Docker image to Docker Hub
                            sh 'docker push arijhabbechi/spring-springapp:latest'
                        }
                    }
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
