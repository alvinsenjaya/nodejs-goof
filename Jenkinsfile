pipeline {
    agent none
    environment {
        DOCKERHUB_CREDENTIALS = credentials('DockerLogin')
        SNYK_CREDENTIALS = credentials('SnykToken')
        SONARQUBE_CREDENTIALS = credentials('SonarToken')
    }
    stages {
        stage('Secret Scanning Using Trufflehog'){
            agent {
                docker {
                    image 'trufflesecurity/trufflehog:latest'
                    args '--entrypoint='
                }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'trufflehog filesystem . --exclude-paths trufflehog-excluded-paths.txt --fail --json --no-update > trufflehog-scan-result.json'
                }
                sh 'cat trufflehog-scan-result.json'
                archiveArtifacts artifacts: 'trufflehog-scan-result.json'
            }
    	}
        stage('Build') {
            agent {
                docker {
                    image 'node:lts-buster-slim'
                }
            }
            steps {
                sh 'npm install'
            }
        }
        stage('SCA Snyk Test') {
            agent {
              docker {
                  image 'snyk/snyk:node'
                  args '-u root --network host --env SNYK_TOKEN=$SNYK_CREDENTIALS_PSW --entrypoint='
              }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'snyk test --json > snyk-scan-report.json'
                }
                sh 'cat snyk-scan-report.json'
                archiveArtifacts artifacts: 'snyk-scan-report.json'
            }
        }
        stage('SCA Retire Js') {
            agent {
              docker {
                  image 'node:lts-buster-slim'
              }
            }
            steps {
                sh 'npm install retire'
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh './node_modules/retire/lib/cli.js --outputformat json --outputpath retire-scan-report.json'
                }
                sh 'cat retire-scan-report.json'
                archiveArtifacts artifacts: 'retire-scan-report.json'
            }
        }
//        stage('SCA OWASP Dependency Check') {
//            agent {
//              docker {
//                  image 'owasp/dependency-check:latest'
//                  args '-u root -v /var/run/docker.sock:/var/run/docker.sock --entrypoint='
//              }
//            }
//            steps {
//                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
//                    sh '/usr/share/dependency-check/bin/dependency-check.sh --scan . --project "NodeJS Goof" --format ALL'
//                }
//                archiveArtifacts artifacts: 'dependency-check-report.html'
//                archiveArtifacts artifacts: 'dependency-check-report.json'
//                archiveArtifacts artifacts: 'dependency-check-report.xml'
//            }
//        }
        stage('SCA Trivy Scan Dockerfile Misconfiguration') {
            agent {
              docker {
                  image 'aquasec/trivy:latest'
                  args '-u root --network host --entrypoint='
              }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'trivy config Dockerfile --exit-code=1 --format json > trivy-scan-dockerfile-report.json'
                }
                sh 'cat trivy-scan-dockerfile-report.json'
                archiveArtifacts artifacts: 'trivy-scan-dockerfile-report.json'
            }
        }
        stage('SAST Snyk') {
            agent {
              docker {
                  image 'snyk/snyk:node'
                  args '-u root --network host --env SNYK_TOKEN=$SNYK_CREDENTIALS_PSW --entrypoint='
              }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'snyk code test --json > snyk-sast-report.json'
                }
                sh 'cat snyk-scan-report.json'
                archiveArtifacts artifacts: 'snyk-sast-report.json'
            }
        }
        stage('SAST SonarQube') {
            agent {
              docker {
                  image 'sonarsource/sonar-scanner-cli:latest'
                  args '--network host -v ".:/usr/src" --entrypoint='
              }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'sonar-scanner -Dsonar.projectKey=nodejs-goof -Dsonar.qualitygate.wait=true -Dsonar.sources=. -Dsonar.host.url=http://192.168.0.116:9000 -Dsonar.token=$SONARQUBE_CREDENTIALS_PSW' 
                }
            }
        }
        stage('Build Docker Image and Push to Docker Registry') {
            agent {
                docker {
                    image 'docker:dind'
                    args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'docker build -t xenjutsu/nodejsgoof:0.1 .'
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
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no ubuntu@192.168.0.117 "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no ubuntu@192.168.0.117 docker pull xenjutsu/nodejsgoof:0.1'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no ubuntu@192.168.0.117 docker rm --force mongodb'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no ubuntu@192.168.0.117 docker run --detach --name mongodb -p 27017:27017 mongo:3'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no ubuntu@192.168.0.117 docker rm --force nodejsgoof'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no ubuntu@192.168.0.117 docker run -it --detach --name nodejsgoof --network host xenjutsu/nodejsgoof:0.1'
                }
            }
        }
//        stage('DAST Nuclei') {
//            agent {
//                docker {
//                    image 'projectdiscovery/nuclei'
//                    args '--user root --network host --entrypoint='
//                }
//            }
//            steps {
//                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
//                    sh 'nuclei -u http://192.168.0.117:3001 -nc -j > nuclei-report.json'
//                    sh 'cat nuclei-report.json'
//                }
//                archiveArtifacts artifacts: 'nuclei-report.json'
//            }
//        }
        stage('DAST OWASP ZAP') {
            agent {
                docker {
                    image 'ghcr.io/zaproxy/zaproxy:stable'
                    args '-u root --network host -v /var/run/docker.sock:/var/run/docker.sock --entrypoint= -v .:/zap/wrk/:rw'
                }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'zap-baseline.py -t http://192.168.0.117:3001 -r zapbaseline.html -x zapbaseline.xml'
                }
                sh 'cp /zap/wrk/zapbaseline.html ./zapbaseline.html'
                sh 'cp /zap/wrk/zapbaseline.xml ./zapbaseline.xml'
                archiveArtifacts artifacts: 'zapbaseline.html'
                archiveArtifacts artifacts: 'zapbaseline.xml'
            }
        }
        stage('DAST Dastardly') {
            agent {
                docker {
                    image 'public.ecr.aws/portswigger/dastardly:latest'
                    args '-u root --network host -v /var/run/docker.sock:/var/run/docker.sock --entrypoint= -v .:/dastardly/:rw --env BURP_START_URL="http://192.168.0.117:3001" --env BURP_REPORT_FILE_PATH="/dastardly/dastardly-report.xml"'
                }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh '/usr/local/burpsuite_enterprise/bin/dastardly'
                }
                sh 'cp /dastardly/dastardly-report.xml ./dastardly-report.xml'
                archiveArtifacts artifacts: 'dastardly-report.xml'
            }
        }
    }
    post {
        always {
            node('built-in') {
                sh 'curl -X POST http://192.168.0.106:8080/api/v2/import-scan/ -H "Authorization: Token a49ba6566e3073f7d78b7d3f7c2136b750d8fb25" -F "scan_type=Trufflehog Scan" -F "file=@./trufflehog-scan-result.json;type=application/json" -F "engagement=3"'
                sh 'curl -X POST http://192.168.0.106:8080/api/v2/import-scan/ -H "Authorization: Token a49ba6566e3073f7d78b7d3f7c2136b750d8fb25" -F "scan_type=Snyk Code Scan" -F "file=@./snyk-sast-report.json;type=application/json" -F "engagement=3"'
                sh 'curl -X POST http://192.168.0.106:8080/api/v2/import-scan/ -H "Authorization: Token a49ba6566e3073f7d78b7d3f7c2136b750d8fb25" -F "scan_type=ZAP Scan" -F "file=@./zapbaseline.xml;type=text/xml" -F "engagement=3"'
            }
        }
    }
}
