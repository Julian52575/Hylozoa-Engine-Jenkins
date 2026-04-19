#!/usr/bin/env bats

@test "dummy.tar is extracted from HOST_DOCS_FOLDER into HTTP_EXPOSE_FOLDER" {
    # Clean
    sudo rm -rf ".$HOST_DOCS_FOLDER/dummy.tar" --verbose || true
    sudo rm -rf "$HTTP_EXPOSE_FOLDER/dummy.tar" --verbose || true #Remove if already present from a previous test
  
    # Copy tar archive into HOST_DOCS_FOLDER
    sudo cp "tests/doc-extracter/dummy.tar" ".$HOST_DOCS_FOLDER" --verbose
    sleep 1
  
    # Test
    [ -d "$HTTP_EXPOSE_FOLDER/dummy.tar" ]
    [ -z $(ls "$HTTP_EXPOSE_FOLDER" | grep "hylozoa") ]
  
    # Clean
    sudo rm -rf ".$HOST_DOCS_FOLDER/dummy.tar" --verbose || true
    sudo rm -rf "$HTTP_EXPOSE_FOLDER/dummy.tar" --verbose || true #Remove if already present from a previous test
}