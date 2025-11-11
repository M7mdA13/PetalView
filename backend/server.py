# server.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import numpy as np
from keras.models import load_model  # Only needs keras

app = FastAPI()

# Enable CORS for Flutter requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Development only
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load the converted model
try:
    model = load_model("bloom_predictor.h5")  # This .h5 file comes from Colab
    if model is None:
        raise ValueError("Model loaded as None")
except Exception as e:
    print(f"Error loading model: {str(e)}")
    raise Exception("Failed to load model. Make sure 'bloom_predictor.h5' exists in the correct location and is valid.")

# Define input schema
class ModelInput(BaseModel):
    feature1: float
    feature2: float
    # Add more features as needed

@app.post("/predict")
def predict(data: ModelInput):
    input_data = np.array([[data.feature1, data.feature2]])  # adjust shape
    prediction = model.predict(input_data)
    return {"prediction": prediction.tolist()}

@app.get("/")
def root():
    return {"message": "Backend is running"}
