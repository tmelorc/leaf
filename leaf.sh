#!/bin/bash 
### BEGIN LEAF INFO
#                     ;     
#             ::     ;;;
#             ::    ;;;;
#             ::   ;;;;;
#             ::  ;;;;;;
#             :: ;;;;;;
#       ;     :: ;;;;;       ██╗     ███████╗ █████╗ ███████╗
#      ;;     ::;;;;         ██║     ██╔════╝██╔══██╗██╔════╝
#     ;;;;    ::;            ██║     █████╗  ███████║█████╗   
#     ;;;;;   ::             ██║     ██╔══╝  ██╔══██║██╔══╝  
#     ;;;;;;  ::             ███████╗███████╗██║  ██║██║     
#      ;;;;;  ::             ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝ (2016-2017)
#        ;;;; ::             Developed by
#           ;;::             - Thiago de Melo
#            ;::             - Jamil V. Pereira
#             ::             IGCE Unesp (Brazil)
#  \/    \/   ::    \/\/\/\/                       \/ \/
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### END LEAF INFO




## variables
export BEGIN_TIME
BEGIN_TIME=$(date +%s)
export DATE_TIME
DATE_TIME=$(date +%Y-%m-%d_%H:%M)
export LEAF="LEAF"
export LEAF_VERSION="2.0"
export DIR_INPUT
DIR_INPUT=$(pwd)
export DIR_OUTPUT="$DIR_INPUT"/output_"$DATE_TIME"
export time_avg=15
export minArea=10000
export threshold=62
export currentFile=1
export numTotalFiles=1
export numQuarentena=0
export percentQ=$(( 100*numQuarentena/currentFile ))
export log=LOGFILE-$DATE_TIME.txt
export ls=LISTFILE-$DATE_TIME.txt
export vacina=VACCINE-$DATE_TIME.txt
export rotated=ROTATED-$DATE_TIME.txt
export alldata=data.all
export LOCK_FILE=ncc_failed.txt
export grass="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
export grassSize=${#grass} 

. scripts/functions.sh
. scripts/colors.sh


IM_VERSION=$(convert -version | head -n 1 | awk -F' ' '{print $3}')
#tar=$DIR_OUTPUT/$DATE_TIME.tar.gz

## read options
while getopts ":a:ci:o:f:t:vhpp" opt; do
  case $opt in
    a)
	  export minArea=$OPTARG
      ;;
    c)
      optc=true
      crop
      exit
      ;;
    f) 
      optf=true
      [ "$opti" = "true" ] && echo "Options -i and -f can not be used together" && exit 1
	  export FILE_INPUT=$OPTARG
	  export DIR_INPUT
      DIR_INPUT=$(dirname "$FILE_INPUT")
	  [ "$opto" != "true" ] && export DIR_OUTPUT && DIR_OUTPUT="$DIR_INPUT"/output_$(date +%Y-%m-%d_%H:%M)
	  single_mode="true"
      ;;
    h)
      help
	  exit
      ;; 
    i)
      opti=true
      [ "$optf" = "true" ] && echo "Options -f and -i can not be used together" && exit 1
      export DIR_INPUT=$OPTARG
      [ "$opto" != "true" ] && export DIR_OUTPUT && DIR_OUTPUT="$DIR_INPUT"/output_$(date +%Y-%m-%d_%H:%M)
      ;;
    o) 
      opto=true
      export DIR_OUTPUT=$OPTARG
      ;;
    p)
	  export optp=true
	  echo "option p"
      exit
      ;;
    t)
      export threshold=$OPTARG
      ;;
    v)
        export optv=true
        #echo "option v: $optv"
        ;;
    \?)
      echo "Invalid option: -$OPTARG."
      help && exit 1
      ;;
	:)
	  echo "Option -$OPTARG requires an argument." && exit 1
	  ;;
  esac
done

### BEGIN LEAF BODY

## summary
clear
printf '\e[5;33m%*s\n' "${COLUMNS:=$(tput cols)}" '' | tr ' ' = 
							echo "    date_time: $DATE_TIME"    | tee -a "$log"
[ "$optf"  = "true" ] && 	echo "         mode: SINGLE"        | tee -a "$log"
[ "$optf" != "true" ] && 	echo "         mode: BATCH"         | tee -a "$log"
							echo "  ImageMagick: $IM_VERSION"   | tee -a "$log"
							echo "      minArea: $minArea"      | tee -a "$log"
							echo "    threshold: $threshold%"   | tee -a "$log"
[ "$optv" = "true" ]  && 	echo "  vaccination: TRUE"          | tee -a "$log"
hrule
							echo " input folder: $DIR_INPUT"    | tee -a "$log"
							echo "output folder: $DIR_OUTPUT"   | tee -a "$log"


