#!/usr/bin/env bats

@test "benchmarkresults_1234_dummy.json is moved from HOST_BMS_FOLDER into BM_EXPOSE_FOLDER" {
    benchmark_file="benchmarkresults_1234_dummy.json"

    #Clean
    sudo rm -rf ".$HOST_BMS_FOLDER/$benchmark_file" --verbose || true
    sudo rm -rf "$BM_EXPOSE_FOLDER/$benchmark_file" --verbose || true

    # Copy
    sudo cp -r "tests/benchmark-exposer/$benchmark_file" ".$HOST_BMS_FOLDER" --verbose
    sleep 1
    
    # Test
    [ -f ".$HOST_BMS_FOLDER/$benchmark_file" ]
    [ -f "$BM_EXPOSE_FOLDER/$benchmark_file" ]

    # Clean
    sudo rm -rf ".$HOST_BMS_FOLDER/$benchmark_file" --verbose || true
    sudo rm -rf "$BM_EXPOSE_FOLDER/$benchmark_file" --verbose || true
}