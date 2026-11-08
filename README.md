# stirling-pdf-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF).

## What this is

A four-file TOS Docker application archive (`stirlingpdfdocker.tar.gz`) that installs
Stirling PDF on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `stirlingpdfdocker`)
- `stirlingpdfdocker.lang` — 23-language superset (TOS requires 14)
- `stirlingpdfdocker.svg` — application icon (326 bytes, 2 SVG elements)
- `docker-compose.yml` — one service, image `stirlingtools/stirling-pdf:3.3.0`

## How it works

| | |
|---|---|
| Container image | `stirlingtools/stirling-pdf:3.3.0` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8028/` (container port 8080) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/configs` → `/Volume1/DockerAppData/stirlingpdfdocker/configs`, `/data` → `/Volume1/DockerAppData/stirlingpdfdocker/data`, `/logs` → `/Volume1/DockerAppData/stirlingpdfdocker/logs`, `/storage` → `/Volume1/DockerAppData/stirlingpdfdocker/storage`, `/pipeline` → `/Volume1/DockerAppData/stirlingpdfdocker/pipeline`, `/customFiles` → `/Volume1/DockerAppData/stirlingpdfdocker/customFiles` |
| Logs | `docker logs stirlingpdfdocker` (stdout/stderr) |

`configs` holds application settings and templates; `data` is the working data folder used by the PDF pipelines. Uploaded files are processed inside the container and are not kept as a permanent library unless you save them.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Entrypoint wrapper**: the upstream image is built to run as root and keeps state in root-owned paths, so the compose file replaces the entrypoint with `src/entrypoint.sh`, which makes the service run as an unprivileged user. See that file for the details.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 8080.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **Rootless Spring Boot.** `src/entrypoint.sh` starts `/app/app.jar` directly as uid 1000 on 8080; the upstream init script is bypassed because it needs root.
- **Two volumes, one port.** `/configs` + `/data`; only 8080 is published.
- **Health check** probes `/` on 8080; the first start can take 1-2 minutes.
- **Fixed image tag**, Docker Hub only, no privileged mode, no host network, no Docker socket.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `configs` | application settings, templates and UI preferences | first start | small | never overwritten; back it up |
| `data` | working data used by PDF pipelines | first start | transient; grows with temporary jobs | safe to clean when no job is running |
| `logs` | application logs | first start | small | safe to rotate/clean |
| `storage` | application storage used by PDF features | first start | grows with use | back it up with configs |
| `pipeline` | pipeline working directory | first start | transient | safe to clean |
| `customFiles` | user-provided custom files | first start | user controlled | back it up |
| `/Volume1/DockerAppData/stirlingpdfdocker/configs` | Stirling PDF application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/stirlingpdfdocker/data` | Stirling PDF application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/stirlingpdfdocker/logs` | Stirling PDF application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/stirlingpdfdocker/storage` | Stirling PDF application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/stirlingpdfdocker/pipeline` | Stirling PDF application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/stirlingpdfdocker/customFiles` | Stirling PDF application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/stirlingpdfdocker.tar.gz + .sha256
scripts/build.sh 3.3.0-3   # packaging iteration bump
scripts/build.sh 3.3.0-2 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/stirlingpdfdocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v3.3.0-2`**, assets `stirlingpdfdocker.tar.gz` +
   `stirlingpdfdocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `stirlingpdfdocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `3.3.0-2` → automated validation → review.

## License / branding

Stirling PDF is distributed by its upstream authors under **MIT**. The container image is the official image from Docker Hub (`stirlingtools/stirling-pdf:3.3.0`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

No login is enabled by default. Anyone who can reach the published port can use the tools; do not expose it to the internet without a TLS reverse proxy and, if needed, enable security.
OCR and large PDFs are CPU/RAM intensive. Very large jobs may need a bigger container memory limit.
Uploaded files are processed transiently; this is not a document management system. Keep your originals elsewhere and download the results.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
