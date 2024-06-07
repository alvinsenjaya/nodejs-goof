pipeline {
    agent none
    environment {
        DOCKERHUB_CREDENTIALS = credentials('DockerLogin')
    }
    stages {
        stage('Secret Scanning Using Trufflehog') {
            agent {
                docker {
                    image 'trufflesecurity/trufflehog:latest'
                    args '--user root --entrypoint='
                }
            }
            steps {
                // catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'trufflehog filesystem . --exclude-paths trufflehog-excluded-paths.txt --fail --json > trufflehog-scan-result.json'
                // }
                sh 'cat trufflehog-scan-result.json'
                archiveArtifacts artifacts: 'trufflehog-scan-result.json'
            }
        }
        stage('Build Docker Image') {
            agent {
                docker {
                    image 'docker:dind'
                    args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'docker build -t xenjutsu/nodejsgoof:0.1 .'
            }
        }
        stage('Push Image to Docker Registry') {
            agent {
                docker {
                    image 'docker:dind'
                    args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh 'docker push xenjutsu/nodejsgoof:0.1'
            }
        }
        stage('Deploy Docker Image') {
            agent {
                docker {
                    image 'kroniak/ssh-client'
                    args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: "DeploymentSSHKey", keyFileVariable: 'keyfile')]) {
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no root@119.81.54.27 "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no root@119.81.54.27 docker pull xenjutsu/nodejsgoof:0.1'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no root@119.81.54.27 docker rm --force mongodb'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no root@119.81.54.27 docker run --detach --name mongodb -p 27017:27017 mongo:3'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no root@119.81.54.27 docker rm --force nodejsgoof'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no root@119.81.54.27 docker run -it --detach -p 3001:3001 --name nodejsgoof --network host xenjutsu/nodejsgoof:0.1'
                }
            }
        }
    }
}
