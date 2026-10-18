# Application-owned Dockerfile

This scenario overlays a root `Dockerfile` and `.dockerignore` on the pinned
Petclinic MySQL fixture. Initialization must preserve both files, reference the
root Dockerfile from `azure.yaml`, and provide Spring datasource bindings
through Container Apps environment variables.
