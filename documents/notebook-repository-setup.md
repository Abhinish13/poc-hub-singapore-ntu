# Notebook Repository Setup

When JupyterHub is deployed, you need to provide the details of a hosted Git repository which contains the set of Jupyter notebooks and data files that will be built into the image used when deploying a users Jupyter notebook instance. The Git repository is identified via the following:

* ``Notebook Repository URL`` - The URL of the Git repository which hosts the Jupyter notebook and data files for the course.
* ``Notebook Repository Context Dir`` - The directory within the Git repository which contains the Jupyter notebook and data files, along with the ``requirements.txt`` file listing what Python packages are required for the Jupyter notebooks. This should be left empty if files are in the root of the Git repository.
* ``Notebook Repository Reference`` - The Git branch, tag or ref of the Git repository which holds the desired version of the Jupyter notebooks and data files. If left as empty, the Git repository 'master' branch will be used.

## Git Repository URL

The URL provided is that which provides the location for where the hosted Git repository is located. The template used to deploy JupyterHub assumes this is a public Git repository.

A URL for a Git repository hosted on GitHub, GitLab or Bitbucket should work. The URL should be that which would be used if doing a ``git clone`` of the hosted Git repository over HTTP/HTTPS.

The typical form of the URL if using GitHub would be:

```
https://github.com/jakevdp/PythonDataScienceHandbook.git
```

A Git repository hosting service may also allow you to use the URL for the home page for the repository in their web UI. For example, if using GitHub, you can also drop the ``.git`` extension and use:

```
https://github.com/jakevdp/PythonDataScienceHandbook
```

## Context Directory

The context directory is the directory within the hosted Git repository which should be incorporated into the image used to run the Jupyter notebooks.

If the only thing in the repository is the Jupyter notebooks and data files for the one course, you can leave this value empty, and the entire contents of the Git repository will be included.

If the Git repository contains Jupyter notebooks and data files for multiple courses, each in separate sub directories, the context directory should be set as the name of the sub directory in the hosted Git repository which holds the files for the one course.

Note that if supplying a ``requirements.txt`` file listing the names of Python packages to automatically be installed in the image, it must be located in the directory referred to by the context directory.

So if setting the context directory to a sub directory, there must be a ``requirements.txt`` file in that sub directory. You cannot place a ``requirements.txt`` file at the top of the Git repository as it will be outside of the directory tree used for the build.

## Version of Files

By default, when building the image the ``master`` branch of the Git repository will be used. If you are versioning the content of your Git repository, and are using branches or version tags, you can provide the name of the branch or version and it will be used. This will ensure that were a rebuild of the image done, that it will not start using newer files that you weren't expecting.

## Python Packages

To have specific Python packages required by a set of Jupyter notebooks installed into the image used to run the Jupyter notebook instance, you need to provide a ``requirements.txt`` file.

The ``requirements.txt`` file must be located in the top of the Git repository if the context directory is left empty, or in the specified context directory if one is supplied.

The format of the file is the standard format expected by ``pip``.

* https://pip.readthedocs.io/en/1.1/requirements.html

All packages to be installed need to be hosted on public repositories.

## System Packages

When Python packages are installed, you can only install packages where system packages they depend on exist in the Python S2I builder base image. All typical packages used in data science with Jupyter notebooks should be able to be installed with no issue.

If a Python package is required which needs an additional system package to be installed, a docker type build phase is incorporated into the deployment, so that the extra system packages can be installed.

To add in additional system packages, you can modify the ``Dockerfile`` included in the [notebook](../notebook) sub directory of this repository.

The base image uses CentOS, so you will need to use yum/rpm to install packages and use the appropriate system package name for CentOS.

Note that if always using the same copy of this repository, the set of system packages you install by customising the docker build in the ``notebook`` directory, will carry through to any future deployments for other courses. You can then use it to build up over time a custom base image which incorporates additional system packages for a range of courses.

## Triggering Builds

When the JupyterHub deployment is done, the builds will be automatically setup and run. If you need to make changes to the set of Jupyter notebook files, data files, or ``requirements.txt`` file after the deployment has been done, you will need to trigger a new build.

To re-rerun the build for the image used to run the Jupyter notebook instance, you can run the command:

```
$ oc start-build jupyterhub-nb-img -n coursename
```

The new image will be used for any new Jupyter notebook instances started.

If the changes include changes to Jupyter notebook and data files, and a user has previously started up a Jupyter notebook instance, their persistent storage would have been populated with the original files. In this case, they would need to rename or delete their workspace directory, then stop and start their Jupyter notebook instance. When the Jupyter notebook instance starts up again, their workspace directory will be populated with the new files.

If adding additional Python packages into the ``requirements.txt`` file and you also needed to add an additional system package to the docker build from the ``notebook`` subdirectory, you can trigger a new docker build for that phase by running:

```
$ oc start-build jupyterhub-nb-bld -n coursename
```

When that build completes, it will automatically trigger a new build of ``jupyterhub-nb-img``.

## Private Git Repository

The assumption in the templates and the all in one deployment script for deploying the JupyterHub instance is that the Git repository holding the notebooks is public. If the Git repository is private, the manual [step by step instructions](step-by-step-installation.md) for deploying the JupyterHub instance will need to be followed.

In following the step by step instructions, after you have created the project, but before you instantiate the template, you will need to perform additional setup steps.

Because the steps depend on the the Git hosting service being used, and the way in which the private Git repository is being accessed, exact details are not provided here. Instead you are referred to these series of blog posts on using a private Git repository.

* https://blog.openshift.com/private-git-repositories-part-1-best-practices/

The general steps you need to do are:

1. Enable external access to the private Git repository.
2. Create the secret in OpenShift for the Git repository credentials.
3. Annotate the secret with the details of the Git repository.
4. Mark that the secret can be used by the ``builder`` service account.

Check the blog post series for details on the specific Git hosting service being used.

Once you have performed these steps, then run the step to instantiate the template which creates the JupyterHub deployment.

Alternatively, you can create the secrets as raw resource definitions in a file supplied as _Project Resources_ when using ``deploy-jupyterhub.sh``. The secrets must have labels of ``app=jupyterhub`` and ``link=builder`` so that they will be automatically linked with the ``builder`` service account and used.
