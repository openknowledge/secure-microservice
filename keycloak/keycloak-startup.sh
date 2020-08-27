export PATH=$PATH:$JBOSS_HOME/bin

#######################################
# create an enabled realm if not exists
#######################################
createRealm() {
  echo ""
  echo "Start creating realm ${1}"
  echo "---------------------------"
  echo ""

  # check realm exists
  echo "Searching for realm '${1}' ..."
  REALM_ID=$(kcadm.sh get realms/$1 --fields id | jq -r .id)
  echo ""

  if [ -z "$REALM_ID" ]
  then
    # create and enable the realm
    kcadm.sh create realms -s realm=$1 -s enabled=true
  else
    echo "Realm ${1} (id=$REALM_ID) already exists"
  fi
  echo ""
  echo "---------------------------"
  echo "Finish creating realm ${1}"
}

#######################################
# configure the following realm settings
# event logging, user registration, language, authentication flow and smtp setting
#######################################
updateRealm() {
  REALM=$1
  shift
  REALM_GROUPS=("$@")

  echo ""
  echo "Start updating realm ${REALM}"
  echo "---------------------------"
  echo ""

  # event logging
  kcadm.sh update realms/$REALM -s 'eventsListeners=["jboss-logging","event-logger"]' -s eventsEnabled=true -s adminEventsEnabled=true -s adminEventsDetailsEnabled=true -s eventsExpiration=300
  echo "Updating realm ${REALM} - enable event settings"

  # user registration
  kcadm.sh update realms/$REALM -s registrationAllowed=false -s registrationEmailAsUsername=false -s editUsernameAllowed=true -s resetPasswordAllowed=true -s rememberMe=false -s verifyEmail=false -s loginWithEmailAllowed=false
  echo "Updating realm ${REALM} - login settings"

  # language
  kcadm.sh update realms/$REALM -s 'supportedLocales=["de"]' -s defaultLocale=de -s internationalizationEnabled=true
  echo "Updating realm ${REALM} - themes settings"

  configureRealmEmailSettings $REALM
  configureRealmAuthenticationFlow $REALM
  configureRealmClientScope $REALM
  configureRealmGroups $REALM ${REALM_GROUPS[@]}

  echo ""
  echo "---------------------------"
  echo "Finish updating realm ${REALM}"
}

#######################################
# configure the email server setting
#######################################
configureRealmEmailSettings() {
  # TODO: Can be deleted if all functionalities are moved to micro services
  echo "Updating realm ${1} - email settings"
  # email server settings
  if [ -z "$SMTP_USERNAME" ]
  then
    kcadm.sh update realms/$1 -s "smtpServer.from=$SMTP_FROM" -s "smtpServer.fromDisplayName=$SMTP_FROM_NAME" -s "smtpServer.host=$SMTP_HOST" -s "smtpServer.port=$SMTP_PORT"
    echo "                     -> setup without authentication and ssl"
  else
    kcadm.sh update realms/$1 -s "smtpServer.from=$SMTP_FROM" -s "smtpServer.fromDisplayName=$SMTP_FROM_NAME" -s "smtpServer.host=$SMTP_HOST" -s "smtpServer.port=$SMTP_PORT" -s "smtpServer.ssl=true" -s "smtpServer.starttls=false" -s "smtpServer.auth=true" -s "smtpServer.user=$SMTP_USERNAME" -s "smtpServer.password=<$SMTP_PASSWORD"
    echo "                     -> setup with authentication and ssl"
  fi
}

#######################################
# configure the authentication flow
#######################################
configureRealmAuthenticationFlow() {
  echo "Updating realm ${1} - authentication flow 'registration'"
  # get authentication flow execution id
  EXECUTION_ID=$(kcadm.sh get authentication/flows/registration%20form/executions -r $1 | jq -r '.[] | select (.providerId=="registration-profile-action") | .id')
  if [ "$EXECUTION_ID" == "null" ]
  then
    EXECUTION_ID=''
  fi

  if [ -z "$EXECUTION_ID" ]
  then
    echo "                     -> [Warning] authentication flow 'registration' not found!"
  else
    # disable validation for prename and surname
    kcadm.sh update authentication/flows/registration%20form/executions -r $1 -b "{\"id\":\"$EXECUTION_ID\",\"requirement\":\"DISABLED\"}"
  fi
}

