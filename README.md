Before you start, set env variables with username & password to download course resources.
See values on [here](https://trainingportal.linuxfoundation.org/learn/course/kubernetes-for-developers-lfd259/kubernetes-architecture/lab-exercises?page=2)

```bash
export TF_VAR_lfd259_password=********
export TF_VAR_lfd259_username=********
```

Make sure you have configured AWS profile. Check `~/.aws/credentials` file and select proper profile by setting env variable:

```bash
export AWS_PROFILE=******
```

For the first time, initialize terraform and S3 backend:
```bash
terraform apply
```

Start...

```bash
terraform apply
```

Wait for instance provisioning be done.
