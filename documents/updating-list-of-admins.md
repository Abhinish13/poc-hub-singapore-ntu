# Updating List of Admins

JupyterHub provides a means for users to create their own Jupyter notebook instance. Only users who can login in with the configured authentication provider, and who are listed as a user in the JupyterHub database can use JupyterHub to create a Jupyter notebook.

Any user of the JupyterHub instance can optionally be designated as an admin of the JupyterHub instance. This will give them additional capabilities for the JupyterHub instance.

Being an admin in the JupyterHub instance is completely unrelated to the underlying OpenShift environment, and does not grant any access to OpenShift (if not already a user in OpenShift), or extra capabilities in the OpenShift cluster (if an existing normal user in OpenShift).

With the configuration used for this deployment, the extra capabilities that a user marked as an admin in JupyterHub has are:

* When they start up their Jupyter notebook instance, they will startup in their own workspace, but they can traverse back up the directory hierarchy through the web interface and are able to see the workspaces of all other users using the JupyterHub instance.
* From the control panel for JupyterHub, they can access the admin panel. The admin panel allows them to see what users are registered, and whether they have an active Jupyter notebook instance. They can stop or start a users Jupyter notebook instance. They can access another users Jupyter notebook instance and work in it as if they were that user. They can also add or delete users from the admin panel, or mark a user as an admin in JupyterHub.

## Initial Setup of Admins

When the JupyterHub instance is initially deployed, a list of initial admin users can be specified. This list is added to what is called a config map in OpenShift. This config map is in turn mounted as a file into the JupyterHub instance and is used to populate the JupyterHub database. If you do not provide any admin users in this way, you can instead add them via the REST API. You will only be able to add users via the admin panel when you have at least one admin user setup.

## Adding Admins via the REST API

Users can be added direct to the JupyterHub database using the scripts:

* [scripts/add-user-to-jupyterhub.sh](../scripts/add-user-to-jupyterhub.sh) - Adds a single user to the JupyterHub user database via the REST API.
* [scripts/add-multiple-users-to-jupyterhub.sh](../scripts/add-multiple-users-to-jupyterhub.sh) - Adds multiple users to the JupyterHub user database via the REST API.

To add a single user, which is also marked as an admin, use the command:

```
$ scripts/add-user-to-jupyterhub.sh coursename username admin
[]{"kind": "user", "name": "username", "admin": true, "groups": [], "server": null, "pending": null, "created": "2018-07-27T00:55:50.163763Z", "last_activity": null, "servers": null}]
```

Compared to adding a normal user, you must supply the additional ``admin`` argument.

The script will output a record as JSON for the user which was added. If the user already exists, you will get an error response:

```
{"status": 409, "message": "All 1 users already exist"}
```

To add multiple users in one command, create an input file with a list of the users one per line. Then run the command:

```
$ ./scripts/add-multiple-users-to-jupyterhub.sh coursename users.txt admin
[{"kind": "user", "name": "username1", "admin": false, "groups": [], "server": null, "pending": null, "created": "2018-07-27T00:58:16.451094Z", "last_activity": null, "servers": null}, {"kind": "user", "name": "username2", "admin": false, "groups": [], "server": null, "pending": null, "created": "2018-07-27T00:58:16.453661Z", "last_activity": null, "servers": null}, {"kind": "user", "name": "username3", "admin": false, "groups": [], "server": null, "pending": null, "created": "2018-07-27T00:58:16.456022Z", "last_activity": null, "servers": null}]
```

Compared to adding nnormal users, you must supply the additional ``admin`` argument.

The script will output the record of all users added. If all users already existed, you will see an error response of:

```
{"status": 409, "message": "All 3 users already exist"}
```

If some users already existed and others didn't, you will only see output the record of which users were added. So it is safe to attempt to add users which are already recorded in the JupyterHub database.

Note that in order to be able to access the JupyterHub REST API, an access token is needed. The script obtains this access token by accessing a pre-generated token from the deployment config for JupyterHub in OpenShift. You therefore need to be logged into OpenShift from the command line with an account with appropriate access to the project for the course.

## Removing Admins via the REST API

A user can be removed direct from the JupyterHub database using the script:

* [scripts/remove-user-from-jupyterhub.sh](../scripts/remove-user-from-jupyterhub.sh) - Removes a single user from the JupyterHub user database via the REST API.

This can be used to remove any users, including users designated as admins.

To remove a single user use the command:

```
$ ./scripts/remove-user-from-jupyterhub.sh coursename username
```

Output will be empty if it succeeds. If you attempt to remove a user that doesn't exist, you will see the response:

```
{"status": 404, "message": "Not Found"}
```

The REST API doesn't provide a way to remove users in bulk. They would need to be remove one at a time.

When a user is removed, any Jupyter notebook instance they currently have running will be shutdown.

Note that if you remove a user in this way who was originally added using the admin users config map, they will be added back again the next time JupyterHub is restarted, unless you also update the config map.

## Using the JupyterHub Admin Panel

Although both admin users and normal users can be loaded into the JupyterHub database through config maps, it is recommended that the JupyterHub user database be updated directly, by way of the admin panel, or via the REST API.

The reason for this recommendation is that if you are making frequent changes to the list of users, using the config map is more unwieldy. Also, removing of users is more complicated as they have to be removed from both the config map and the JupyterHub database via the admin panel.

To add users via the admin panel, you need to be logged in as a user designated as an admin in JupyterHub. You should access the _Control Panel_ and then the _Admin_ panel.

From the admin panel, select on _Add Users_. From the popup window, you can add a new user. If you need to add more than one user, they need to be listed one per line. You cannot list multiple users on the same line.

