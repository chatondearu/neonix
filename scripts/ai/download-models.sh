#!/usr/bin/env bash

# Bash version of scripts/ai/download-models.py
# Downloads and verifies AI models using llama-completion

CONFIG_YAML_PATH="/etc/llama-swap/config.yaml"

# Check if config file exists
if [[ ! -f "$CONFIG_YAML_PATH" ]]; then
    echo "Error: $CONFIG_YAML_PATH not found."
    exit 1
fi

echo "Reading configuration from $CONFIG_YAML_PATH..."

# Parse YAML to get models
# We need to use a YAML parser. If yq is available, use it.
if command -v yq &> /dev/null; then
    MODELS=$(yq eval '.models' "$CONFIG_YAML_PATH" 2>/dev/null)
    if [[ -z "$MODELS" ]]; then
        echo "Error: Could not parse models from YAML."
        echo "Install yq with: nix-env -iA nixpkgs.yq-go or use the Python version."
        exit 1
    fi
else
    echo "Error: yq not found. Please install yq (nixpkgs.yq-go) or use the Python version."
    exit 1
fi

# Count number of models (approximate)
MODEL_COUNT=$(echo "$MODELS" | yq length 2>/dev/null || echo "0")
echo "Found $MODEL_COUNT models."
echo "============================================================"

# Process each model
for model_name in $(echo "$MODELS" | yq keys -); do
    echo "Processing model: $model_name"
    
    # Get the cmd for this model
    cmd=$(echo "$MODELS" | yq ".$model_name.cmd" - 2>/dev/null)
    
    if [[ -z "$cmd" ]]; then
        echo "  Skipping $model_name: No command found."
        echo "------------------------------------------------------------"
        continue
    fi
    
    # Extract relevant arguments (-hf, --hf-repo, --hf-file, --mmproj-url)
    # This is a simple parser that looks for these patterns
    dl_args=()
    
    # Split command into parts
    read -ra cmd_parts <<< "$cmd"
    
    i=0
    while [[ $i -lt ${#cmd_parts[@]} ]]; do
        arg="${cmd_parts[$i]}"
        
        case "$arg" in
            -hf|--hf-repo|--hf-file|--mmproj-url)
                dl_args+=("$arg")
                if [[ $i -lt $((${#cmd_parts[@]} - 1)) ]]; then
                    dl_args+=("${cmd_parts[$i+1]}")
                    ((i++))
                fi
                ;;
        esac
        
        ((i++))
    done
    
    # Check if we found any relevant arguments
    if [[ ${#dl_args[@]} -eq 0 ]]; then
        echo "  Warning: No HuggingFace arguments found in command. Skipping."
        echo "------------------------------------------------------------"
        continue
    fi
    
    # Construct llama-completion command
    # We use -p "check" -n 1 to just load the model and generate 1 token, ensuring it's downloaded.
    cli_cmd=("llama-completion" "${dl_args[@]}" "-p" "System check" "-n" "1" "--no-display-prompt")
    
    echo "  Running: ${cli_cmd[*]}"
    
    # Run the command
    if "${cli_cmd[@]}"; then
        echo "  -> Success/Verified."
    else
        echo "  -> Failed (or maybe just interrupted)."
    fi
    
    echo "------------------------------------------------------------"
done
