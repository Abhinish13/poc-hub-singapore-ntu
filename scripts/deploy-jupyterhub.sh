#!/bin/bash

# Some bash functions for common tasks.

trim()
{
    local trimmed="$1"

    # Strip leading space.
    trimmed="${trimmed## }"
    # Strip trailing space.
    trimmed="${trimmed%% }"

    echo "$trimmed"
}

# Script can optionally be passed the arguments. If not supplied the
# user will be prompted to supply them.

if [ "$#" -ge 1 ]; then
    COURSE_NAME=$1
    shift
else
    read -p "Course Name: " COURSE_NAME
fi

COURSE_NAME=$(trim `echo $COURSE_NAME | tr 'A-Z' 'a-z'`)

if [ "$COURSE_NAME" == "" ]; then
    echo "ERROR: Course name cannot be empty."
    exit 1
fi

if ! [[ $COURSE_NAME =~ ^[a-z0-9-]*$ ]]; then
    echo "ERROR: Invalid course name $COURSE_NAME."
    exit 1
fi

if [ "$#" -ge 1 ]; then
    NOTEBOOK_REPOSITORY_URL=$1
    shift
else
    read -p "Notebook Repository URL: " NOTEBOOK_REPOSITORY_URL
fi

NOTEBOOK_REPOSITORY_URL=$(trim $NOTEBOOK_REPOSITORY_URL)

if [ "$NOTEBOOK_REPOSITORY_URL" == "" ]; then
    echo "ERROR: Repository URL cannot be empty."
    exit 1
fi

if [ "$#" -ge 1 ]; then
    NOTEBOOK_REPOSITORY_CONTEXT_DIR=$1
    shift
else
    read -p "Notebook Repository Context Dir: " NOTEBOOK_REPOSITORY_CONTEXT_DIR
fi

if [ "$#" -ge 1 ]; then
    NOTEBOOK_REPOSITORY_REFERENCE=$1
    shift
else
    read -p "Notebook Repository Reference [master]: " NOTEBOOK_REPOSITORY_REFERENCE
fi

if [ "$#" -ge 1 ]; then
    LDAP_SEARCH_USER=$1
    shift
else
    read -p "LDAP Search User: " LDAP_SEARCH_USER
fi

LDAP_SEARCH_USER=$(trim $LDAP_SEARCH_USER)

if [ "$LDAP_SEARCH_USER" == "" ]; then
    echo "ERROR: LDAP search user cannot be empty."
    exit 1
fi

if [ "$#" -ge 1 ]; then
    LDAP_SEARCH_PASSWORD=$1
    shift
else
    read -s -p "LDAP Search Password: " LDAP_SEARCH_PASSWORD
    echo
fi

LDAP_SEARCH_PASSWORD=$(trim $LDAP_SEARCH_PASSWORD)

if [ "$LDAP_SEARCH_PASSWORD" == "" ]; then
    echo "ERROR: LDAP search user password cannot be empty."
    exit 1
fi

if [ "$#" -ge 1 ]; then
    JUPYTERHUB_ADMIN_USERS=$1
    shift
else
    read -p "JupyterHub Admin Users: " JUPYTERHUB_ADMIN_USERS
fi

if [ "$#" -ge 1 ]; then
    PROJECT_RESOURCES=$1
    shift
else
    read -p "Project Resources: " PROJECT_RESOURCES
fi

if [ x"$CONTINUE_PROMPT" != x"n" ]; then
    read -p "Continue? [Y/n] " DO_UPDATE
fi

if ! [[ $DO_UPDATE =~ ^[Yy]?$ ]]; then
    exit 1
fi

export DO_UPDATE
export CONTINUE_PROMPT=n

# Fail fast if any of these steps fail.

set -e

# Now run all the steps together to create the directories in the NFS
# shares and create the persistent volumes.

`dirname $0`/create-notebooks-directory.sh "$COURSE_NAME" ""
`dirname $0`/create-notebooks-volume.sh "$COURSE_NAME" ""
`dirname $0`/create-database-directory.sh "$COURSE_NAME" ""
`dirname $0`/create-database-volume.sh "$COURSE_NAME" ""

# Create the project and load the template into it.

`dirname $0`/create-project.sh "$COURSE_NAME"

# Load any project resources if path to file has been provided.

if [ x"$PROJECT_RESOURCES" != x"" ]; then
    `dirname $0`/create-project-resources.sh "$COURSE_NAME" "$PROJECT_RESOURCES"
fi

# Deploy instantiate the template to deploy JupyterHub.

`dirname $0`/instantiate-template.sh "$COURSE_NAME" \
    "$NOTEBOOK_REPOSITORY_URL" "$NOTEBOOK_REPOSITORY_CONTEXT_DIR" \
    "$NOTEBOOK_REPOSITORY_REFERENCE" "$LDAP_SEARCH_USER" \
    "$LDAP_SEARCH_PASSWORD" "$JUPYTERHUB_ADMIN_USERS"