#######################################
# update the realm client scope by moving
#  microprofile-jwt from optional to default
#  roles from default to optional
#######################################
configureRealmClientScope() {
  echo "Updating realm ${1} - client scopes"
  # get client scope 'microprofile-jwt' id
  MP_JWT_ID=$(kcadm.sh get realms/$1/client-scopes | jq '.[] | select(.name=="microprofile-jwt")' | jq -r .id)
  if [ -z "$MP_JWT_ID" ]
  then
    echo "                     -> [Warning] client scope 'microprofile-jwt' not found!"
  else
    # delete 'microprofile-jwt' from "Assigned Optional Client Scopes"
    kcadm.sh delete realms/$1/default-optional-client-scopes/$MP_JWT_ID
    # PUT 'microprofile-jwt' to "Assigned Default Client Scopes"
    kcadm.sh update realms/$1/default-default-client-scopes/$MP_JWT_ID
    echo "                     -> client scope 'microprofile-jwt' moved from optional to default"
  fi
  # get client scope 'roles' id
  ROLES_ID=$(kcadm.sh get realms/$1/client-scopes | jq '.[] | select(.name=="roles")' | jq -r .id)
  if [ -z "$ROLES_ID" ]
  then
    echo "                     -> [Warning] client scope 'roles' not found!"
  else
    # delete 'roles' from "Assigned Default Client Scopes"
    kcadm.sh delete realms/$1/default-default-client-scopes/$ROLES_ID
    # PUT 'roles' to "Assigned Optional Client Scopes"
    kcadm.sh update realms/$1/default-optional-client-scopes/$ROLES_ID
    echo "                     -> client scope 'roles' moved from default to optional"
  fi
}

#######################################
# configure realm groups
#######################################
configureRealmGroups() {
  REALM=$1
  shift
  REALM_GROUPS=("$@")

  echo "Updating realm ${REALM} - create groups"
  echo ""

  for REALM_GROUP in "${REALM_GROUPS[@]}";
  do
    REALM_GROUP_ID=$(kcadm.sh get groups -r $REALM -q search=$REALM_GROUP --fields=id | jq -r .[0].id)
    if [ "$REALM_GROUP_ID" == "null" ]
    then
      REALM_GROUP_ID=''
    fi

    if [ -z "$REALM_GROUP_ID" ]
    then
      REALM_GROUP_ID=$(kcadm.sh create groups -r $REALM -s name=$REALM_GROUP -i)
      echo "Group ${REALM_GROUP} (id=${REALM_GROUP_ID}) created"
    else
      echo "Group ${REALM_GROUP} (id=${REALM_GROUP_ID}) already exists"
    fi
  done
}

#######################################
# create client specific authentication flows
#######################################
createAuthenticationFlow() {
  echo ""
  echo "Start creating authentication flow for client ${2}"
  echo "---------------------------"
  echo ""

  BASIS_FLOW=Browser-$2
  FORM=Forms-$2
  REQUIRED_ROLE=Required-Role-$2

  # create the realm role for the required-role extension
  configureRealmRole $1 $2

  # create the basis flow
  configureBasisAuthenticationFlow $1 $2

  echo ""
  echo "Created authentication flow structure:"
  echo "--------------------------------------"
  echo "Flow: Browser-${2}"
  echo ""
  echo "Auth-Type                             Requirement             Config"
  echo "Forms-${2}                     ALTERNATIVE"
  echo "     -> username-password-form        REQUIRED"
  echo "     -> required-role                 REQUIRED                role=${2^^}"
  echo ""
  echo "---------------------------"
  echo "Finish creating authentication flow for client ${2}"
}

#######################################
# create realm role for specific authentication flows
#######################################
configureRealmRole() {
  # create the realm role for the required-role extension
  ROLE_ID=$(kcadm.sh get roles -r $1 --fields id,name | jq '.[] | select(.name=="'${2^^}'")' | jq -r .id)

  if [ "$ROLE_ID" == "null" ]
  then
    ROLE_ID=''
  fi

  if [ -z "$ROLE_ID" ]
  then
    ROLE_ID=$(kcadm.sh create roles -r $1 -s name=${2^^} -i)
    echo "Role ${2^^} created"
  else
    echo "Role ${2^^} (id=${ROLE_ID}) already exists"
  fi
}

