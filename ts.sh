while getopts ":Dcm" opt; do
    case $opt in
        m)
        printf "%s\n" "本地.m3u8" && m3u8=1
        ;;
        D)
        printf "%s\n" "Dolby Vision" && DV=1
        ;;
        c)
        printf "%s\n" "合并模式" && concat=1
        ;;
esac
done
Path="$(dirname $0)"
[[  $m3u8 != 1  ]]  && [[  $concat != 1  ]] && printf "请添加-m(使用.m3u8)或-c(直接合并)\n" && exit
[[  $DV == 1  ]]  && cd "$Path"
Path1="$(pwd)"
replace()
{
    aa="$1"
    ab="$(echo "$aa" | tr "/" " " | sed 's/ /\\\//g' )"
    aline=
    aline="$ab"
}

m3u(){
    if [[  "$1" == ""  ]] ;then
        printf "参数为空"
    else
        n=0
        while read line ;do
            if [[  "$line" =~ ^"https://"  ]] || [[  "$line" =~ ^"http://"  ]]  ;then
                printf ""
                wget -t=3 --connect-timeout=15 -o wget.txt -N "$line" -O "0$n".ts 
                n=$((n+1))
                sleep 1.75
                printf 已下载"$n"个ts文件\\r
            fi
done<<EOF
$(cat $1)
EOF

cp "$1" ./.m3u8
m3u8

    #    read -p 生成的视频文件名: name
    #    echo 生成"$tspath"/"$name".mp4
    #    ffmpeg -i "${1}" -c copy "$name".mp4
    fi
}


m3u8(){
[[  "$DV" -eq 1  ]] && ts0="$(echo "$allts" | grep "/0.ts"$ )"
pm3u8="$(find . | grep "[^0-9a-zA-Z].m3u8"$ )"
if [[  "$pm3u8" != ""  ]] ;then
echo "使用m3u8文件$pm3u8"
else
echo 未找到m3u8文件 && exit
fi

if [[ -e  local.m3u8  ]];then
read -p 确定使用本地已存在的m3u8
else
(rm local.m3u8 && read -p 删除本地已存在的m3u8 && echo 删除local.m3u8 ) 2>/dev/null
echo 生成local.m3u8...
n=-1
#[[  "$DV" -eq 1  ]] &&  n=0
while read -r -e line ;do
if [[  "$line" =~ ^"#"  ]] ;then
#if [[  "$DV" -eq 1  ]];then
#[[  "$line" =~ "#EXT-X-MAP:URI"  ]] && line="#EXT-X-MAP:URI=\"$ts0\""
#fi
echo "$line" >>local.m3u8
else
line="$(echo "$line" | tr -d [a-z])" 
letters=
for i in $(seq 1 ${#line});do
letter=${line:$((i-1)):1}
if [[  "$letter" == [0-9]  ]];then
letters="$letters$letter"
else
if [[  "$letters" != ""  ]] ;then
n=$((n+1))
printf "$letters" >>local.m3u8
else
n=$((n+1))
letters="0$n"
printf "$letters" >>local.m3u8
fi
start[n]="$letters"
printf "END" >>local.m3u8
echo >>local.m3u8
break
fi
done
fi
done<<EOF
$(cat "$pm3u8")
EOF

#re="\\/"

for t in $(seq 0 $tsn);do
while read line ;do
[[  "$line" =~ "/$t.ts"$  ]] || [[  "$line" =~ "./0$t.ts"$  ]] && aline="$line" && replace "$aline" && break
#printf $aline
done<<EOF
$allts
EOF


theline="^$(cat local.m3u8 | grep  ^"${start[t]}END"$ )"
if [[  $theline != "^"  ]];then
echo "local.m3u8" | xargs sed -i "" s/"$theline"/"${aline}"/ ||  echo "local.m3u8" | xargs sed -i"" s/"$theline"/"${aline}"/ #兼容LINUX

printf "\r已整理%d个.ts文件\033[K" "$t"
fi
done
#echo "$allts2"
echo
#allts3=$(echo "$allts2" | grep "[0-9]" | tr "\n" "|" )
fi

read -p 生成的视频文件名: name
tspath="$(pwd)"
echo 生成"$tspath"/"$name".mp4

ffmpeg -i "local.m3u8" -c copy "$name".mp4

}

read -p ts文件夹路径: tspath
[[  "$tspath" == ""  ]] && tspath="./" && echo 当前文件夹路径为$(pwd)
cd "$tspath"
allts="$(find . | grep .ts$)"
tsn=$(echo "$allts" | wc -l )
if [[  "$concat" -eq 1  ]] ;then
tspath="$(pwd)"
#if [[ -e  local.txt  ]];then
#read -p 确定使用本地已存在的list
#else
#(rm local.txt && read -p 删除本地已存在的list && echo 删除local.txt ) 2>/dev/null

#echo \#\#\#\#\#\#\# >> local.txt
pt=0
echo 整合中...
for t in $(seq 0 $tsn);do
while read line ;do
aline=
[[  "$line" =~ "/$t.ts"$  ]] && aline="$line" && break
#printf $aline
done<<EOF
$allts
EOF
[[  "$aline" == ""  ]] && continue
[[  $pt -eq 1  ]] &&   allts1="$allts1|$aline" && continue
 allts1="$aline" && pt=1
done

allts1=concat:"$allts1"
#printf "$allts1\n" >> local.txt
#echo \#\#\#\#\#\#\# >> local.txt
#fi
read -p 生成的视频文件名: name

echo 生成"$tspath"/"$name".mp4
ffmpeg -i "${allts1}" -c copy "$name".mp4
elif [[  "$m3u8" -eq 1  ]];then
printf ""
m3u8
else
printf ""
m3u "$1"
fi



if [[  "$DV" -eq 1  ]];then
cd "$Path1"
read -p 确定重新封装杜比视界
"$Path"/mp4demuxer_mac --input-file "$tspath"/"$name".mp4  --output-folder "$tspath"/ 
while true;do
read -p "杜比类型(4/5/7/8/9/h)" dvn
[[  "$dvn" -eq h  ]] && "$Path"/mp4muxer_mac -h 
[[  "$dvn" -eq h  ]] &&  continue
break
done
[[  "$dvn" -eq 8  ]] && read -p "dv-bl-compatible-id:(1/2/4)" dbid 
[[  "$dvn" -ne 8  ]] && "$Path"/mp4muxer_mac -o "$tspath"/DV-"$name".mp4 -i "$tspath"/out_2.*   -i "$tspath"/out_1.* --dv-profile $dvn  --mpeg4-comp-brand mp42,iso6,isom,msdh,dby1 --overwrite
[[  "$dvn" -eq 8  ]] && "$Path"/mp4muxer_mac -o "$tspath"/DV-"$name".mp4 -i "$tspath"/out_2.*   -i "$tspath"/out_1.* --dv-profile $dvn --dv-bl-compatible-id $dbid  --mpeg4-comp-brand mp42,iso6,isom,msdh,dby1 --overwrite

fi


