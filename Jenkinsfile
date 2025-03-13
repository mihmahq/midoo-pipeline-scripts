pipeline {
    agent any

    parameters {
        string(name: 'COMPANY_NAME', description: 'Enter the company name', defaultValue: 'Gloxon Empire')
        string(name: 'EMAIL_ADDRESS', description: 'Enter the email address', defaultValue: 'gloxonempire@gmail.com')
        choice(name: "COUNTRY", choices: ['cm', 'ng', 'us'], description: 'Select the country')
    }

    environment {
        PATH = "/home/linuxbrew/.linuxbrew/bin:${env.PATH}"
        GIT_REPO_URL = 'https://github.com/mihmahq/midoo-pipeline-scripts.git'
        GIT_CREDENTIALS_ID = 'github-access-token'
        STAGE = 0
        DB_NAME = ''
        HCLOUD_TOKEN = credentials('hcloud-token')
        HCLOUD_IMAGE_ID = 67794396  // ubuntu 22.04
        HCLOUD_DATACENTER = 'fsn1-dc14'
        MIDOO_PRIVATE_NETWORK = 'midoo-net'
        JENKINS_SSH_KEY_NAME = 'jenkins'
        ADMIN_SSH_KEY_NAME = 'kinason'
        HCLOUD_SERVER_TYPE = 'cx22'
    }

    stages{
        stage ("Git Init") {
            steps {
                script {
                    echo "Cloning repository from ${env.GIT_REPO_URL}"
                    git branch: 'main', credentialsId: env.GIT_CREDENTIALS_ID, url: env.GIT_REPO_URL
                    updateStageInFile(1)
                }
            }
        }

        stage ("Setup") {
            steps {
                sh "export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin"
            }
        }

        stage('Create Server') {
            steps {
                script {
                    echo "Creating server for ${params.COMPANY_NAME} in ${params.COUNTRY}"
                    updateStageInFile(2)
                    generateDatabaseName()
                    def serverName = getServerName()

                    def createServerOutput = sh(script: """
                        hcloud server create \
                            --image ${env.HCLOUD_IMAGE_ID} \
                            --name ${serverName} \
                            --type ${env.HCLOUD_SERVER_TYPE} \
                            --datacenter ${env.HCLOUD_DATACENTER} \
                            --network ${env.MIDOO_PRIVATE_NETWORK} \
                            --ssh-key ${env.ADMIN_SSH_KEY_NAME} \
                            --ssh-key ${env.JENKINS_SSH_KEY_NAME} \
                            --output json
                    """, returnStdout: true).trim()

                    def jsonResponse = readJSON text: createServerOutput
                    def serverStatus = jsonResponse.server.status

                    if (serverStatus == 'running') {
                        echo "Server is running! Proceeding to midoo installation..."
                    } else {
                        error "Server is not running. Status: ${serverStatus}"
                    }
                }
            }
        }

        stage ("Install Midoo") {
            steps {
                script {
                    echo "Installing Midoo on the server"
                    updateStageInFile(3)
                    def serverName = getServerName()
                    def dbName = getDatabaseName()
                    def serverIP = sh(script: "hcloud server ip ${serverName}", returnStdout: true).trim()

                    echo "Server IP is: ${serverIP}"

                    sh 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'

                    echo "Waiting for SSH to be ready on ${serverIP}"
                    sh """
                        timeout 60 bash -c "until nc -zv ${serverIP} 22; do echo 'Waiting for port 22...'; sleep 2; done" || \
                        { echo 'Timeout waiting for SSH'; exit 1; }
                    """

                    sh "ssh-keygen -R ${serverIP} > /dev/null 2>&1 || true"
                    sh "ssh-keyscan -H ${serverIP} >> ~/.ssh/known_hosts || { echo 'ssh-keyscan failed'; exit 1; }"
                    sh "chmod 600 ~/.ssh/known_hosts"
                    sh "scp -r scripts/ *.sh root@${serverIP}:/root/ || { echo 'SCP failed'; exit 1; }"

                    withCredentials([
                        string(credentialsId: 'db-host', variable: 'DB_HOST'),
                        string(credentialsId: 'db-port', variable: 'DB_PORT'),
                        string(credentialsId: 'db-user', variable: 'DB_USER'),
                        string(credentialsId: 'db-password', variable: 'DB_PASSWORD'),
                        string(credentialsId: 'db-password', variable: 'ADMIN_PASSWORD')
                    ]) {

                        sh """
                            ssh -o BatchMode=yes root@${serverIP} \
                                "bash /root/main.sh \$DB_HOST \$DB_PORT \$DB_USER \$DB_PASSWORD \$ADMIN_PASSWORD ${dbName}" || \
                            { echo 'Remote script execution failed'; exit 1; }
                        """
                    }

                    sh """
                        ssh -o BatchMode=yes root@${serverIP} 'bash /root/refresh-addons.sh || { echo 'Remote sync custom addons script execution failed'; exit 1; }
                    """
                }
            }
        }

        stage("Create Login Credentials") {
            steps {
                script {
                     echo "Creating login credentials using ${params.EMAIL_ADDRESS}"
                     updateStageInFile(4)

                }
            }
        }

        stage("Send Login Credentials") {
            steps {
                script {
                    echo "Sending login credentials to ${params.EMAIL_ADDRESS}"
                    updateStageInFile(5)
                }
            }
        }

        stage("Call Backend API") {
            steps {
                script {
                     echo "Calling backend API to register ${params.COMPANY_NAME}"
                     updateStageInFile(6)

                }
            }
        }
    }


    post {
        success {
            echo "Pipeline completed successfully!"
            cleanWs()
        }
        failure {
            echo "Pipeline failed. Please check the logs for details."
            script {
                def current_stage = getCurrentStage()
                if (current_stage > 1) {
                    echo "Rolling back, destroying the server and deleting database"
                    destroyServer()
                    deleteDatabase()
                }
            }

            cleanWs()

        }
    }
}

def generateDatabaseName() {
    def companyName = "${params.COMPANY_NAME}".replaceAll(/[^a-zA-Z0-9]/, '').toLowerCase();

    if (companyName.length() > 8) {
        companyName = companyName.take(8);
    }
    def uuidPart = UUID.randomUUID().toString().split('-')[-1]

    writeFile file: 'db_name.txt', text: "${companyName}_${uuidPart}"
}

def getDatabaseName() {
     try {
        return readFile('db_name.txt').trim()
    } catch (Exception e) {
        return 1
    }
}

def getServerName() {
    def dbName = readFile('db_name.txt').trim()
    def uuidPart = dbName.split('_')[1];
    def firstHalf = uuidPart[0..3];
    def secondHalf = uuidPart[4..7];
    def reversedUUIDPart = secondHalf+firstHalf;

    return "${dbName.split('_')[0]}-${reversedUUIDPart}"
}

def destroyServer() {
    echo "Destroying orphan server"
    def currentStage = getCurrentStage()
    if (currentStage > 1) {
        def serverName = getServerName()
        sh "hcloud server delete ${serverName}"
    }
}
def deleteDatabase() {
    echo "Destroying orphan database"
}
def updateStageInFile(stage) {
    writeFile file: "stage.txt", text: stage.toString()
}
def getCurrentStage(){
    try {
        def stage = readFile('stage.txt').trim()
        return stage.toInteger()
    } catch (Exception e) {
        return 1
    }
}