#######################################
# create basis authentication flows for specific client
#######################################
configureBasisAuthenticationFlow() {
  BASIS_FLOW=Browser-$2
  FORM=Forms-$2
  REQUIRED_ROLE=Required-Role-$2

  BASIS_FLOW_ID=$(kcadm.sh get realms/$1/authentication/flows -r $1 --fields id,alias | jq '.[] | select(.alias=="'$BASIS_FLOW'")' | jq -r .id)

  if [ "$BASIS_FLOW_ID" == "null" ]
  then
    BASIS_FLOW_ID=''
  fi

  if [ -z "$BASIS_FLOW_ID" ]
  then
    # create the basis flow
    kcadm.sh create realms/$1/authentication/flows -r $1 -s alias=$BASIS_FLOW -s providerId=basic-flow -s topLevel=true -s builtIn=false
    # create the form flow
    kcadm.sh create realms/$1/authentication/flows/$BASIS_FLOW/executions/flow -r $1 -s alias=$FORM -s type=basic-flow -s provider=registration-page-form
    # create the username-password-form flow
    kcadm.sh create realms/$1/authentication/flows/$FORM/executions/execution -r $1 -s provider=auth-username-password-form
    # create the required-role flow
    kcadm.sh create realms/$1/authentication/flows/$FORM/executions/execution -r $1 -s provider=required-role
    # configure the form flow
    FORM_ID=$(kcadm.sh get realms/$1/authentication/flows/$BASIS_FLOW/executions -r $1 | jq '.[] | select(.displayName=="'$FORM'")' | jq -r .id)
    kcadm.sh update realms/$1/authentication/flows/$BASIS_FLOW/executions -r $1 -b "{\"id\":\"$FORM_ID\",\"requirement\":\"ALTERNATIVE\"}"
    echo "Configure flow id '${FORM_ID}' - set requirement to 'ALTERNATIVE'"
    # configure the required-role flow
    REQUIRED_ROLE_ID=$(kcadm.sh get realms/$1/authentication/flows/$BASIS_FLOW/executions -r $1 | jq '.[] | select(.providerId=="required-role")' | jq -r .id)
    kcadm.sh update realms/$1/authentication/flows/$BASIS_FLOW/executions -r $1 -b "{\"id\":\"$REQUIRED_ROLE_ID\",\"requirement\":\"REQUIRED\"}"
    kcadm.sh create realms/$1/authentication/executions/$REQUIRED_ROLE_ID/config -s alias=$REQUIRED_ROLE -s 'config."role"='${2^^}
    echo "Configure flow id '${REQUIRED_ROLE_ID}' - set requirement to 'REQUIRED'"
  else
    echo "Authentication flow ${BASIS_FLOW} (id=${BASIS_FLOW_ID}) already exists"
  fi
}

#######################################
# create a client if not exists and sets following properties:
# redirectUris, webOrigins, fullScopeAllowed
#######################################
createClient() {
  echo ""
  echo "Start creating client ${2}"
  echo "---------------------------"
  echo ""

  # ### DEFAULT CLIENTS ###
  echo "Searching for client '${2}' ..."
  CLIENT_ID=$(kcadm.sh get clients -r $1 -q clientId=$2 --fields id | jq -r .[0].id)

  if [ "$CLIENT_ID" == "null" ]
  then
    CLIENT_ID=''
  fi

  if [ -z "$CLIENT_ID" ]
  then
    # create and enable the client
    CLIENT_ID=$(kcadm.sh create clients -r $1 -s clientId=$2 -i)
    echo "Client ${2} (id='$CLIENT_ID') created"
  else
    echo "Client ${2} (id=$CLIENT_ID) already exists"
  fi

  echo ""
  echo "---------------------------"
  echo "Finish creating client ${2}"
}

#######################################
# update client theme
#######################################
updateClient() {
  REALM=$1
  CLIENT=$2
  THEME=$3
  shift
  shift
  shift
  ROLES=("$@")
  echo ""
  echo "Start updating client ${CLIENT}"
  echo "---------------------------"

  CLIENT_ID=$(kcadm.sh get clients -r $REALM -q clientId=$CLIENT --fields id | jq -r .[0].id)
  BASIS_FLOW=Browser-$CLIENT

  # update client
  kcadm.sh update clients/$CLIENT_ID -r $REALM -s publicClient=true -s "redirectUris=$REDIRECT_URIS" -s "webOrigins=$WEB_ORIGINS" -s fullScopeAllowed=false -s directAccessGrantsEnabled=true
  echo "Updating client ${CLIENT} - access type, redirect uris and web origins"

  AUTH_FLOW_ID=$(kcadm.sh get realms/$REALM/authentication/flows -r $REALM | jq '.[] | select(.alias=="'$BASIS_FLOW'")' | jq -r .id)
  kcadm.sh update clients/$CLIENT_ID -r $REALM -s 'authenticationFlowBindingOverrides."browser"='$AUTH_FLOW_ID
  echo "Updating client ${CLIENT} - authentication flow settings"

  kcadm.sh update clients/$CLIENT_ID -r $REALM -s attributes.login_theme=$THEME -s fullScopeAllowed=false
  echo "Updating client ${CLIENT} - themes settings to '${THEME}'"

  configureClientMapper $REALM $CLIENT $CLIENT_ID
  configureClientRoles $REALM $CLIENT $CLIENT_ID ${ROLES[@]}

  echo ""
  echo "---------------------------"
  echo "Finish updating client ${CLIENT}"
}

