# utils.py
import torch
import torchvision
import cv2
import numpy as np
import math
import torch.nn as nn


class HeightPredictionModel(nn.Module):
    def __init__(self):
        super(HeightPredictionModel, self).__init__()
        self.fc1 = nn.Linear(4, 128)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(128, 64)
        self.fc3 = nn.Linear(64, 1)

    def forward(self, x):
        x = self.fc1(x)
        x = self.relu(x)
        x = self.fc2(x)
        x = self.relu(x)
        x = self.fc3(x)
        return x


def detect_objects(yolov5_model, image, device, confidence_threshold=0.5):
    results = yolov5_model(image)
    boxes = results.xyxy[0].cpu().numpy()
    filtered_boxes = [box for box in boxes if box[4] >= confidence_threshold]
    return filtered_boxes


def segment_objects(mask_rcnn_model, image, boxes, device, scaler, regression_model, target_size=(512, 512)):
    def pad_to_square(image):
        width, height = image.size
        max_side = max(width, height)
        padding = (
            (max_side - width) // 2,
            (max_side - height) // 2,
            (max_side - width + 1) // 2,
            (max_side - height + 1) // 2,
        )
        return torchvision.transforms.functional.pad(image, padding, fill=0, padding_mode='constant')

    transform = torchvision.transforms.Compose([
        torchvision.transforms.ToPILImage(),
        torchvision.transforms.Lambda(pad_to_square),
        torchvision.transforms.Resize(target_size, interpolation=torchvision.transforms.InterpolationMode.BILINEAR),
        torchvision.transforms.ToTensor()
    ])

    image_tensor = torch.from_numpy(image).permute(2, 0, 1).float() / 255.0
    image_tensor = image_tensor.to(device)
    masks = []
    all_outputs = []

    for box in boxes:
        x1, y1, x2, y2 = map(int, box[:4])
        cropped_image = image_tensor[:, y1:y2, x1:x2]
        resized_image = transform(cropped_image.permute(1, 2, 0).cpu().numpy()).to(device)
        resized_image = resized_image.unsqueeze(0)

        with torch.no_grad():
            output = mask_rcnn_model(resized_image)
            all_outputs.append(output)

        max_height = 0
        max_width = 0
        best_mask = None

        for i, mask in enumerate(output[0]['masks']):
            mask_np = mask[0].mul(255).byte().cpu().numpy()
            mask_resized = cv2.resize(mask_np, (x2 - x1, y2 - y1), interpolation=cv2.INTER_NEAREST)
            mask_full_image = np.zeros(image.shape[:2], dtype=np.uint8)
            mask_full_image[y1:y2, x1:x2] = mask_resized
            height = calculate_height_from_mask(mask_np)
            width = calculate_width_from_mask(mask_np)

            if height > max_height and output[0]['labels'][i] == 3:
                max_height = height
                max_width = width
                best_mask = mask_full_image

        if max_height != 0:
            angle = math.radians(15)
            sin_angle = np.sin(angle)
            cos_angle = np.cos(angle)

            input_features = np.array([[max_height, max_height / max_width, sin_angle, cos_angle]])
            input_features = scaler.transform(input_features)
            input_tensor = torch.tensor(input_features, dtype=torch.float32).to(device)
            real_height = regression_model(input_tensor).item()

            masks.append((x1, y1, x2, y2, best_mask, real_height, max_height, max_width))

    return masks, all_outputs


def calculate_height_from_mask(mask):
    max_height = 0
    for col in range(mask.shape[1]):
        y_indices = np.where(mask[:, col] > 127)[0]
        if len(y_indices) > 0:
            height = np.max(y_indices) - np.min(y_indices)
            if height > max_height:
                max_height = height
    return max_height


def calculate_width_from_mask(mask):
    max_width = 0
    for row in range(mask.shape[0]):
        x_indices = np.where(mask[row, :] > 127)[0]
        if len(x_indices) > 0:
            width = np.max(x_indices) - np.min(x_indices)
            if width > max_width:
                max_width = width
    return max_width


def draw_boxes_and_masks(image, masks, outputs):
    heights = []
    widths = []
    for _, mask_info in enumerate(masks):
        x1, y1, x2, y2, mask, real_height, height, width = mask_info
        heights.append(real_height)
        widths.append(width)
        cv2.rectangle(image, (x1, y1), (x2, y2), (0, 255, 0), 2)
        cv2.putText(image, f'{real_height:.2f} mm', (x1, y1 - 20), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
        if mask is not None:
            mask_color = np.zeros_like(image)
            mask_color[:, :, 1] = mask
            image = cv2.addWeighted(image, 1.0, mask_color, 0.5, 0)
    return image, heights, widths
