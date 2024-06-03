import os
import re
from huggingface_hub import login, HfApi, HfFolder
from dotenv import load_dotenv
from roboflow import Roboflow


def hf_login():
    load_dotenv()

    token = os.getenv("HUGGINGFACE_TOKEN")

    if token is None:
        raise ValueError("HUGGINGFACE_TOKEN 환경변수가 설정되지 않았습니다.")

    login(token=token)


def upload_model_to_hf(repo_name, local_model_dir, filenames):
    api = HfApi()
    token = HfFolder.get_token()

    for filename in filenames:
        model_path = os.path.join(local_model_dir, filename)
        print(model_path)
        if os.path.exists(model_path):
            api.upload_file(
                path_or_fileobj=model_path,
                path_in_repo=filename,
                repo_id=repo_name,
                repo_type="model",
                token=token,
            )


def find_latest_exp_dir(runs_dir='../yolov5/runs/train'):
    exp_dirs = [d for d in os.listdir(runs_dir) if os.path.isdir(os.path.join(runs_dir, d)) and re.match(r'exp\d*', d)]
    exp_numbers = [int(d[3:]) if len(d) > 3 else 0 for d in exp_dirs]
    latest_exp_dir = f'exp{max(exp_numbers)}' if exp_numbers else None
    return os.path.join(runs_dir, latest_exp_dir) if latest_exp_dir else None


def download_images_from_rb():
    roboflow_token = os.getenv("ROBOFLOW_TOKEN")
    rf = Roboflow(api_key=roboflow_token)
    project = rf.workspace("roboflow-gw7yv").project("self-driving-car")
    version = project.version(3)
    dataset = version.download("yolov5", location="../data")