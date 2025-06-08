from sklearn.model_selection import train_test_split
import pandas as pd
from MarkovModelConstructor import MarkovModelConstructor

def fit_classifier(df: pd.DataFrame, model):
    features = ['TransitionMatrix']
    X = df[features].to_numpy()
    y = df['StrategyLabel'].to_numpy()
    
    # Split the data into training and testing sets
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Fit the model
    model.fit(X_train, y_train)
    
    # Evaluate the model
    accuracy = model.score(X_test, y_test)
    print(f"Model accuracy: {accuracy}")
    
    return model

if __name__ == "__main__":
    path = "analysis/data/final_datasets/final_experiment_fixations.csv"
    states = ['sent_msg', 'trgt', 'comp', 'dist', 'available_msgs']
    keep_non_aoi = False
    if keep_non_aoi:
        states.append('non_aoi')
    MarkovModelConstr = MarkovModelConstructor(states)
    df = MarkovModelConstr.create_markov_models(path, states, save=False, per='participant')
    from sklearn.ensemble import RandomForestClassifier
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    fitted_model = fit_classifier(df, model)