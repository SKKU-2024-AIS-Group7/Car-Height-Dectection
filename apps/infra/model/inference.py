import torch
import torchvision
import joblib
import json
import cv2
import numpy as np
from PIL import Image
import os
from utils import HeightPredictionModel, detect_objects, segment_objects, draw_boxes_and_masks


def model_fn(model_dir):
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    
    hf_path = 'https://huggingface.co/jspark2000/yolov5-vehicle/resolve/main/best.pt'
    yolov5_model = torch.hub.load('ultralytics/yolov5', 'custom', path=hf_path, force_reload=True).to(device)

    mask_rcnn_model = torchvision.models.detection.maskrcnn_resnet50_fpn_v2(pretrained=True).to(device)
    mask_rcnn_model.eval()

    regression_model = HeightPredictionModel()
    regression_model.load_state_dict(torch.load(os.path.join(model_dir, 'height_prediction_model.pth')))
    regression_model.to(device)
    regression_model.eval()

    scaler = joblib.load(os.path.join(model_dir, 'scaler.pkl'))

    return {
        'yolov5_model': yolov5_model,
        'mask_rcnn_model': mask_rcnn_model,
        'regression_model': regression_model,
        'scaler': scaler,
        'device': device
    }



def input_fn(request_body, content_type):
    if content_type == 'image/jpeg':
        image = Image.open(request_body)
        return np.array(image)
    else:
        raise ValueError('Unsupported content type: {}'.format(content_type))



def predict_fn(input_object, model):
    yolov5_model = model['yolov5_model']
    mask_rcnn_model = model['mask_rcnn_model']
    regression_model = model['regression_model']
    scaler = model['scaler']
    device = model['device']

    image_rgb = cv2.cvtColor(input_object, cv2.COLOR_BGR2RGB)
    boxes = detect_objects(yolov5_model, image_rgb, device)
    vehicle_boxes = [box for box in boxes if int(box[5]) in [1, 10]]
    masks, outputs = segment_objects(mask_rcnn_model, image_rgb, vehicle_boxes, device, scaler, regression_model)
    image_with_masks, heights, widths = draw_boxes_and_masks(image_rgb, masks, outputs)

    output_image_path = '/tmp/output_image_with_masks.jpg'
    output_image = cv2.cvtColor(image_with_masks, cv2.COLOR_RGB2BGR)
    cv2.imwrite(output_image_path, output_image)

    return {
        'heights': heights,
        'widths': widths,
        'output_image_path': output_image_path
    }


def output_fn(prediction, accept):
    if accept == 'application/json':
        return json.dumps(prediction)
    else:
        raise ValueError('Unsupported accept type: {}'.format(accept))
