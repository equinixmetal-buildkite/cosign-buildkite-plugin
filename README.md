# cosign Buildkite plugin

The cosign Buildkite plugin provides a convenient mechanism for running the
open-source cosign OCI container image signing tool for your containers.
For more information about cosign, please refer to their
[documentation](https://docs.sigstore.dev/cosign/overview).

**Important notes**

To ensure you know what you're signing:

- It's best to have this plugin run as part of the image CI build step (where the
built image is stored locally) and not as a separate step (signing a remote image).
- It's strongly recommended to use image digest instead of image tag (plugin will
automatically try to infer and use digest based on the provided image tag).
Otherwise, you might get a warning from cosign, or it may even refuse to sign the image:
>WARNING: Image reference ghcr.io/my-project/my-image:v1.2.3 uses a tag, not a
digest, to identify the image to sign.
    This can lead you to sign a different image than the intended one. Please use a
    digest (example.com/ubuntu@sha256:abc123...) rather than tag
    (example.com/ubuntu:latest) for the input to cosign. The ability to refer to
    images by tag will be removed in a future release.

## Features

- Automatically downloads and verifies the `cosign` executable if it cannot be
  found in the `PATH` environment variable's directories

## Basic signing examples

The following code snippets demonstrates how to use the plugin in a pipeline
step with the configuration parameters and upload the signature to the same
repository as the container image.

### Keyless signing (default)

#### Using the Public-Good Sigstore Instance

>WARNING: risk of data leakage - sensitive information may be unintentionally exposed to the public, do not use for non-public repos!

```yml
steps:
  - plugins:
      - equinixmetal-buildkite/cosign#v0.1.0:
          image: "ghcr.io/my-project/my-image@sha256:1e1e4f97dd84970160975922715909577d6c12eaaf6047021875674fa7166c27"
```

#### Using a custom/private Sigstore Instance

```yml
steps:
  - plugins:
      - equinixmetal-buildkite/cosign#v0.1.0:
          image: "ghcr.io/my-project/my-image@sha256:1e1e4f97dd84970160975922715909577d6c12eaaf6047021875674fa7166c27"
          keyless-config:
            tuf-mirror-url: "https://tuf.my-sigstore.dev"
            tuf-root-url: "https://tuf.my-sigstore.dev/root.json"
            rekor-url: "https://rekor.my-sigstore.dev"
            fulcio-url: "https://fulcio.my-sigstore.dev"
```

### Keyed signing

Note: Currently, only the file-based keyed signing is supported.

#### Using the Public-Good Sigstore Instance

>WARNING: risk of data leakage - sensitive information may be unintentionally exposed to the public, do not use for non-public repos!

```yml
steps:
  - plugins:
      - equinixmetal-buildkite/cosign#v0.1.0:
          image: "ghcr.io/my-project/my-image@sha256:1e1e4f97dd84970160975922715909577d6c12eaaf6047021875674fa7166c27"
          keyless: false
          keyed-config:
            key: "/path-to/cosign.key"
```

#### Using a custom/private Sigstore Instance

```yml
steps:
  - plugins:
      - equinixmetal-buildkite/cosign#v0.1.0:
          image: "ghcr.io/my-project/my-image@sha256:1e1e4f97dd84970160975922715909577d6c12eaaf6047021875674fa7166c27"
          keyless: false
          keyed-config:
            tuf-mirror-url: "https://tuf.my-sigstore.dev"
            tuf-root-url: "https://tuf.my-sigstore.dev/root.json"
            rekor-url: "https://rekor.my-sigstore.dev"
            key: "/path-to/cosign.key"
```

## Configuration

### `image` (Required, string)

References the image to sign.

To avoid issues, use the image digest instead of image tag.
See `Important notes` above for details.

### `keyless` (Optional, boolean)

If set to `true`, the plugin will use keyless signatures. If set to `false`, the
plugin will use a keypair. If not specified, the plugin will default to `true`.

### `keyless-config` (Optional, object)

If `keyless` is set to `true`, the plugin will use the following configuration
parameters to sign the container image:

- `tuf-mirror-url` (Optional, string):
  The URL of the TUF server to use. If not specified, the plugin will use
  the default TUF URL of the Public-Good Sigstore Instance.
- `tuf-root-url` (Optional, string):
  The URL of the TUF root JSON file to use. If not specified, the plugin will use
  the default TUF root JSON file URL of the Public-Good Sigstore Instance.
- `rekor_url` (Optional, string):
  The URL of the Rekor server to use. If not specified, the plugin will use
  the default Rekor URL of the Public-Good Sigstore Instance.
- `fulcio_url` (Optional, string):
  The URL of the Fulcio server to use. If not specified, the plugin will use
  the default Fulcio URL of the Public-Good Sigstore Instance.
- `oidc-issuer` (Optional, string):
  The URL of the OIDC issuer. If not specified, the plugin will use
  the default OIDC issuer URL of the Public-Good Sigstore Instance.
- `oidc-provider` (Optional, string):
  The URL of the OIDC provider. If not specified, the plugin will use
  the default `buildkite-agent` OIDC provider for Buildkite.

### `keyed-config` (Optional, object)

If `keyless` is set to `false`, the plugin will use the following configuration
parameters to sign the image:

- `tuf-mirror-url` (Optional, string):
  The URL of the TUF server to use. If not specified, the plugin will use
  the default TUF URL of the Public-Good Sigstore Instance.
- `tuf-root-url` (Optional, string):
  The URL of the TUF root JSON file to use. If not specified, the plugin will use
  the default TUF root JSON file URL of the Public-Good Sigstore Instance.
- `rekor_url` (Optional, string):
  The URL of the Rekor server to use. If not specified, the plugin will use
  the default Rekor URL of the Public-Good Sigstore Instance.
- `key` (Required, string): The path to the private key to use.

### `cosign-version` (Optional, string)

Controls the version of cosign to be used.

## Developing

To run the tests:

```shell
make test
```

Run the tests with debug logging enabled:

```shell
TEST_DEBUG=1 make test
```

To enable debug logging for a stubbed command in the test, you need to set or
uncomment the export for the necessary command in the `.bats` file.

e.g. to view the debug logging for the `cosign` command, set the following
at the top of the `.bats` file:

```shell
export cosign_STUB_DEBUG=/dev/tty
```

and then run the tests with debug logging enabled:

```shell
TEST_DEBUG=1 make test
```
