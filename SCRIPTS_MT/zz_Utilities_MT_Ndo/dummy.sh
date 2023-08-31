#!/bin/bash

dummy=$1


nozero=$(echo $dummy | $PATHGNU/gsed 's/\.*0*$//')

echo $nozero
