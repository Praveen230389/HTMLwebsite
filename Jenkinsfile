// Jenkinsfile (Declarative pipeline)
pipeline {
  agent any

  environment {
    // Adjust to your SonarQube and Docker Registry setup
    SONAR_HOST_URL    = 'http://localhost:9000'
    SONAR_AUTH_TOKEN  = credentials('sonar-token')        // Jenkins credential ID for Sonar auth token
    DOCKER_REGISTRY   = 'mydockerhubuser/html-site'       // e.g. DockerHub repo
    REGISTRY_CREDENTIALS = 'dockerhub-credentials'        // Jenkins credential ID for registry user/pass
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('My SonarQube') {
          // Assumes you have a SonarQube Scanner configured in Jenkins
          sh "sonar-scanner \
              -Dsonar.projectKey=html-site \
              -Dsonar.host.url=${env.SONAR_HOST_URL} \
              -Dsonar.login=${env.SONAR_AUTH_TOKEN}"
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          IMAGE_TAG = "${DOCKER_REGISTRY}:${env.BUILD_NUMBER}"
        }
        sh "docker build -t ${IMAGE_TAG} ."
      }
    }

    stage('Push to Registry') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${REGISTRY_CREDENTIALS}",
                                         usernameVariable: 'REG_USER',
                                         passwordVariable: 'REG_PASS')]) {
          sh '''
            echo "$REG_PASS" | docker login -u "$REG_USER" --password-stdin
            docker push ${IMAGE_TAG}
          '''
        }
      }
    }

    stage('Deploy to EC2 Instances') {
      steps {
        script {
          // List your three instance hostnames or IPs here:
          def servers = [
            'ec2-54-11-22-33.compute-1.amazonaws.com',
            'ec2-54-44-55-66.compute-1.amazonaws.com',
            'ec2-54-77-88-99.compute-1.amazonaws.com'
          ]

          // Run the deploy step in parallel to all three
          def deploySteps = servers.collectEntries { server ->
            ["Deploy to ${server}" : {
               sh """
                 ssh -o StrictHostKeyChecking=no ec2-user@${server} \\
                   'docker pull ${IMAGE_TAG} && \\
                    docker stop html-site || true && \\
                    docker rm html-site || true && \\
                    docker run -d --name html-site -p 80:80 ${IMAGE_TAG}'
               """
            }]
          }
          parallel deploySteps
        }
      }
    }
  }

  post {
    always {
      // Optional: clean up workspace or send notifications
      cleanWs()
    }
  }
}
