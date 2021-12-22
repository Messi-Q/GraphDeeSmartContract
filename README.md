# GraphDeeSmartContract ![GitHub stars](https://img.shields.io/github/stars/Messi-Q/GraphDeeSmartContract.svg?style=plastic) ![GitHub forks](https://img.shields.io/github/forks/Messi-Q/GraphDeeSmartContract.svg?color=blue&style=plastic) ![License](https://img.shields.io/github/license/Messi-Q/GraphDeeSmartContract.svg?color=blue&style=plastic)

This repo is a python implementation of smart contract vulnerability detection using graph neural networks (DR-GCN).


## Requirements
### Required Packages
* **python**3 or above
* **PyTorch**1.0.0
* **numpy**1.18.2
* **sklearn** for model evaluation

Run the following script to install the required packages.
```
pip install --upgrade pip
pip install torch==1.0.0
pip install numpy==1.18.2
pip install scikit-learn
```


## Citation
Please use this citation if you want to cite our [paper](https://www.ijcai.org/Proceedings/2020/0454.pdf) or codebase in your paper:
```
@inproceedings{zhuang2020smart,
  title={Smart Contract Vulnerability Detection using Graph Neural Network.},
  author={Zhuang, Yuan and Liu, Zhenguang and Qian, Peng and Liu, Qi and Wang, Xiang and He, Qinming},
  booktitle={IJCAI},
  pages={3283--3290},
  year={2020}
}
``` 


## Running project
* To run program, use this command: python SMVulDetector.py.
* In addition, you can use specific hyper-parameters to train the model. All the hyper-parameters can be found in `parser.py`.

Examples:
```shell
python SMVulDetector.py --dataset training_data/REENTRANCY_CORENODES_1671
python SMVulDetector.py --dataset training_data/REENTRANCY_CORENODES_1671 --model gcn_modify --n_hidden 192 --lr 0.001 -f 64,64,64 --dropout 0.1 --vector_dim 100 --epochs 50 --lr_decay_steps 10,20 
```

Using script：
Repeating 10 times for different seeds with `train.sh`.
```shell
for i in $(seq 1 10);
do seed=$(( ( RANDOM % 10000 )  + 1 ));
python SMVulDetector.py --model gcn_modify --seed $seed | tee logs/smartcheck_"$i".log;
done
```
Then, you can find the training results in the `logs/`.


### Dataset
ESC: [Ethereum Smart Contracts](https://drive.google.com/open?id=1h9aFFSsL7mK4NmVJd4So7IJlFj9u0HRv)

VSC: [Vntchain Smart Contacts](https://drive.google.com/open?id=1FTb__ERCOGNGM9dTeHLwAxBLw7X5Td4v)

The train data after normalization:

`training_data/LOOP_CORENODES_1317`, `LOOP_FULLNODES_1317`, `REENTRANCY_CORENODES_1671`, `REENTRANCY_FULLNODES_1671`


### Reference
1. A fraction of the code reuses the code of [graph_unet](https://github.com/bknyaz/graph_nn).
2. Thomas N. Kipf, Max Welling, Semi-Supervised Classification with Graph Convolutional Networks, ICLR 2017.