#######################################
# add and configure the MP-JWT groups mapper if not exists
#######################################
configureClientMapper() {
  # CLIENT_ID=$(kcadm.sh get clients -r $1 -q clientId=$2 --fields id | jq -r .[0].id)
  echo "Updating client ${2} - mapper settings"

  # get protocol mapper 'MP JWT Groups Mapper' id
  MAPPER_ID=$(kcadm.sh get clients/$3/protocol-mappers/protocol/openid-connect -r $1 --fields=protocolMapper | jq -r .[0].protocolMapper)

  if [ "$MAPPER_ID" == "null" ]
  then
    MAPPER_ID=''
  fi

  if [ -z "$MAPPER_ID" ]
  then
    # create mapper for client
    kcadm.sh create clients/$3/protocol-mappers/models -r $1 -s name='MP JWT Groups Mapper' -s protocol=openid-connect -s protocolMapper=oidc-usermodel-client-role-mapper -s 'config."id.token.claim"=true' -s 'config."access.token.claim"=true' -s 'config."userinfo.token.claim"=true' -s 'config."multivalued"=true' -s 'config."claim.name"=groups'

    echo ""
    echo "Client mapper:"
    echo "--------------"
    echo "  -> add MP-JWT groups mapper"
    echo ""
  fi
}

#######################################
# create client roles and a realm role based on the client name in uppercase
#######################################
configureClientRoles() {
  REALM=$1
  CLIENT=$2
  CLIENT_ID=$3
  shift
  shift
  shift
  ROLES=("$@")

  echo "Updating client ${CLIENT} - create roles"
  echo ""

  for ROLE in "${ROLES[@]}";
  do
    ROLE_ID=$(kcadm.sh get clients/$CLIENT_ID/roles -r $REALM --fields id,name | jq '.[] | select(.name=="'$ROLE'")' | jq -r .id)
    if [ "$ROLE_ID" == "null" ]
    then
      ROLE_ID=''
    fi

    if [ -z "$ROLE_ID" ]
    then
      ROLE_ID=$(kcadm.sh create clients/$CLIENT_ID/roles -r $REALM -s name=$ROLE -i)
      echo "Role ${ROLE} created"
    else
      echo "Role ${ROLE} (id=${ROLE_ID}) already exists"
    fi
  done
}

#######################################
# update group by adding roles
#######################################
updateGroup() {
  REALM=$1
  CLIENT=$2
  REALM_GROUP=$3
  shift
  shift
  shift
  GROUP_ROLES=("$@")
  echo ""
  echo "Start updating group ${REALM_GROUP} for client ${CLIENT}"
  echo "---------------------------"

  CLIENT_ID=$(kcadm.sh get clients -r $REALM -q clientId=$CLIENT --fields id | jq -r .[0].id)

  REALM_GROUP_ID=$(kcadm.sh get groups -r $REALM -q search=$REALM_GROUP --fields=id | jq -r .[0].id)

  for GROUP_ROLE in "${GROUP_ROLES[@]}";
  do
    GROUP_ROLE_ID=$(kcadm.sh get clients/$CLIENT_ID/roles -r $REALM --fields id,name | jq '.[] | select(.name=="'$GROUP_ROLE'")' | jq -r .id)
    if [ "GROUP_ROLE_ID" == "null" ]
    then
      GROUP_ROLE_ID=''
    fi

    if [ -z "GROUP_ROLE_ID" ]
    then
      echo "Role ${GROUP_ROLE} not exists"
    else
      kcadm.sh create groups/$REALM_GROUP_ID/role-mappings/clients/$CLIENT_ID -r $REALM -b "[{\"id\":\"${GROUP_ROLE_ID}\",\"name\":\"${GROUP_ROLE}\"}]"
      echo "Add role ${GROUP_ROLE} to group ${REALM_GROUP}"
    fi
  done

  echo ""
  echo "---------------------------"
  echo "Finish updating group ${REALM_GROUP} for client ${CLIENT}"
}

