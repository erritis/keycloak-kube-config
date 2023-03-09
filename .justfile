werf-convert:
  kompose convert -f docker-compose.yml -o ./.helm/templates;
  rm ./.helm/templates/*-persistentvolumeclaim.yaml;
  find ./.helm/templates -type f -exec sed -i "s/'{{{{ \(.*\) }}'/{{{{ \1 }}/g" {} +;
  mv .helm/templates/*-configmap.yaml .kube/config;
  mv .helm/templates/*-secret.yaml .kube/secret;

werf-encrypt:
  werf helm secret values encrypt .raw/secret-values.yaml -o .helm/secret-values.yaml
  bash -c 'for filename in .raw/config/*; do name=${filename##*/}; werf helm secret file encrypt ".raw/config/$name" -o ".helm/config/$name"; done;';
  bash -c 'for filename in .raw/secret/*; do name=${filename##*/}; werf helm secret file encrypt ".raw/secret/$name" -o ".helm/secret/$name"; done;';
werf-decrypt:
  werf helm secret values decrypt .helm/secret-values.yaml -o .raw/secret-values.yaml
  bash -c 'for filename in .helm/config/*; do name=${filename##*/}; werf helm secret file encrypt ".helm/config/$name" -o ".raw/config/$name"; done;';
  bash -c 'for filename in .helm/secret/*; do name=${filename##*/}; werf helm secret file encrypt ".helm/secret/$name" -o ".raw/secret/$name"; done;';

werf-up-storage:
  kubectl apply -f local-storage.yaml;
  kubectl apply -f keycloakdb-pv-0.yaml;
werf-down-storage:
  kubectl delete -f keycloakdb-pv-0.yaml;
  kubectl delete -f local-storage.yaml;

werf-up-conf:
  kubectl create namespace keycloak &>/dev/null || exit 0;
  kubectl config set-context --current --namespace=keycloak;
  kubectl apply -Rf ./.kube/config/;
  kubectl apply -Rf ./.kube/secret/;
werf-down-conf:
  kubectl apply -Rf ./.kube/config/;
  kubectl apply -Rf ./.kube/secret/;

werf-up:
  werf converge;
werf-down:
  werf dismiss;
  
werf-clear:
  werf dismiss;
  kubectl delete namespace keycloak;
  kubectl delete -f keycloakdb-pv-0.yaml;
  kubectl delete -f local-storage.yaml;
  