In the case that you want to designate these users as admins, you should select the _Admin_ checkbox in the popup window before adding the users.

If you need to make an existing user an admin, you can select _edit_ on that user in the admin panel, select the _Admin_ checkbox and save the change.

If you need to remove admin rights from a user, you can select _edit_ on that user in the admin panel, de-select the _Admin_ checkbox and save the change. Note thought that if the user was listed in the config map for admin users and you remove admin rights via the admin panel, when JupyterHub is restarted, admin rights will be restored again. In this case you need to ensure you also remove the user from the config map for admin users.

To delete any user, find the user in the list of users from the admin panel and select _delete_. If the user has a current Jupyter notebook instance, that Jupyter notebook instance will be shutdown, when removing the user from the database. You will also need to remove the user from any config map if they were also listed there.

## Querying the Admin Users Config Map

To get a copy of the current contents of the config map used to initialise the admin users for the JupyterHub instance, run the script:

```
$ scripts/extract-admin-users.sh coursename > coursename-admin_users.txt
```

The contents of the config map will be displayed as output, so can be saved to a file by directing output to a file as shown.

## Updating Admin Users Config Map

If not using the recommended method of adding additional admins via the admin panel of JupyterHub, and you want to load them via the config map, pull down the current config map and add the LDAP username of the user to it.

To update the config map, run the script:

```
$ scripts/update-admin-users.sh coursename coursename-admin_users.txt
```

The arguments are the name of the course and the file containing the list of users. If you don't supply the arguments, you will be prompted for the inputs.

You will also be asked whether you want to trigger a new deployment of JupyterHub. This will cause JupyterHub to be restarted so that the updated config map is read.

When JupyterHub is restarted, any new users listed in the config map, will be added to the JupyterHub database and marked as an admin.

If you are using the config map to load the users, and need to remove a user, two steps are required.

You first need to remove the user from the config map for the admin users. This is done using the same process as adding a user, except that you are removing the LDAP username from the file containing the user whitelist, before updating the config map with the modified file.

To remove a user as an admin requires two steps. You first need to remove the user from the config map for the admin users. This is done using the same process as adding an admin user, except that you are removing the LDAP username from the file containing the list of admin users, before updating the config map with the modified file.

A second step that must then be done, is to also delete the user from the admin panel in JupyterHub. If you do not do this, the user will still be recorded in the JupyterHub database. This is because JupyterHub doesn't synchronise the database with the list from the config map when entries are removed.

Performing the second step of deleting the user from the admin panel will remove them from the JupyterHub database and they will not be able to use the JupyterHub instance. Note though that if the user was also listed in the config map for the user whitelist, they will be added back into the JupyterHub database the next time the JupyterHub instance is restarted. Ensure therefore that the user is also removed from the users whitelist if they appeared in both the user whitelist and list of admin users, and they should not retain any access.

Because of the need to perform two steps when removing users, if you know you will need to keep making changes, it is better to load users and make changes through the admin panel and not use the config map.

## Admin Users Database Backups

As the recommended procedure is to use the admin page in JupyterHub to manage additional admin users, the admin users in the config map may not be complete. In this case it is possible to retrieve an up to date copy from the JupyterHub instance. This is done by retrieving it from backups which are periodically made from the database.

There are two ways that the user database is backed up, which you can retrieve. The need to backup the database is checked on a five minute interval. The backup will only be done if a change in the users is detected.

The first type of backup is done to a config map in OpenShift. To retrieve this backup for admin users you can use the script:

* [scripts/extract-admin-users-backup.sh](../scripts/extract-admin-users-backup.sh) - Download the backup of the admin users in the JupyterHub database.

Run the script as:

```
$ scripts/extract-admin-users-backup.sh coursename > coursename-admin_users.txt
```

The file created will only include users marked as an admins.

This type of backup only provides the latest set of users from the JupyterHub database.

A second type of backup is done by writing the backup files to the same persistent volume as is used for notebooks.

To see the list of files in the backups directory, first identify the name of the pod for the JupyterHub instance using ``oc get pods``.

```
$ oc get pods -n coursename --selector app=jupyterhub,deploymentconfig=jupyterhub
NAME                  READY     STATUS    RESTARTS   AGE
jupyterhub-40-pgm8w   1/1       Running   0          3d
```

Once you have the name of the pod, you can list what backup files there are by running ``oc rsh``.

```
$ oc rsh -n coursename podname ls /opt/app-root/notebooks/backups
admin_users-2018-07-09-01-45-16.txt
user_whitelist-2018-07-09-01-45-16.txt
admin_users-latest.txt
user_whitelist-latest.txt
```

The suffix of the timestamped files is of the form ``-YYYY-MM-DD-hh-mm-ss.txt``. There is also one with the ``-latest.txt`` extension which is a symlink to the latest timestamped file.

To copy a file back to the current host, run ``cat`` on the file and save the results to a file.

```
$ oc rsh -n coursename podname \
  cat /opt/app-root/notebooks/backups/admin_users-2018-07-09-01-45-16.txt >
  coursename-admin_users.txt
```

A new backup file is created each time the JupyterHub instance is restarted. A backup will also be periodically made if it is detected that a change was made to the list of admin users since the last time a backup was made.

You can therefore use the backup files as an audit trail as to when changes were made to the list of admin users.

Note that these files are saved into a ``backups`` directory within the persistent volume used to hold users notebooks. An alternative way to retrieve these files is to mount the NFS share for the notebooks directory, and traverse to the ``backups`` directory within the notebooks directory for the course.
