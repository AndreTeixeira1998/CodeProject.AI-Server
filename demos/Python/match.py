import os
import requests
import demoConfig as cfg

image_data2 = open(os.path.join(cfg.imageDir, "RobertDowneyJr3.jpg"), "rb").read()
image_data1 = open(os.path.join(cfg.imageDir, "RobertDowneyJr4.jpg"), "rb").read()

response = requests.post(
    cfg.serverUrl + "vision/face/match",
    files={"image1": image_data1, "image2": image_data2},
    verify=cfg.verifySslCert

).json()

print(response)