## creating output folders and exporting them
mkdir -p "$DIR_OUTPUT"
for dir in {bin,data,final,quarentena}; do
	mkdir -p "$DIR_OUTPUT/$dir" 2>/dev/null
	export DIR_$dir="$DIR_OUTPUT/$dir"
							echo "      created: $DIR_OUTPUT/$dir"
done

hrule

## cleaning
bash ./scripts/clean.sh 

## main.sh
echo "LEAF: $LEAF_VERSION" >> "$log"
echo "minArea: $minArea" >> "$log"


## single mode
if [[ "$single_mode" = "true" ]]; then
	export numTotalFiles=1
	export percent=100
    estimated_time
    #image_dim $FILE_INPUT
    echo "$FILE_INPUT" > "$ls"
	echo "total input files: $numTotalFiles" | tee -a "$log"
    cat "$ls" >> "$log"
	printf '%*s\n\e[0m' "${COLUMNS:=$(tput cols)}" '' | tr ' ' = 
	bash ./scripts/main.sh "$FILE_INPUT"
else
## batch mode
	export numTotalFiles
    numTotalFiles=$(ls "$DIR_INPUT"/*.{jpg,png} 2>/dev/null | wc -l)
    [ "$numTotalFiles" == 0 ] && echo -e ${redbb}" *** No input files in $DIR_INPUT. Stopped."${off} && echo "" && exit 1
    estimated_time
    ls "$DIR_INPUT"/*.{jpg,png} 2>/dev/null > "$ls"
	echo -e "     total input files: $numTotalFiles" | tee -a "$log"
    cat "$ls" >> "$log"
	echo -e "estimated running time: $ESTIMATED_TIME_STR"
	printf '%*s\n\e[0m' "${COLUMNS:=$(tput cols)}" '' | tr ' ' =
	confirm
	for file in $(ls "$DIR_INPUT"/*.{jpg,png} 2>/dev/null); do
        ####   2>/dev/null;   # testar se existe file pra evitar erro
		clear
 		bash ./scripts/main.sh "$file" 
		currentFile=$((currentFile+1))
        sleep 1
	done
fi

#exit 0 ########## coloquei manualmente

sleep 0

## calling vacina.sh
if [ "$optv" == "true" ]; then
if [ "$(ls -A "$DIR_quarentena")" ]; then
	numQuarentena=$(ls "$DIR_quarentena"/*.png | wc -l)
	percentQ=$((100*numQuarentena/numTotalFiles ))
	printf '\e[0;31;41m%*s\n''\e[1;37m' "${COLUMNS:=$(tput cols)}" '' | tr ' ' = 
    ans="n"
	[ "$optv" != "true" ] && read -r -n 1 -p "Apply vaccine (y/n)? Infected ($numQuarentena : $percentQ%) " ans
    [ "$optv"  = "true" ] && echo "Automatic vaccination mode" && sleep 1
	echo ""
	printf '\e[0;31;41m%*s''\e[0m' "${COLUMNS:=$(tput cols)}" '' | tr ' ' = 
	if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
        export vacina_ans=true
		[ "$optv" != "true" ] && echo -e '\e[1;32m'"YES: starting vaccination..."'\e[0m'
		echo "---< vaccination >---" >> "$log"
		bash ./scripts/vacina.sh
	else
		echo -e '\e[1;36m'"NO! Skipping process..."'\e[0m'
	fi
	Hrule
fi fi

## computing TDA functions on final directory only if not empty
if [ "$(ls -A "$DIR_final")" ]; then
    i=1
    total=$(ls "$DIR_final"/*.png | wc -l)
    echo -e ${greenbb}"computing functions to TDA... it could take some minutes"${off}
    for file in "$DIR_final"/*.png; do
        echo "[$i/$total] diameter.sh on $file"
        bash ./scripts/diameter.sh "$file"
        i=$(( i+1 ))
    done
    echo -e ${greenbb}"done"${off}

    hrule
    echo -e ${greenbb}"checking UP-DOWN"${off}
    bash ./scripts/up-down.sh "$DIR_OUTPUT"
    echo -e ${greenbb}"done"${off}
fi



#cd $DIR_OUTPUT && tar -zcf $tar data/ && cd ..

total_time
printf '\e[0m''%*s\n' "${COLUMNS:=$(tput cols)}" '' | tr ' ' = 
echo -e ${yellowbb}"Total Time: $TOTAL_TIME_STR... Good bye ${USER^^}"${off}
echo               "Total Time: $TOTAL_TIME_STR" >> "$log"
printf '%*s\n' "${COLUMNS:=$(tput cols)}" '' | tr ' ' = 

mv "$log" "$ls" ./*-"$vacina" "$rotated" data.all "$DIR_OUTPUT" 2>/dev/null
rm "$LOCK_FILE" bordered.jpg 2>/dev/null

exit 0
