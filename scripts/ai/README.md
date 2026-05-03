´´´bash
nix-shell -p python3 python313Packages.pyyaml --run "python scripts/ai/download-models.py"
´´´

# Optimizing Code Generation with llama-swap

**Running the Benchmark**

To run the benchmark, execute the following commands:

1. `llama-swap -config benchmark-config.yaml`
1. `./run-benchmark.sh http://localhost:8080 "3090-only" "3090-with-draft" "3090-P40-draft"`

The [benchmark script](run-benchmark.sh) generates a CSV output of the results, which can be converted to a Markdown table for readability.
