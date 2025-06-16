import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.metrics import f1_score
from MarkovModelConstructor import MarkovModelConstructor

def fit_classifier(df: pd.DataFrame, model, target):
    features = [col for col in df.columns if col != target]
    X = df[features].to_numpy()
    y = df['StrategyLabel'].to_numpy()
    
    # Split the data into training and testing sets
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Fit the model
    model.fit(X_train, y_train)
    
    # Evaluate the model
    conf_matrix = pd.crosstab(y_test, model.predict(X_test), rownames=['Actual'], colnames=['Predicted'])
    f1 = f1_score(model.predict(X_test), y_test, average='weighted')
    print(f"Model: {model.__class__.__name__}, Accuracy: {f1:.2f}")
    print("Confusion Matrix:")
    print(conf_matrix)
    
    return model

if __name__ == "__main__":
    path = "analysis/data/final_datasets/final_experiment_fixations.csv"
    states = ['sent_msg', 'trgt', 'comp', 'dist', 'av_msgs']
    keep_non_aoi = False
    if keep_non_aoi:
        states.append('non_aoi')
    MarkovModelConstr = MarkovModelConstructor(states)
    df = MarkovModelConstr.create_markov_models(path, states, include_non_aoi=False, save=False, explode=True, per='participant')
    # print(df.iloc[0]['TransitionMatrix'])
    assert df is not None, "DataFrame should not be None after Markov Model construction"
    # only keep simple condition
    df = df[df['Condition'] == 'simple']
    df.drop(columns=['Condition'], inplace=True)
    df = pd.get_dummies(df, columns=['MsgType'], drop_first=True)
    from sklearn.ensemble import RandomForestClassifier
    target = 'StrategyLabel'
    df.drop(columns=['Scanpath', 'TransitionMatrix', 'Subject', 'Correct'], inplace=True)

    model_forest = RandomForestClassifier(n_estimators=1, random_state=42, criterion='gini')
    fitted_model_forest = fit_classifier(df, model_forest, target)
    from sklearn.neighbors import KNeighborsClassifier
    model_knn = KNeighborsClassifier(n_neighbors=20)
    fitted_model_knn = fit_classifier(df, model_knn, target)
    from sklearn.neural_network import MLPClassifier
    model_nn = MLPClassifier(hidden_layer_sizes=(100, 50), max_iter=500, random_state=42)
    fitted_model_nn = fit_classifier(df, model_nn, target)

