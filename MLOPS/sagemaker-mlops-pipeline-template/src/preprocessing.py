import pandas as pd
from sklearn.model_selection import train_test_split

def preprocess(input_path: str, output_train: str, output_test: str):
    df = pd.read_csv(input_path)
    train_df, test_df = train_test_split(df, test_size=0.2, random_state=42)
    train_df.to_csv(output_train, index=False)
    test_df.to_csv(output_test, index=False)

if __name__ == '__main__':
    import sys
    preprocess(sys.argv[1], sys.argv[2], sys.argv[3])
