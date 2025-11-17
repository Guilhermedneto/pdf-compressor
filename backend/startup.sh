#!/bin/bash

# Install Ghostscript
apt-get update
apt-get install -y ghostscript

# Start the application
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
