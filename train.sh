#!/usr/bin/env bash
for i in $(seq 1 10);
do seed=$(( ( RANDOM % 10000 )  + 1 ));
python SmConVulDetector.py --model gcn --seed $seed | tee logs/smartcheck_"$i".log;
done

