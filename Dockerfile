# EPICS pmac Dockerfile. Adds support for delta tau turbo pmac 2 and power
ARG REGISTRY=gcr.io/diamond-pubreg/controls/prod
ARG MODULES_VERSION=1.0.5

FROM ${REGISTRY}/epics/epics-modules:${MODULES_VERSION}

# install additional dependecies
USER root

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    libssh2-1-dev \
    libboost-dev

# get additional support modules
USER ${USERNAME}

ARG MOTOR_VERSION=R7-2-1
ARG PMAC_VERSION=2-5-3
ARG IPAC_VERSION=2.16

RUN python3 module.py add epics-modules ipac IPAC ${IPAC_VERSION} && \
    python3 module.py add epics-modules motor MOTOR ${MOTOR_VERSION} && \
    python3 module.py add dls-controls pmac PMAC ${PMAC_VERSION}

# patch for distro
COPY --chown=${USER_UID}:${USER_GID} CONFIG_SITE.linux-x86_64.Common ${SUPPORT}/pmac-${PMAC_VERSION}/configure
RUN cp ${SUPPORT}/motor-${MOTOR_VERSION}/motorApp/Db/basic_asyn_motor.db ${SUPPORT}/motor-${MOTOR_VERSION}/motorApp/Db/basic_asyn_motor.template

# update the generic IOC Makefile
COPY --chown=${USER_UID}:${USER_GID} Makefile ${EPICS_ROOT}/ioc/iocApp/src

# update dependencies and build support modules AND ioc
RUN python3 module.py dependencies && \
    make  && \
    make clean

