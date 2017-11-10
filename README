## Jenkinsfile shows some useful functions for when you write a pipeline.

Covers:
* PreBuildMerge
* Workspace cleanup
* print env vars
* lock (for synchronous execution of stages)
* parallel 
* python virtual envs
* git merge
* using placeholder variables within sh blocks
* slack notifications
* git build notifications


Multi-branch pipeline needs to be configured to point to the scm, it will then do branch indexing
where jenkins will check any remote branches of the repo and if they contain a Jenkinsfile,
it will create the relevant pipeline jobs per each remote branch.

You cannot execute Pipeline script locally.
If you want to test a change to Jenkinsfile live but without committing it,
use the Replay feature to manually edit and run the groovy file on the jenkins machine.

Pipelines documentation is a little scattered. Some useful links:

https://jenkins.io/doc/book/pipeline/
https://jenkins.io/blog/2016/10/16/stage-lock-milestone/
https://stackoverflow.com/search?tab=relevance&q=jenkinsfile

TODO:
Extend with shared libs
https://jenkins.io/doc/book/pipeline/shared-libraries/




