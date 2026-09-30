# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /


FROM golang:latest AS orbit-build

WORKDIR /build

RUN git clone --branch 7319-orbit-nixos-external-components --sparse --depth 1 --filter=blob:none  https://github.com/fleetdm/fleet.git .

RUN git sparse-checkout set orbit server client pkg ee

RUN CGO_ENABLED=1 \
    GOOS=linux \
    GOARCH=amd64 \
    go build \
    -trimpath \
    # -ldflags="-s -w -X github.com/fleetdm/fleet/v4/orbit/pkg/build.Version=$VERSION \
    # -X github.com/fleetdm/fleet/v4/orbit/pkg/build.Commit=$COMMIT \
    # -X github.com/fleetdm/fleet/v4/orbit/pkg/build.Date=$DATE" \
    -o ./orbit-linux ./orbit/cmd/orbit

RUN CGO_ENABLED=1 \
    GOOS=linux \
    GOARCH=amd64 \
    go build \
    -trimpath \
    # -ldflags="-s -w -X github.com/fleetdm/fleet/v4/orbit/pkg/build.Version=$VERSION \
    # -X github.com/fleetdm/fleet/v4/orbit/pkg/build.Commit=$COMMIT \
    # -X github.com/fleetdm/fleet/v4/orbit/pkg/build.Date=$DATE" \
    -o ./fleet-desktop ./orbit/cmd/desktop

# Base Image
FROM ghcr.io/ublue-os/base-main:44

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

RUN rm /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

COPY --from=ghcr.io/ublue-os/brew:latest /system_files /
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /usr/bin/systemctl preset brew-setup.service && \
    /usr/bin/systemctl preset brew-update.timer && \
    /usr/bin/systemctl preset brew-upgrade.timer

COPY --from=orbit-build /build/orbit-linux /usr/bin/orbit
COPY --from=orbit-build /build/fleet-desktop /usr/bin/fleet-desktop
COPY ./build_files/orbit.service /usr/lib/systemd/system/orbit.service
COPY ./build_files/orbit-env /etc/default/orbit
RUN systemctl enable orbit.service

RUN systemctl enable ly@tty2.service
RUN systemctl disable getty@tty2.service
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint


