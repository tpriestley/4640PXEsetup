#!/bin/bash

#copies setup folder to vm and runs script
scp -r setup/ todoapp:
ssh todoapp bash setup/install_script.sh