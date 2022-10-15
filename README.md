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
          sign:
            image: "ghcr.io/my-project/my-image:latest"
            keyless: true
            keyless_config:
              fulcio_url: "https://fulcio.sigstore.dev"
              rekor_url: "https://rekor.sigstore.dev" 
```

This will use keyless signatures and upload the signature to the same repository
as the image. Note that if the Fulcio URL and Rekor URL are not specified, the
plugin will use the default values presented.

## Configuration

### `sign` (Optional, object)

Contains the configuration for doing a container signature.

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