#######################################
# create an admin user if not exists
#######################################
createUser() {
  REALM=$1
  CLIENT=$2
  USER_EMAIL=$3
  shift
  shift
  shift
  USER_GROUPS=("$@")
  echo ""
  echo "Start creating user ${USER_EMAIL} for client ${CLIENT}"
  echo "---------------------------"
  ## create user if not exist; add realm role for auth flow and client roles

  USER_ID=$(kcadm.sh get users -r $REALM --fields id,username,email | jq -r '.[] | select(.email=="'${USER_EMAIL}'") | .id')
  if [ -z "$USER_ID" ]
  then
    USER_ID=$(kcadm.sh create users -r $REALM -s username=$USER_EMAIL -s email=$USER_EMAIL -s enabled=true -i)
    echo "User with email ${USER_EMAIL} (id='$USER_ID') created"
  else
    echo "User with email ${USER_EMAIL} (id='$USER_ID') already exists"
  fi

  # set default password to user
  kcadm.sh set-password -r $REALM --username $USER_EMAIL --new-password Test1234

  # add user to realm role
  kcadm.sh add-roles -r $REALM --uusername $USER_EMAIL --rolename ${CLIENT^^}

  echo ""
  # add user to client roles
  for USER_GROUP in "${USER_GROUPS[@]}";
  do
    USER_GROUP_ID=$(kcadm.sh get groups -r $REALM -q search=$USER_GROUP --fields=id | jq -r .[0].id)
    kcadm.sh update users/$USER_ID/groups/$USER_GROUP_ID -r $REALM -n
    echo "Add user (name='${USER_EMAIL}') to group '${USER_GROUP}'"
  done

  echo ""
  echo "---------------------------"
  echo "Finish creating user ${USER_EMAIL} for client ${CLIENT}"
}

#######################################
# process keycloak configuration
#######################################
waitingForKeycloakEndpoint=true

while $waitingForKeycloakEndpoint; do
  if [[ $(curl --head --write-out %{http_code} --silent --output /dev/null http://localhost:8080/auth) != 303 ]]
  then
    echo "wait 15 seconds before potentially running init scripts"
    sleep 15
  else
    waitingForKeycloakEndpoint=false

    echo ""
    echo "Start setting up keycloak"
    echo "--------------------------------------------------------"
    echo ""
    
    # login to the admin url
    kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD

    # configure common properties for all realms
    REALM_GROUPS=("SYSTEM_USER" "SYSTEM_ADMINISTRATOR")
    createRealm "MicroProfile"
    updateRealm "MicroProfile" ${REALM_GROUPS[@]}

    # configure client specific authentication flows
    createAuthenticationFlow "MicroProfile" "ok-react-demo-webapp"

    # configure clients incl mapper
    CLIENT_ROLES=("USER" "ADMIN")
    createClient "MicroProfile" "ok-react-demo-webapp"
    updateClient "MicroProfile" "ok-react-demo-webapp" "keycloak" ${CLIENT_ROLES[@]}

    # configure groups with roles
    SYSTEM_USER_ROLES=("USER")
    updateGroup "MicroProfile" "ok-react-demo-webapp" "SYSTEM_USER" ${SYSTEM_USER_ROLES[@]}
    SYSTEM_ADMINISTRATOR_ROLES=("USER" "ADMIN")
    updateGroup "MicroProfile" "ok-react-demo-webapp" "SYSTEM_ADMINISTRATOR" ${SYSTEM_ADMINISTRATOR_ROLES[@]}

    # create an admin user
    SYSTEM_ADMINISTRATOR_USER_ROLES=("SYSTEM_ADMINISTRATOR")
    createUser "MicroProfile" "ok-react-demo-webapp" "test.admin@domain.tld" ${SYSTEM_ADMINISTRATOR_USER_ROLES[@]}
    SYSTEM_USER_USER_ROLES=("SYSTEM_USER")
    createUser "MicroProfile" "ok-react-demo-webapp" "test.user@domain.tld" ${SYSTEM_USER_USER_ROLES[@]}

    echo ""
    echo "--------------------------------------------------------"
    echo "Finish setting up keycloak"
    echo ""
  fi

done &
