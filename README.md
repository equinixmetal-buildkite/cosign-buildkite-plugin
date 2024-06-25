# cosign buildkite plugin

The cosign buildkite plugin provides a convenient mechanism for running the
open-source cosign container signing tool for your containers. For more information
about cosign, please refer to their
[documentation](https://docs.sigstore.dev/cosign/overview).

## Features

- Automatically downloads and verifies the cosign executable if it cannot be
  found in the `PATH` environment variable's directories

## Basic signing example

The following code snippet demonstrates how to use the plugin in a pipeline
step with the default plugin configuration parameters:

```yml
steps:
  - command: ls
    plugins:
      - equinixmetal-buildkite/cosign#v0.1.0:
          image: "ghcr.io/my-project/my-image:latest"
          keyless: true
          keyless-config:
            fulcio-url: "https://fulcio.sigstore.dev"
            rekor-url: "https://rekor.sigstore.dev" 
```

This will use keyless signatures and upload the signature to the same repository
as the image. Note that if the Fulcio URL and Rekor URL are not specified, the
plugin will use the default values presented.

## Configuration

### `image` (Required, string)

References the image to sign

### `keyless` (Optional, boolean)

If set to `true`, the plugin will use keyless signatures. If set to `false`, the
plugin will use a keypair. If not specified, the plugin will default to `false`
to avoid accidentally exposing information to the public Sigstore infrastructure.

### `keyless-config` (Optional, object)

If `keyless` is set to `true`, the plugin will use the following configuration
parameters to sign the image:

- `fulcio_url` (Optional, string): The URL of the Fulcio server to use. If not
  specified, the plugin will default to `https://fulcio.sigstore.dev`.
- `rekor_url` (Optional, string): The URL of the Rekor server to use. If not
  specified, the plugin will default to `https://rekor.sigstore.dev`.

### `keyed-config` (Optional, object)

If `keyless` is set to `false`, the plugin will use the following configuration
parameters to sign the image:

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
