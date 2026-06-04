# IVR FreeSWITCH base image — FreeSWITCH 1.10 plus the modules our IVRs need
# Built from SignalWire's token-gated Debian packages.
#
# The SignalWire token is supplied as a BuildKit secret (id=signalwire_token):
# read from a tmpfs mount, its only on-disk copy (apt auth.conf) is deleted in
# the same layer, so it never persists in the final image.
#
#   DOCKER_BUILDKIT=1 docker build \
#     --secret id=signalwire_token,env=SIGNALWIRE_TOKEN \
#     -t ghcr.io/snapwre/ivr-freeswitch:latest .
FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN --mount=type=secret,id=signalwire_token \
    set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends gnupg2 wget ca-certificates \
      unixodbc odbc-postgresql; \
    TOKEN="$(cat /run/secrets/signalwire_token)"; \
    wget --http-user=signalwire --http-password="$TOKEN" \
      -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg \
      https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg; \
    printf 'machine freeswitch.signalwire.com login signalwire password %s\n' "$TOKEN" \
      > /etc/apt/auth.conf; \
    chmod 600 /etc/apt/auth.conf; \
    echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ bookworm main" \
      > /etc/apt/sources.list.d/freeswitch.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      freeswitch \
      freeswitch-mod-event-socket freeswitch-mod-sofia freeswitch-mod-console \
      freeswitch-mod-commands freeswitch-mod-dptools freeswitch-mod-dialplan-xml \
      freeswitch-mod-sndfile freeswitch-mod-native-file freeswitch-mod-tone-stream \
      freeswitch-mod-lua freeswitch-mod-curl freeswitch-mod-say-en \
      freeswitch-mod-expr freeswitch-mod-hash freeswitch-mod-amr freeswitch-mod-spandsp \
      freeswitch-mod-logfile \
      freeswitch-mod-timerfd; \
    apt-get purge -y --auto-remove wget gnupg2; \
    rm -f /etc/apt/auth.conf /etc/apt/sources.list.d/freeswitch.list \
          /usr/share/keyrings/signalwire-freeswitch-repo.gpg; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /usr/share/freeswitch/sounds/custom
# Exposing 5080/udp incase kamailio runs on 5060 and forwards to FreeSWITCH on 5080. ESL on 8021/tcp.
EXPOSE 5060/udp 5080/udp 8021/tcp
CMD ["freeswitch", "-nonat", "-nf", "-c"]
