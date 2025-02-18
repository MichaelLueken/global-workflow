#! /usr/bin/env bash

################################################################################
#
# UNIX Script Documentation Block
# Script name:         exgfs_wave_post_gridded_sbs.sh
# Script description:  Creates output products from binary WW3 data
#
# Author:   Jose-Henrique Alves Org: NCEP/EMC      Date: 2019-12-06
# Abstract: This script is the postprocessor for the wave component in GFS.
#           This version runs side-by-side with the GFS fcst step.
#           It executes several scripts forpreparing and creating output data
#           as follows:
#
#  wave_grib2_sbs.sh         : generates GRIB2 files.
#  wave_grid_interp_ush.sh   : interpolates data from new grids to old grids
#
# Script history log:
# 2019-12-06  J-Henrique Alves: First Version adapted from HTolman post.sh 2007
# 2020-06-10  J-Henrique Alves: Porting to R&D machine Hera
# 2020-07-31  Jessica Meixner: Removing points, now gridded data only
#
# $Id$
#
# Attributes:
#   Language: Bourne-again (Bash) Shell
#
###############################################################################
#
# --------------------------------------------------------------------------- #
# 0.  Preparations

source "$HOMEgfs/ush/preamble.sh"

# 0.a Basic modes of operation

  # Set wave model ID tag to include member number
  # if ensemble; waveMEMB var empty in deterministic
  export WAV_MOD_TAG=${CDUMP}wave${waveMEMB}

  cd $DATA

  echo "Starting WAVE POSTPROCESSOR SCRIPT for $WAV_MOD_TAG"

  set +x
  echo ' '
  echo '                     *********************************'
  echo '                     *** WAVE POSTPROCESSOR SCRIPT ***'
  echo '                     *********************************'
  echo ' '
  echo "Starting at : $(date)"
  echo '-------------'
  echo ' '
  ${TRACE_ON:-set -x}

# Script will run only if pre-defined NTASKS
#     The actual work is distributed over these tasks.
  if [ -z ${NTASKS} ]
  then
    echo "FATAL ERROR: requires NTASKS to be set "
    err=1; export err;${errchk}
    exit $err
  fi

# 0.c Defining model grids

# 0.c.1 Grids

  export waveGRD=${waveGRD?Var waveGRD Not Set}

# 0.c.2 extended global grid and rtma transfer grid
  export waveinterpGRD=${waveinterpGRD?Var wavepostGRD Not Set}
  export wavepostGRD=${wavepostGRD?Var wavepostGRD Not Set}


  set +x
  echo ' '
  echo 'Grid information  :'
  echo '-------------------'
  echo "   Native wave grids  : $waveGRD"
  echo "   Interpolated grids : $waveinterpGRD"
  echo "   Post-process grids : $wavepostGRD"
  echo ' '
  ${TRACE_ON:-set -x}


# 0.c.3 Define CDATE_POST
  export CDATE_POST=${CDATE}
  export FHRUN=0

# --------------------------------------------------------------------------- #
# 1.  Get files that are used by most child scripts

  export DOGRB_WAV=${DOGRB_WAV:-'YES'} #Create grib2 files
  export DOGRI_WAV=${DOGRI_WAV:-'NO'} #Create interpolated grids

  exit_code=0

  set +x
  echo ' '
  echo 'Preparing input files :'
  echo '-----------------------'
  ${TRACE_ON:-set -x}

# 1.a Model definition files and output files (set up using poe)

# 1.a.1 Copy model definition files
  for grdID in $waveGRD $wavepostGRD $waveinterpGRD
  do
    if [ -f "$COMIN/rundata/${CDUMP}wave.mod_def.${grdID}" ]
    then
      set +x
      echo " Mod def file for $grdID found in ${COMIN}/rundata. copying ...."
      ${TRACE_ON:-set -x}

      cp -f $COMIN/rundata/${CDUMP}wave.mod_def.${grdID} mod_def.$grdID
    fi
  done

# 1.a.2 Check that model definition files exist
  for grdID in $waveGRD $wavepostGRD $waveinterpGRD
  do
    if [ ! -f mod_def.$grdID ]
    then
      set +x
      echo ' '
      echo '*************************************************** '
      echo " FATAL ERROR : NO MOD_DEF FILE mod_def.$grdID "
      echo '*************************************************** '
      echo ' '
      ${TRACE_ON:-set -x}
      err=2; export err;${errchk}
      exit $err
      DOGRB_WAV='NO'
    else
      set +x
      echo "File mod_def.$grdID found. Syncing to all nodes ..."
      ${TRACE_ON:-set -x}
    fi
  done


