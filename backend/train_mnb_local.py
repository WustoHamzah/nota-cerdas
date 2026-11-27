"""Latih mnb_model.pkl secara lokal dari datasets/transaksi_indonesia.csv.

Pakai:  python train_mnb_local.py
Hasil:  models_ai/mnb_model.pkl  (+ metrik Accuracy, classification_report, confusion matrix)
"""
from pathlib import Path

import joblib
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import train_test_split
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline

from ai_service import clean_text  # preprocessing identik dengan saat inferensi

BASE = Path(__file__).resolve().parent
CSV_PATH = BASE / "datasets" / "transaksi_indonesia.csv"
MODEL_PATH = BASE / "models_ai" / "mnb_model.pkl"
LABELS = ["Makan", "Transportasi", "Kebutuhan", "Lainnya"]


def train(verbose: bool = True) -> dict:
    df = pd.read_csv(CSV_PATH)
    X = df["text"].astype(str).map(clean_text)
    y = df["category"]
    X_tr, X_te, y_tr, y_te = train_test_split(
        X, y, test_size=0.2, stratify=y, random_state=42
    )
    model = Pipeline([
        ("tfidf", TfidfVectorizer(ngram_range=(1, 2))),
        ("clf", MultinomialNB(alpha=0.5)),
    ])
    model.fit(X_tr, y_tr)
    pred = model.predict(X_te)
    acc = accuracy_score(y_te, pred)
    if verbose:
        print(f"Data: {len(df)} baris | train={len(X_tr)} test={len(X_te)}")
        print(f"Accuracy: {acc:.4f}\n")
        print(classification_report(y_te, pred, labels=LABELS, digits=4))
        print("Confusion matrix (baris=aktual, kolom=prediksi):", LABELS)
        print(confusion_matrix(y_te, pred, labels=LABELS))
    MODEL_PATH.parent.mkdir(exist_ok=True)
    joblib.dump(model, MODEL_PATH)
    if verbose:
        print(f"\nModel disimpan: {MODEL_PATH}")
    return {"accuracy": acc, "n_test": len(y_te)}


if __name__ == "__main__":
    train()
