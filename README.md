# ivr-freeswitch — FreeSWITCH base image

Reusable FreeSWITCH base image for our IVR projects. It carries FreeSWITCH plus
the modules our IVRs need, which the upstream
image used before (`ghcr.io/patrickbaus/freeswitch-docker`) does not ship.
`mod_curl` lets in-process Lua IVRs fire HTTP calls (`bgapi curl ...`).

Built from SignalWire's official Debian packages (FreeSWITCH 1.10 stable),
multi-arch `linux/amd64` + `linux/arm64`.

## Published image

```
ghcr.io/snapwre/ivr-freeswitch:latest
```

Consuming projects build their application image `FROM` this
base and copy their own config in. This base only contains the FreeSWITCH
binary, the module set, and an empty `/usr/share/freeswitch/sounds/custom` dir.

## Build & publish (GitHub Actions)

1. **Token secret (one time).** Get a free *Personal Access Token* from
   <https://signalwire.com> → Dashboard → "Personal Access Token". Add it under
   **Settings → Secrets and variables → Actions** as `SIGNALWIRE_TOKEN`.
2. **Run the workflow.** Actions → **Build FreeSWITCH base image** → *Run
   workflow*. Also runs on every push to `main` and on `fs-v*` tags.
3. Image is pushed to `ghcr.io/snapwre/ivr-freeswitch` (tags: `latest`, short
   commit SHA, and any tag/manual tag supplied).
4. If the package is private, make it pullable: GHCR package page → **Package
   settings → Change visibility → Public** (or grant the deploy host a PAT).

## Build locally (optional)

```bash
export SIGNALWIRE_TOKEN=pat_xxx
DOCKER_BUILDKIT=1 docker build \
  --secret id=signalwire_token,env=SIGNALWIRE_TOKEN \
  -t ghcr.io/snapwre/ivr-freeswitch:latest .
```

The token is read from a BuildKit secret and never written to a persisted image
layer.

## Module set

The package list in the [`Dockerfile`](./Dockerfile) must match the consuming
project's `autoload_configs/modules.conf.xml`. **Load a new module there → add
its `freeswitch-mod-*` package here too** and re-run the workflow, otherwise
FreeSWITCH will fail to load it.