# 1.b Input template files

  if [ "$DOGRI_WAV" = 'YES' ]
  then
    for intGRD in $waveinterpGRD
    do
      if [ -f $PARMwave/${intGRD}_interp.inp.tmpl ]
      then
        cp -f $PARMwave/${intGRD}_interp.inp.tmpl ${intGRD}_interp.inp.tmpl
      fi

      if [ -f ${intGRD}_interp.inp.tmpl ]
      then
        set +x
        echo "   ${intGRD}_interp.inp.tmpl copied. Syncing to all nodes ..."
        ${TRACE_ON:-set -x}
      else
        set +x
        echo ' '
        echo '*********************************************** '
        echo '*** ERROR : NO TEMPLATE FOR GRINT INPUT FILE *** '
        echo '*********************************************** '
        echo ' '
        ${TRACE_ON:-set -x}
        echo "$WAV_MOD_TAG post $date $cycle : GRINT template file missing."
        exit_code=1
        DOGRI_WAV='NO'
      fi
    done
  fi

  if [ "$DOGRB_WAV" = 'YES' ]
  then
    for grbGRD in $waveinterpGRD $wavepostGRD
    do
      if [ -f $PARMwave/ww3_grib2.${grbGRD}.inp.tmpl ]
      then
        cp -f $PARMwave/ww3_grib2.${grbGRD}.inp.tmpl ww3_grib2.${grbGRD}.inp.tmpl
      fi

      if [ -f ww3_grib2.${grbGRD}.inp.tmpl ]
      then
        set +x
        echo "   ww3_grib2.${grbGRD}.inp.tmpl copied. Syncing to all nodes ..."
        ${TRACE_ON:-set -x}
      else
        set +x
        echo ' '
        echo '*********************************************** '
        echo "*** ERROR : NO TEMPLATE FOR ${grbGRD} GRIB INPUT FILE *** "
        echo '*********************************************** '
        echo ' '
        ${TRACE_ON:-set -x}
        exit_code=2
        DOGRB_WAV='NO'
      fi
    done
  fi


# 1.c Data summary

  set +x
  echo ' '
  echo "   Input files read and processed at : $(date)"
  echo ' '
  echo '   Data summary : '
  echo '   ---------------------------------------------'
  echo "      Sufficient data for GRID interpolation    : $DOGRI_WAV"
  echo "      Sufficient data for GRIB files            : $DOGRB_WAV"
  echo ' '
  ${TRACE_ON:-set -x}

# --------------------------------------------------------------------------- #
# 2.  Make consolidated grib2 file for side-by-side grids and interpolate
#     onto extended grids
#
# 2.a Command file set-up

  set +x
  echo '   Making command file for sbs grib2 and GRID Interpolation '
  ${TRACE_ON:-set -x}

# 1.a.2 Loop over forecast time to generate post files
# When executed side-by-side, serial mode (cfp when run after the fcst step)
# Contingency for RERUN=YES
  if [ "${RERUN-NO}" = "YES" ]; then
    fhr=$((FHRUN + FHMIN_WAV))
    if [ $FHMAX_HF_WAV -gt 0 ] && [ $FHOUT_HF_WAV -gt 0 ] && [ $fhr -lt $FHMAX_HF_WAV ]; then
      FHINCG=$FHOUT_HF_WAV
    else
      FHINCG=$FHOUT_WAV
    fi
    fhr=$((fhr + FHINCG))
  else
    fhr=$FHMIN_WAV
  fi
  fhrg=$fhr
  iwaitmax=120 # Maximum loop cycles for waiting until wave component output file is ready (fails after max)
  while [ $fhr -le $FHMAX_WAV ]; do

    ymdh=$($NDATE $fhr $CDATE)
    YMD=$(echo $ymdh | cut -c1-8)
    HMS="$(echo $ymdh | cut -c9-10)0000"
    YMDHMS=${YMD}${HMS}
    FH3=$(printf %03i $fhr)

    fcmdnow=cmdfile.${FH3}
    fcmdigrd=icmdfile.${FH3}
    mkdir output_$YMDHMS
    cd output_$YMDHMS
    rm -f ${fcmdnow} ${fcmdigrd}
    touch ${fcmdnow} ${fcmdigrd}


