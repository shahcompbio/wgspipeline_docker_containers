# Automated building of new docker containers via Jenkins.

This repo contains the following:
- a set of docker files for building images as `./{project}/{package}/`
- a script for building the correct image based on git tags in `./container_builder/build_script.py`
- a docker file for building the jenkins image in `./jenkins`

Steps:
1. modify a dockerfile and git push to this repo (required even if the dockerfile did not change contents)
2. git tag the latest commit with the format {project}/{package}-{version}
3. jenkins will build a docker image for {project}/{package}:{version} and push to all registries as configured in jenkins

> IMPORTANT: Won't build without a new commit first when pushing tags

> IMPORTANT: Pushing tags too quickly may fail as only the most recent is built by jenkins
