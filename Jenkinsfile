#!/usr/bin/env groovy

def ARCHIVA_HOST = 'archiva.org'
def DOCKER_REGISTRY = "hub.docker.com"
// env.X lets us access our ENV variables
def DOCKER_IMAGE_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}".replaceAll("/", "-")
def MVN_HOME = "/path/to/the/maven/installation"
// set the build description so it shows up on the Jenkins UI of each build
currentBuild.description = "#${env.BUILD_NUMBER} - origin/${env.BRANCH_NAME}"
// remove any slashes in the branch name as these can be error prone
JOB_NAME = "${env.BRANCH_NAME}".replaceAll("/", "-")

MY_FILE = "/path/to/myfile.txt"

// get the project version so we can re-use this to point to a specific artifact version in the rest of the script
def getProjectVersion() {
    // Pipeline Utility Steps plugin must be installed for 'readMavenPom' to work
    pom = readMavenPom file: "pom.xml"
    return pom.version
}

// A node is a step that schedules a task to run by adding it to the Jenkins build queue
// As soon as an executor slot is available on a node (the Jenkins master, or agent), the task is run on that node
// A node also allocates a workspace (file directory) on that node for the duration of the task
node ('linux') {

    properties(
            [
                    // limits the concurrency per branch built.
                    // Does not limit the concurrency of branches being built. Use 'lock' for this functionality
                    disableConcurrentBuilds(),
                    buildDiscarder(logRotator(numToKeepStr: '50'))
            ]
    )

    try {
        // stage is the logical separation of pipeline into segments of work
        stage('Checkout') {
            timeout(time: 30, unit: 'MINUTES') {
                // this will recursively delete the entire contents of the Jenkins workspace
                deleteDir()
                // use this format if you want to do a pre build merge
                // build will fail immediately if there are merge conflicts with the target branch
                checkout changelog: true, poll: true, scm:
                        [
                                $class: 'GitSCM',
                                branches:
                                        [
                                                [name: "origin/${env.BRANCH_NAME}"]
                                        ],
                                doGenerateSubmoduleConfigurations: false,
                                extensions:
                                        [
                                                [$class: 'PreBuildMerge',
                                                 options:
                                                         [
                                                                 fastForwardMode: 'FF',
                                                                 mergeStrategy: 'default',
                                                                 mergeRemote: 'origin',
                                                                 mergeTarget: 'master'
                                                         ]
                                                ]
                                        ],
                                submoduleCfg: [],
                                userRemoteConfigs:
                                        [
                                                [url: 'ssh://git@git.joey.com:1234/home/jenkins-pipelines.git']
                                        ]
                        ]
            }
        }

        stage ('Scm checkout and Maven Build') {
            // give a timeout of to the phase to ensure proper cleanup (aborted) within the given window
            timeout(time: 30, unit: 'MINUTES') {
                checkout scm
                sh('''
            multi line shell commands can be written like this    
            ''')
                sh("$MVN_HOME/bin/mvn -B clean install")
                // prefer stashing files over archiving
                // Stash and unstash are designed for sharing files, for example your application’s source code, between stages and nodes.
                // Archives, on the other hand, are designed for longer term file storage (e.g., intermediate binaries from your builds).
                projectVersion = getProjectVersion()
                stash includes: 'some-web-app/target/some-web-app-' + projectVersion + '.war', name: 'some-web-app'
                stash includes: 'database-scripts/target/database-scripts-' + projectVersion + '.tar.gz', name: 'database-scripts'
            }
        }

        stage ('Create a python virtual env to execute python commands') {
            // give a timeout of to the phase to ensure proper cleanup (aborted) within the given window
            timeout(time: 30, unit: 'MINUTES') {
                sh('virtualenv -p python2.7 venv')
                sh('''
                . venv/bin/activate;
                pip install -r requirements.txt;
                pip freeze;
                do some python stuff here!
                ''')
            }
        }

        stage ('Use triple double quotes for vars inside sh blocks') {
            timeout(time: 30, unit: 'MINUTES') {

                sh("""
                cat myfile;
                cat ${MY_FILE};
                """)
            }
        }

        stage ('debug jenkins') {
            timeout(time: 30, unit: 'MINUTES') {
                // print all env variables
                sh("printenv")
                // print the branch from the webhook trigger of multibranch pipeline
                sh("echo '${env.BRANCH_NAME}'")
            }
        }

        /**
         * Do a merge back into the repo: Similar to traditional POST Build step of Automerge
         */
        stage("Automerge") {
            timeout(time: 30, unit: 'MINUTES') {
                sh("git push origin HEAD:master")
            }
        }

        /**
         * Use the lock to lock a stage or step.  This will prevent parallel building per branch in Multibranch pipelines.
         * Parallel executions can also take place per job run.
         *
         * A,B,C all run in parallel per job run, but while A is executing, a lock with be held, and if another branch
         * tries to run this A step, it will wait until the lock is released.
         *
         */
        stage("Deploy") {
            parallel (
                    'deploy_env_A' : {
                        lock("deploy_env_C_lock") {
                            timeout(time: 30, unit: 'MINUTES') {
                                sh('''
                            deploy some stuff on env A
                            ''')
                            }
                        }
                    },
                    'deploy_env_B' : {
                        lock("deploy_env_C_lock") {
                            timeout(time: 30, unit: 'MINUTES') {
                                sh('''
                            deploy some stuff on env B
                            ''')
                            }
                        }
                    },
                    'deploy_env_C' : {
                        lock("deploy_env_C_lock") {
                            timeout(time: 30, unit: 'MINUTES') {
                                sh('''
                            deploy some stuff on env C
                            ''')
                            }
                        }
                    }
            )
        }
    } catch (e) {
        // fail the build if any exception is thrown
        currentBuild.result = "FAILED"
        throw e
    } finally {
        // on success or fail, we always send notifications
        notifyBuild(currentBuild.result)
        step(
                [
                        $class           : 'JUnitResultArchiver',
                        allowEmptyResults: true,
                        healthScaleFactor: 1,
                        testResults      : 'junit-py27.xml'
                ]
        )
    }



}

