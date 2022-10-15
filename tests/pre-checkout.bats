#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# Uncomment the following line to debug stub failures
#export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty
#export CURL_STUB_DEBUG=/dev/tty
#export MKTEMP_STUB_DEBUG=/dev/tty
#export SHA256SUM_STUB_DEBUG=/dev/tty
#export UNAME_STUB_DEBUG=/dev/tty

readonly TESTV='6.6.6'

setup() {
  export BUILDKITE_PLUGIN_COSIGN_VERSION="${TESTV}"
  stub buildkite-agent "\* \* \* \* \* \* : exit 0"
}

teardown() {
  unset BUILDKITE_PLUGIN_COSIGN_VERSION
  # Handle scenarios where the stub is never called by returning 0.
  # This is because unstub throws an error if the stub was never
  # executed. We need to do so because there are scenarios where
  # buildkite-agent is never called.
  unstub buildkite-agent || return 0
}

@test "os_cpu_string: uname failure" {
  stub uname "-a : exit 123"

  run "$PWD/hooks/pre-checkout"

  [ "$status" -eq 1 ]

  unstub uname
}

@test "os_cpu_string: unknown os" {
  stub uname "-a : echo foobar"

  run "$PWD/hooks/pre-checkout"

  [ "$status" -eq 2 ]

  unstub uname
}

@test "os_cpu_string: unknown cpu" {
  stub uname "-a : echo Linux foobar"

  run "$PWD/hooks/pre-checkout"

  [ "$status" -eq 3 ]

  unstub uname
}

@test "download_cosign: curl hashes file failure" {
  stub uname "-a : echo Linux amd64"
  stub curl "\* \* \* : exit 66"

  run "$PWD/hooks/pre-checkout"

  [ "$status" -eq 41 ]

  unstub uname
  unstub curl
}

@test "download_cosign: no hashes" {
  stub uname "-a : echo Linux amd64"
  stub curl "\* \* \* : echo ''"

  run "$PWD/hooks/pre-checkout"

  [ "$status" -eq 42 ]

  unstub uname
  unstub curl
}

@test "download_cosign: no matching hash" {
  stub uname "-a : echo Linux amd64"
  stub curl "\* \* \* : printf '%s\n%s\n' 'foo foo' 'bar bar'"

  run "$PWD/hooks/pre-checkout"

  [ "$status" -eq 43 ]

  unstub uname
  unstub curl
}

@test "download_cosign: mktemp failure" {
  stub uname "-a : echo Linux amd64"
  stub curl "--fail -L https://github.com/sigstore/cosign/releases/download/v${TESTV}/cosign_checksums.txt : echo '82678d08fe942e81f8bb72a13e70bc3696f9a69756bdb2ee507e0f57cb5b3777  cosign-linux-amd64'"
  stub mktemp "\* : exit 123"

  run "$PWD/hooks/pre-checkout"

  [ "$status" -eq 44 ]

  unstub uname
  unstub curl
  unstub mktemp
}

@test "download_cosign: curl cosign exectuable failure" {
  stub uname "-a : echo Linux amd64"
  stub mktemp "-d : echo /tmp/x"
  stub curl \
    "--fail -L https://github.com/sigstore/cosign/releases/download/v${TESTV}/cosign_checksums.txt : echo 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f  cosign-linux-amd64'" \
    "--fail -L -o /tmp/x/cosign https://github.com/sigstore/cosign/releases/download/v${TESTV}/cosign-linux-amd64 : exit 123"

  run "$PWD/hooks/pre-checkout"

  [ "$status" -eq 45 ]

  unstub uname
  unstub mktemp
  unstub curl
}

@test "sha2_256_hash_file: target file missing" {
  stub uname "-a : echo Linux amd64"
  stub mktemp "-d : echo /tmp/x"
  stub curl \
    "--fail -L https://github.com/sigstore/cosign/releases/download/v${TESTV}/cosign_checksums.txt : echo 'AAAA  cosign-linux-amd64'" \
    "--fail -L -o /tmp/x/cosign https://github.com/sigstore/cosign/releases/download/v${TESTV}/cosign-linux-amd64 : echo foobar"

  run "$PWD/hooks/pre-checkout"

  [ "$status" -eq 31 ]

  unstub uname
  unstub mktemp
  unstub curl
}

@test "sha2_256_hash_file: empty hash result" {
  temp="$(mktemp -d)"
  tar_file="${temp}/cosign"

  stub uname "-a : echo Linux amd64"
  stub mktemp "-d : echo ${temp}"
  stub curl \
    "--fail -L https://github.com/sigstore/cosign/releases/download/v${TESTV}/cosign_checksums.txt : echo 'AAAA  cosign-linux-amd64'" \
    "--fail -L -o ${tar_file} https://github.com/sigstore/cosign/releases/download/v${TESTV}/cosign-linux-amd64 : echo foobar > ${tar_file}"
  stub sha256sum "\* : echo"

  run "$PWD/hooks/pre-checkout"

  [ "$status" -eq 34 ]

  unstub uname
  unstub curl
  unstub mktemp
  unstub sha256sum
}

@test "sha2_256_hash_file: hash verification failure" {
  temp="$(mktemp -d)"
  tar_file="${temp}/cosign"

  stub uname "-a : echo Linux amd64"
  stub mktemp "-d : echo ${temp}"
  stub curl \
    "--fail -L https://github.com/sigstore/cosign/releases/download/v${TESTV}/cosign_checksums.txt : echo 'AAAA  cosign-linux-amd64'" \
    "--fail -L -o ${tar_file} https://github.com/sigstore/cosign/releases/download/v${TESTV}/cosign-linux-amd64 : echo foobar > ${tar_file}"
  stub sha256sum "\* : echo 'hailsatan  ${tar_file}'"

  run "$PWD/hooks/pre-checkout"

  [ "$status" -eq 35 ]

  unstub uname
  unstub curl
  unstub mktemp
  unstub sha256sum
}

@test "main: existing cosign" {
  temp="$(mktemp -d)"
  cosign_exe="${temp}/cosign"
  touch "${cosign_exe}"

  stub which "cosign : echo ${cosign_exe}"
  echo "${cosign_exe}"

  run "$PWD/hooks/pre-checkout"

  [ "$output" == "${cosign_exe}" ]

  unstub which
}

@test "main: cosign downloaded from internets to temp" {
  temp="$(mktemp -d)"
  tar_file="${temp}/cosign"
  cosign_exe="${temp}/cosign"

  stub which \
    "cosign : exit 1" \
    "sha256sum : exit 0"
  stub uname "-a : echo Linux amd64"
  stub mktemp "-d : echo ${temp}"
  stub curl \
    "--fail -L https://github.com/sigstore/cosign/releases/download/v${TESTV}/cosign_checksums.txt : echo 'AAAA  cosign-linux-amd64'" \
    "--fail -L -o ${tar_file} https://github.com/sigstore/cosign/releases/download/v${TESTV}/cosign-linux-amd64 : echo foobar > ${tar_file}"
  stub sha256sum "\* : echo 'AAAA  ${tar_file}'"

  run "$PWD/hooks/pre-checkout"

  [ "$output" == "${cosign_exe}" ]

  unstub which
  unstub uname
  unstub curl
  unstub mktemp
  unstub sha256sum
}