# Create instances of directories for gridded output
    export GRIBDATA=${DATA}/output_$YMDHMS
    export GRDIDATA=${DATA}/output_$YMDHMS

# Gridded data (main part, need to be run side-by-side with forecast

    if [ $fhr = $fhrg ]
    then
      iwait=0
      for wavGRD in ${waveGRD} ; do
        gfile=$COMIN/rundata/${WAV_MOD_TAG}.out_grd.${wavGRD}.${YMD}.${HMS}
        while [ ! -s ${gfile} ]; do sleep 10; let iwait=iwait+1; done
        if [ $iwait -eq $iwaitmax ]; then
          echo '*************************************************** '
          echo " FATAL ERROR : NO RAW FIELD OUTPUT FILE out_grd.$grdID "
          echo '*************************************************** '
          echo ' '
          ${TRACE_ON:-set -x}
          echo "$WAV_MOD_TAG post $grdID $date $cycle : field output missing."
          err=3; export err;${errchk}
          exit $err
        fi
        ln -s ${gfile} ./out_grd.${wavGRD}
      done

      if [ "$DOGRI_WAV" = 'YES' ]
      then
        nigrd=1
        for grdID in $waveinterpGRD
        do
          ymdh_int=$($NDATE -${WAVHINDH} $ymdh); dt_int=3600.; n_int=9999 ;
          echo "$USHwave/wave_grid_interp_sbs.sh $grdID $ymdh_int $dt_int $n_int > grint_$grdID.out 2>&1" >> ${fcmdigrd}.${nigrd}
          if [ "$DOGRB_WAV" = 'YES' ]
          then
            gribFL=\'$(echo ${OUTPARS_WAV})\'
            case $grdID in
              glo_15mxt) GRDNAME='global' ; GRDRES=0p25 ; GRIDNR=255  ; MODNR=11 ;;
              reg025) GRDNAME='global' ; GRDRES=0p25 ; GRIDNR=255  ; MODNR=11 ;;
              glo_30mxt) GRDNAME='global' ; GRDRES=0p50 ; GRIDNR=255  ; MODNR=11 ;;
              glo_30m) GRDNAME='global' ; GRDRES=0p50 ; GRIDNR=255  ; MODNR=11 ;;
              at_10m) GRDNAME='atlocn' ; GRDRES=0p16 ; GRIDNR=255  ; MODNR=11   ;;
              ep_10m) GRDNAME='epacif' ; GRDRES=0p16 ; GRIDNR=255  ; MODNR=11   ;;
              wc_10m) GRDNAME='wcoast' ; GRDRES=0p16 ; GRIDNR=255  ; MODNR=11   ;;
              ak_10m) GRDNAME='alaska' ; GRDRES=0p16 ; GRIDNR=255  ; MODNR=11   ;;
            esac
            echo "$USHwave/wave_grib2_sbs.sh $grdID $GRIDNR $MODNR $ymdh $fhr $GRDNAME $GRDRES $gribFL > grib_$grdID.out 2>&1" >> ${fcmdigrd}.${nigrd}
          fi
          echo "${GRIBDATA}/${fcmdigrd}.${nigrd}" >> ${fcmdnow}
          chmod 744 ${fcmdigrd}.${nigrd}
          nigrd=$((nigrd+1))
        done
      fi

      if [ "$DOGRB_WAV" = 'YES' ]
      then
        for grdID in ${wavepostGRD} # First concatenate grib files for sbs grids
        do
          gribFL=\'$(echo ${OUTPARS_WAV})\'
          case $grdID in
              aoc_9km) GRDNAME='arctic' ; GRDRES=9km ; GRIDNR=255  ; MODNR=11   ;;
              ant_9km) GRDNAME='antarc' ; GRDRES=9km ; GRIDNR=255  ; MODNR=11   ;;
              glo_10m) GRDNAME='global' ; GRDRES=0p16 ; GRIDNR=255  ; MODNR=11   ;;
              gnh_10m) GRDNAME='global' ; GRDRES=0p16 ; GRIDNR=255  ; MODNR=11   ;;
              gsh_15m) GRDNAME='gsouth' ; GRDRES=0p25 ; GRIDNR=255  ; MODNR=11   ;;
              glo_15m) GRDNAME='global' ; GRDRES=0p25 ; GRIDNR=255  ; MODNR=11   ;;
              ao_20m) GRDNAME='arctic' ; GRDRES=0p33 ; GRIDNR=255  ; MODNR=11   ;;
              so_20m) GRDNAME='antarc' ; GRDRES=0p33 ; GRIDNR=255  ; MODNR=11   ;;
              glo_15mxt) GRDNAME='global' ; GRDRES=0p25 ; GRIDNR=255  ; MODNR=11   ;;
              reg025) GRDNAME='global' ; GRDRES=0p25 ; GRIDNR=255  ; MODNR=11   ;;
              gwes_30m) GRDNAME='global' ; GRDRES=0p50 ; GRIDNR=255  ; MODNR=10 ;;
          esac
          echo "$USHwave/wave_grib2_sbs.sh $grdID $GRIDNR $MODNR $ymdh $fhr $GRDNAME $GRDRES $gribFL > grib_$grdID.out 2>&1" >> ${fcmdnow}
        done
      fi

    fi

    if [ ${CFP_MP:-"NO"} = "YES" ]; then
      nfile=0
      ifile=0
      iline=1
      ifirst='yes'
      nlines=$( wc -l ${fcmdnow} | awk '{print $1}' )
      while [ $iline -le $nlines ]; do
        line=$( sed -n ''$iline'p' ${fcmdnow} )
        if [ -z "$line" ]; then
          break
        else
          if [ "$ifirst" = 'yes' ]; then
            echo "#!/bin/sh" > cmdmfile.$nfile
            echo "$nfile cmdmfile.$nfile" >> cmdmprog
            chmod 744 cmdmfile.$nfile
          fi
          echo $line >> cmdmfile.$nfile
          nfile=$(( nfile + 1 ))
          if [ $nfile -eq $NTASKS ]; then
            nfile=0
            ifirst='no'
          fi
          iline=$(( iline + 1 ))
        fi
      done
    fi

    wavenproc=$(wc -l ${fcmdnow} | awk '{print $1}')
    wavenproc=$(echo $((${wavenproc}<${NTASKS}?${wavenproc}:${NTASKS})))

    set +x
    echo ' '
    echo "   Executing the grib2_sbs scripts at : $(date)"
    echo '   ------------------------------------'
    echo ' '
    ${TRACE_ON:-set -x}

    if [ "$wavenproc" -gt '1' ]
    then
      if [ ${CFP_MP:-"NO"} = "YES" ]; then
        ${wavempexec} -n ${wavenproc} ${wave_mpmd} cmdmprog
      else
        ${wavempexec} ${wavenproc} ${wave_mpmd} ${fcmdnow}
      fi
      exit=$?
    else
      chmod 744 ${fcmdnow}
      ./${fcmdnow}
      exit=$?
    fi

    if [ "$exit" != '0' ]
    then
      set +x
      echo ' '
      echo '*************************************'
      echo '*** FATAL ERROR: CMDFILE FAILED   ***'
      echo '*************************************'
      echo '     See Details Below '
      echo ' '
      ${TRACE_ON:-set -x}
      err=4; export err;${errchk}
      exit $err
    fi

    rm -f out_grd.* # Remove large binary grid output files

    cd $DATA

    FHINCG=$(( DTFLD_WAV / 3600 ))
    if [ $fhr = $fhrg ]
    then
