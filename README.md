To run:
1. `docker-compose build`
1. `docker-compose up -d`
1. Go to your local jenkins at: `localhost:8080`


## Jenkinsfile shows some useful functions for when you write a pipeline.

Covers:
* PreBuildMerge
* Workspace cleanup
* print env vars
* lock (for synchronous execution of stages)
* parallel stage/step execution
* python virtual envs
* git merge
* using placeholder variables within sh blocks
* slack notifications
* git build notifications

##### SCM configuration
Multi-branch pipeline needs to be configured to point to the scm, it will then do branch indexing
where jenkins will check any remote branches of the repo and if they contain a Jenkinsfile,
it will create the relevant pipeline jobs per each remote branch.

##### Replay function
You cannot execute Pipeline script locally.
If you want to test a change to Jenkinsfile live but without committing it,
use the Replay feature to manually edit and run the groovy file on the jenkins machine.

##### Pipelines documentation is a little scattered. Some useful links:
https://jenkins.io/doc/book/pipeline/   
https://jenkins.io/blog/2016/10/16/stage-lock-milestone/   
https://stackoverflow.com/search?tab=relevance&q=jenkinsfile


##### // TODO:
Extend with shared libs
https://jenkins.io/doc/book/pipeline/shared-libraries/




