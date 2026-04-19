#!/usr/bin/env bats

@test "dummy.tar is extracted into HTTP_EXPOSE_FOLDER" {
  rm -rf "$HTTP_EXPOSE_FOLDER/dummy.tar" || true #Remove if already present from a previous test
  sudo rm ".$HOST_DOCS_FOLDER/dummy.tar" --verbose
  sudo cp "tests/doc-extracter/dummy.tar" ".$HOST_DOCS_FOLDER" --verbose
  [ -d "$HTTP_EXPOSE_FOLDER/dummy.tar" ]
  [ -z $(ls "$HTTP_EXPOSE_FOLDER" | grep "hylozoa") ]
}