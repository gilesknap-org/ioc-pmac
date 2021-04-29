
# EPICS delta tau pmac Dockerfile
ARG REGISTRY=gcr.io/diamond-privreg/controls/prod
ARG SYNAPPS_VERSION=6.2b1.1

FROM ${REGISTRY}/epics/epics-synapps:${SYNAPPS_VERSION}

ARG MOTOR_VERSION=R7-2-1
ARG PMAC_VERSION=2-4-11

# install additional dependecies
USER root

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    libssh2-1-dev \
    libboost-dev

# get additional support modules
USER ${USERNAME}

RUN ./add_module.sh epics-modules motor MOTOR ${MOTOR_VERSION}
RUN ./add_module.sh dls-controls pmac PMAC ${PMAC_VERSION}

# patch for distro
COPY --chown=${USER_UID}:${USER_GID} CONFIG_SITE.linux-x86_64.Common ${SUPPORT}/pmac-${PMAC_VERSION}/configure
RUN cp ${SUPPORT}/motor-${MOTOR_VERSION}/motorApp/Db/basic_asyn_motor.db ${SUPPORT}/motor-${MOTOR_VERSION}/motorApp/Db/basic_asyn_motor.template

# update dependencies and build
RUN make release && \
    make -C motor-${MOTOR_VERSION} && \
    make -C pmac-${PMAC_VERSION} && \
    make clean

# update the generic IOC Makefile
COPY --chown=${USER_UID}:${USER_GID} Makefile ${SUPPORT}/ioc/iocApp/src

# update dependencies and build (separate step for efficient image layers)
RUN make release && \
    make -C ioc && \
    make -C ioc clean
