import pandas as pd
from sklearn.ensemble import RandomForestClassifier
import joblib
import os

def train(train_path, model_path):
    df = pd.read_csv(train_path)
    X = df.drop('label', axis=1)
    y = df['label']
    model = RandomForestClassifier(n_estimators=100)
    model.fit(X, y)
    joblib.dump(model, os.path.join(model_path, 'model.joblib'))

if __name__ == '__main__':
    import sys
    train(sys.argv[1], sys.argv[2])
