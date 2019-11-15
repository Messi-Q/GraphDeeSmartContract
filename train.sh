#!/usr/bin/env bash
for i in $(seq 1 10);
do seed=$(( ( RANDOM % 10000 )  + 1 ));
python SmConVulDetector.py --model gcn_modify --seed $seed | tee logs/reentrancy_results/GraphDeeLogs_fullnodes_1671/smartcheck_"$i".log;
done

