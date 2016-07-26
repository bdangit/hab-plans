bdangit habitat plans
=====================

[origin: bdangit](https://app.habitat.sh/#/pkgs/bdangit)

## workflow

### Build

    $ hab studio new
    $ hab studio enter

    (hab)$ build {plan}

### Run

From within habitat studio:

    (hab)$ hab start bdangit/{plan}

Dockerized:

    (hab)$ hab export docker bdangit/{plan}
    $ docker run -it bdangit/{plan}
