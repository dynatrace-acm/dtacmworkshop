#!/bin/bash

echo "Start Production carts load"
nohup ../utils/cartsLoadTest.sh &
nohup ../utils/cartsLoadTest.sh &
