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

        stage('Remove Test Database') {
            steps {
                script {
                    sh 'docker stop mysql-test && docker rm mysql-test'
                }
            }
        }

        stage('Run Trivy Scan') {
            steps {
                script {
                    // Run the custom Trivy scan script
                    sh './trivy-docker-scan.sh'
                }
            }
        }

        stage('Opa Scan') {
            steps {
                script {
                    
                    sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker.rego Spring/Dockerfile'
                }
            }
        }

        stage('Archive Reports') {
            steps {
                // Archive the reports in Jenkins
                archiveArtifacts artifacts: "*-trivy-report.html", allowEmptyArchive: false
            }
        }

        stage('Publish HTML Report') {
            steps {
                // Publish the HTML report
                publishHTML(target: [
                    allowMissing: false,
                    keepAll: true,
                    reportDir: '.',
                    reportFiles: '*-trivy-report.html',
                    reportName: 'Trivy Vulnerability Report'
                ])
            }
        }


        stage('Build and Push Docker Image') {
            steps {
                dir('Spring') {
                    // Build the Docker image using Docker Compose
                    sh 'docker compose up -d --build'

                    // Push the Docker image to Docker Hub
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
    }

    post {
        always {
            publishChecks name: 'Tests', summary: 'Test results', detailsURL: env.BUILD_URL
        }
    }
}
