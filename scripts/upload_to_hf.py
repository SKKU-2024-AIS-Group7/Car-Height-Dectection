from huggingface_hub import login, HfApi, HfFolder
import os
from dotenv import load_dotenv


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
