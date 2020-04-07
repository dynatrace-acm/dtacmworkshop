#!/bin/bash

../utils/deleteagConfiguration.sh

gcloud container clusters delete acmworkshop --zone=us-central1-a -q
gcloud compute instances delete dtactivegate --zone=us-central1-a -q