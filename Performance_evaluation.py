import numpy as np
from os.path import join as pjoin
from sklearn.metrics import confusion_matrix

data_dir = "./results/"


# Performance evaluation, tools : SmartCheck, Securify, Mythril, Oyente
def read_label(fpath, line_parse_fn=None):
    with open(pjoin(data_dir, fpath), 'r') as f:
        lines = f.readlines()
    data = [line_parse_fn(s) if line_parse_fn is not None else s for s in lines]
    return data


ground_truth = read_label("ground_truth_164.txt", line_parse_fn=lambda s: int(float(s.strip())))
securify_label = read_label("securify_label_164.txt", line_parse_fn=lambda s: int(float(s.strip())))
smartcheck_label = read_label("smartcheck_label_164.txt", line_parse_fn=lambda s: int(float(s.strip())))
myth_label = read_label("myth_label_164.txt", line_parse_fn=lambda s: int(float(s.strip())))
oyente_label = read_label("oyente_label_164.txt", line_parse_fn=lambda s: int(float(s.strip())))

tn, fp, fn, tp = confusion_matrix(securify_label, ground_truth).ravel()
# tn, fp, fn, tp = confusion_matrix(smartcheck_label, ground_truth).ravel()
# tn, fp, fn, tp = confusion_matrix(myth_label, ground_truth).ravel()
# tn, fp, fn, tp = confusion_matrix(oyente_label, ground_truth).ravel()

# tn, fn, fp, tp = confusion_matrix(securify_label, ground_truth).ravel()

print(tn, fp, fn, tp)

print('Accuracy:', (tn + tp) / (tn + fp + fn + tp))
print('False positive rate(FPR): ', fp / (fp + tn))
print('False negative rate(FNR): ', fn / (fn + tp))
recall = tp / (tp + fn)
print('Recall(TPR): ', recall)
precision = tp / (tp + fp)
print('Precision: ', precision)
print('F1 score: ', (2 * precision * recall) / (precision + recall))
