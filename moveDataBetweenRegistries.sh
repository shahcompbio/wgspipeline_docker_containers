# #!/home/abramsd
#Douglas Abrams
#8/16/19  
#pulls the newest versions of every repo in a registry and pushes them onto a target registry 
#[PUSH FROM]: registry being pulled from
#[target]: target registry

repos=( $(az acr repository list  -g [PUSH_FROM] -n [PUSH_FROM]  -o table) )
for element in "${repos[@]:2}"
do
    versions=($(az acr repository show-tags  -g [PUSH_FROM]-n [PUSH_FROM] -o table --repository ${element} -o table))
    nVersions=${#versions[@]}
    newestVers=${versions[$nVersions-1]}
    pulling="[PUSH_FROM].azurecr.io/"$element":"$newestVers
    echo "pulling down  "$pulling
    docker pull ${pulling}
    docker tag "[PUSH_FROM].azurecr.io/"$element":"$newestVers "[target].azurecr.io/"$element":"$newestVers
    docker push "[target].azurecr.io/"$element":"$newestVers
done
