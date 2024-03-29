# Add support for delta tau turbo pmac 2 and power pmac
ARG MOTOR_VERSION=R7-2-1
ARG PMAC_VERSION=2-5-3
ARG IPAC_VERSION=2.16

##### build stage ##############################################################

FROM ghcr.io/epics-containers/epics-modules:4.41r3.0 AS developer

ARG MOTOR_VERSION
ARG PMAC_VERSION
ARG IPAC_VERSION

# install additional dependecies
USER root

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    libssh2-1-dev \
    libboost-dev \
    && rm -rf /var/lib/apt/lists/*

USER ${USERNAME}

# get additional support modules
RUN python3 module.py add epics-modules ipac IPAC ${IPAC_VERSION} && \
    python3 module.py add epics-modules motor MOTOR ${MOTOR_VERSION} && \
    python3 module.py add dls-controls pmac PMAC ${PMAC_VERSION}

# add CONFIG_SITE.linux
COPY --chown=${USER_UID}:${USER_GID} CONFIG_SITE.linux-x86_64.Common ${SUPPORT}/pmac-${PMAC_VERSION}/configure
RUN cp ${SUPPORT}/motor-${MOTOR_VERSION}/motorApp/Db/basic_asyn_motor.db ${SUPPORT}/motor-${MOTOR_VERSION}/motorApp/Db/basic_asyn_motor.template

# update the generic IOC Makefile to include the new support
COPY --chown=${USER_UID}:${USER_GID} Makefile ${IOC}/iocApp/src

# update dependencies and build the support modules and the ioc
RUN python3 module.py dependencies && \
    make -j -C  ${SUPPORT}/motor-${MOTOR_VERSION} && \
    make -C  ${SUPPORT}/pmac-${PMAC_VERSION} && \
    make -j -C  ${IOC} && \
    make -j clean

##### runtime stage #############################################################

FROM ghcr.io/epics-containers/epics-modules:4.41r3.0.run AS runtime

ARG MOTOR_VERSION
ARG PMAC_VERSION
ARG IPAC_VERSION

USER ${USERNAME}

# get the products from the build stage
COPY --from=developer --chown=${USER_UID}:${USER_GID} ${SUPPORT}/motor-${MOTOR_VERSION} ${SUPPORT}/motor-${MOTOR_VERSION}
COPY --from=developer --chown=${USER_UID}:${USER_GID} ${SUPPORT}/pmac-${PMAC_VERSION} ${SUPPORT}/pmac-${PMAC_VERSION}
COPY --from=developer --chown=${USER_UID}:${USER_GID} ${IOC} ${IOC}
