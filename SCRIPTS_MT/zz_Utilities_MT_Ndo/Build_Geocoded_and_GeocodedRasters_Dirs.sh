#!/bin/bash
######################################################################################
# Dummy script to create dir structure
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#
######################################################################################

mkdir -p Geocoded 
cd Geocoded

mkdir -p Ampli
mkdir -p Coh
mkdir -p Defo
mkdir -p DefoInterpol
mkdir -p DefoInterpolDetrend
mkdir -p DefoInterpolx2Detrend
mkdir -p InterfFilt
mkdir -p InterfResid
mkdir -p UnwrapPhase

cd ..

mkdir -p GeocodedRasters 
cd GeocodedRasters

mkdir -p Ampli
mkdir -p Coh
mkdir -p Defo
mkdir -p DefoInterpol
mkdir -p DefoInterpolDetrend
mkdir -p DefoInterpolx2Detrend
mkdir -p InterfFilt
mkdir -p InterfResid
mkdir -p UnwrapPhase
