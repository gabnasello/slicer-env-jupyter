#!/bin/bash

VERSION='2026-09-15'

docker build --network=host --no-cache -t gnasello/slicer-env-jupyter:$VERSION .