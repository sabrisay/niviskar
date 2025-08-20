import pandas as pd
from sklearn.metrics import accuracy_score
import joblib
import json
import os

def evaluate(test_path, model_path, report_path):
    df = pd.read_csv(test_path)
    X = df.drop('label', axis=1)
    y = df['label']
    model = joblib.load(os.path.join(model_path, 'model.joblib'))
    preds = model.predict(X)
    acc = accuracy_score(y, preds)
    with open(report_path, 'w') as f:
        json.dump({'accuracy': acc}, f)

if __name__ == '__main__':
    import sys
    evaluate(sys.argv[1], sys.argv[2], sys.argv[3])
