import numpy as np
from os.path import join as pjoin
from sklearn.metrics import confusion_matrix

data_dir = "./logs/timestamp_results/"


# Performance evaluation, tools : SmartCheck, Securify, Mythril, Oyente
def read_label(fpath, line_parse_fn=None):
    with open(pjoin(data_dir, fpath), 'r') as f:
        lines = f.readlines()
    data = [line_parse_fn(s) if line_parse_fn is not None else s for s in lines]
    return data


ground_truth = read_label("ground_truth_185.txt", line_parse_fn=lambda s: int(float(s.strip())))
securify_label = read_label("securify_label_185.txt", line_parse_fn=lambda s: int(float(s.strip())))
smartcheck_label = read_label("smartcheck_label_185.txt", line_parse_fn=lambda s: int(float(s.strip())))
myth_label = read_label("myth_label_185.txt", line_parse_fn=lambda s: int(float(s.strip())))
oyente_label = read_label("oyente_label_185.txt", line_parse_fn=lambda s: int(float(s.strip())))

# tn, fp, fn, tp = confusion_matrix(ground_truth, securify_label).ravel()
tn, fp, fn, tp = confusion_matrix(ground_truth, smartcheck_label).ravel()
# tn, fp, fn, tp = confusion_matrix(ground_truth, myth_label).ravel()
# tn, fp, fn, tp = confusion_matrix(ground_truth, oyente_label).ravel()

print(tn, fn, fp, tp)

print('Accuracy:', (tn + tp) / (tn + fp + fn + tp))
print('False positive rate(FPR): ', fp / (fp + tn))
print('False negative rate(FNR): ', fn / (fn + tp))
recall = tp / (tp + fn)
print('Recall(TPR): ', recall)
precision = tp / (tp + fp)
print('Precision: ', precision)
print('F1 score: ', (2 * precision * recall) / (precision + recall))
