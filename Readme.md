# GraphDeeSmartContract ![GitHub stars](https://img.shields.io/github/stars/Messi-Q/GraphDeeSmartContract.svg?style=plastic) ![GitHub forks](https://img.shields.io/github/forks/Messi-Q/GraphDeeSmartContract.svg?color=blue&style=plastic) ![License](https://img.shields.io/github/license/Messi-Q/GraphDeeSmartContract.svg?color=blue&style=plastic)

This repo is a python implementation of smart contract vulnerability detection based on graph neural network (GCN). 
We also present a automation tool of generate graph.

### Running project
* To run program, use this command: python SmConVulDetector.py.
* In addition, you can use specific hyperparameters to train the model. All the hyperparameters can be found in `parser.py`.

Examples:
```shell
python SmConVulDetector.py --dataset data/SMART_CONTRACT_BY_MANUAL
python SmConVulDetector.py --dataset data/SMART_CONTRACT_BY_MANUAL --model gcn_modify --n_hidden 192 --lr 0.001 -f 64,64,64 --dropout 0.1 --vector_dim 100 --epochs 50 --lr_decay_steps 10,20 
```

Using script：
Repeating 10 times for different seeds with `train.sh`.
```shell
for i in $(seq 1 10);
do seed=$(( ( RANDOM % 10000 )  + 1 ));
python SmConVulDetector.py --model gcn --seed $seed | tee logs/smartcheck_"$i".log;
done
```
Then, you can find the training results in the `logs`.

