# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

FROM node:12.18-slim

# node-gyp dependencies
RUN apt-get update && apt-get install -y \
        python \
        make \
        git \
        curl \
        g++

# Add Tini - this is not ARM happy
ENV TINI_VERSION v0.18.0
ENV TINI_PLATFORM tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/${TINI_PLATFORM} /tini
RUN chmod +x /tini

# Clone FluidFramework to be able to copy Tinylicious
RUN git clone --depth 1 --branch main --single-branch https://github.com/microsoft/FluidFramework.git /tmp/FluidFramework

# Copy tinylicious and then remove the FluidFramework repo
RUN cp -r /tmp/FluidFramework/server/tinylicious /usr/src/server && rm -rf /tmp/FluidFramework
WORKDIR /usr/src/server

# Need to set the --unsafe-perm flag since we are doing the install as root. Consider adding an 'app' accout so we
# can do the install as node but then switch to 'app' to run. As app we won't be able to write to installed files
# and be able to change them.
RUN npm install

# Expose the port the app runs under
EXPOSE 3000

# And build
RUN npm run tsc

# Storage directories
RUN mkdir /var/lib/tinylicious && chown node:node /var/lib/tinylicious
RUN mkdir /var/lib/db && chown node:node /var/lib/db

# Don't run as root user
USER node

# Node wasn't designed to be run as PID 1. Tini is a tiny init wrapper. You can also set --init on docker later than
# 1.13 but Kubernetes is at 1.12 so we prefer tini for now.
ENTRYPOINT ["/tini", "--"]

# And set the default command to start the server
CMD ["npm", "start"]