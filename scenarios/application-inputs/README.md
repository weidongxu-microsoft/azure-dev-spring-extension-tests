# Application inputs

This scenario verifies explicit application-owned runtime values and secrets.
The application reads `APP_GREETING` and `JWT_SECRET` without an `azure.yaml`
or application configuration file.

Generation must bind the value directly, bind the secret through a Container
Apps secret reference, and require both values from the selected azd environment.