node ('linux') {
    stage ('Push Docker Image To Docker Hub') {
        timeout(time: 30, unit: 'MINUTES') {
            echo('fetching artifact from the previous job')
            unstash 'some-web-app'
            echo('building and publishing the container images')
            // This is using the CloudBees Docker Pipeline Plugin
            // similar to running $ export DOCKER_HOST=tcp://0.0.0.1:2375
            docker.withServer('tcp://0.0.0.1:2375') {
                docker.build("${DOCKER_REGISTRY}/some-web-app:${DOCKER_IMAGE_TAG}").push()
            }
        }
    }

    stage ('Deploy Regression') {
        timeout(time: 30, unit: 'MINUTES') {
            sh("docker compose up regression")
        }
    }

    stage ('Regression Test') {
        timeout(time: 30, unit: 'MINUTES') {
            sh("$MVN_HOME/bin/mvn clean integration-test")
        }
    }

}

node ('linux') {
    stage ('Publish Artifacts to archiva') {
        timeout(time: 30, unit: 'MINUTES') {
            if ("${env.BRANCH_NAME}" == "master") {
                echo('fetching artifacts from the previous job')
                unstash 'database-scripts'
                echo('publishing artifacts to archiva')
                projectVersion = getProjectVersion()
                withCredentials([usernamePassword(credentialsId: 'ArtifactoryLogin', usernameVariable: 'username', passwordVariable: 'password')]) {
                    sh('''$MVN_HOME/bin/mvn deploy:deploy-file -B
              -DgroupId=com.your.package
              -DartifactId=database-scripts
              -Dversion=${projectVersion}-${env.BUILD_NUMBER}
              -Dfile=database-scripts/target/database-scripts-${projectVersion}.tar.gz
              -DrepositoryId=database-scripts
              -Durl=http://${username}:${password}@${ARCHIVA_HOST}/path/to/your/project
              '''
                    )
                }
            } else {
                echo('no need to publish artifacts to archiva since we are not at the master branch')
            }
        }
    }

}

/* helper methods */

private void notifyBuild(String buildStatus = 'INPROGRESS') {
    // build status of null means success
    buildStatus = buildStatus ?: 'SUCCESS'

    postToSlack(buildStatus)
    postToGit(buildStatus)
}

private boolean checkGitLog() {
    sh('git log -1')
    lastCommit = sh([script: 'git log -1', returnStdout: true])
    if (lastCommit.contains("Check for something in the log message")) {
        return true
    } else {
        return false
    }
}


/**
 * publishes to artifactory
 * @param projectVersion
 * @param releaseType
 */
private void publishToArtifactory(String projectVersion, String releaseType) {
    // ARTIFACTORY_SERVER_ID is configured in the manage Jenkins section: jenkins-host.com/configure
    def artifactory = Artifactory.server("${ARTIFACTORY_SERVER_ID}")
    def uploadSpec = [
            files: [[
                            pattern: "target/myApp-${projectVersion}.zip",
                            target : "archiva_path/${releaseType}/${projectVersion}/${env.BUILD_NUMBER}/"
                    ]]
    ]
    def buildInfo = artifactory.upload(groovy.json.JsonOutput.toJson(uploadSpec))
    artifactory.publishBuildInfo(buildInfo)
}

/**
 * Post to git
 * @param state
 */
private void postToGit(String state) {
    if ('SUCCESS' == state || 'FAILED' == state) {
        currentBuild.result = state         // Set result of currentBuild
    }
    step([$class: 'StashNotifier'])
}

/**
 * Post messages to slack
 */
private void postToSlack(String buildStatus) {
    def subject = "${buildStatus}: Job '${JOB_NAME} [${env.BUILD_NUMBER}]'"
    def summary = "${subject} (${env.BUILD_URL})"

    // Override default values based on build status
    if (buildStatus == 'INPROGRESS') {
        color = 'YELLOW'
        colorCode = '#FFFF00'
    } else if (buildStatus == 'SUCCESS') {
        color = 'GREEN'
        colorCode = '#00FF00'
    } else {
        color = 'RED'
        colorCode = '#FF0000'
    }

    slackSend(color: colorCode, message: summary)
}