# Check if grib2 file created
      ENSTAG=""
      if [ ${waveMEMB} ]; then ENSTAG=".${membTAG}${waveMEMB}" ; fi
      gribchk=${CDUMP}wave.${cycle}${ENSTAG}.${GRDNAME}.${GRDRES}.f${FH3}.grib2
      if [ ! -s ${COMOUT}/gridded/${gribchk} ]; then
        set +x
        echo ' '
        echo '********************************************'
        echo "*** FATAL ERROR: $gribchk not generated "
        echo '********************************************'
        echo '     See Details Below '
        echo ' '
        ${TRACE_ON:-set -x}
        err=5; export err;${errchk}
        exit $err
      fi
      if [ $FHMAX_HF_WAV -gt 0 ] && [ $FHOUT_HF_WAV -gt 0 ] && [ $fhr -lt $FHMAX_HF_WAV ]; then
        FHINCG=$FHOUT_HF_WAV
      else
        FHINCG=$FHOUT_WAV
      fi
      fhrg=$((fhr+FHINCG))
    fi
    echo $fhrg

    fhr=$fhrg #loop with out_grd stride

  done

# --------------------------------------------------------------------------- #
# 7.  Ending output

echo "$exit_code"

# End of MWW3 prostprocessor script ---------------------------------------- #
