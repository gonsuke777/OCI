import io
import json
import logging
import mimetypes
import oci
from fdk import response

# ログの設定
logging.basicConfig(level=logging.INFO)

def handler(ctx, data: io.BytesIO = None):
    # 1. API Gateway から渡されたパスを取得
    # 例: /v1/web/index.html -> index.html
    path_parameters = ctx.RequestURL().split('/')
    filename = path_parameters[-1] if path_parameters[-1] else "index.html"

    # 2. リソース・プリンシパルによる認証
    # Function 自体に付与された権限を使用して OCI サービスにアクセス
    try:
        signer = oci.auth.signers.get_resource_principals_signer()
        client = oci.object_storage.ObjectStorageClient({}, signer=signer)
        
        # 環境変数などからネームスペースとバケット名を取得（直接記述も可）
        namespace = client.get_namespace().data
        bucket_name = "AYU-OBJSTR1"

        # 3. Object Storage からファイルを取得
        get_obj = client.get_object(namespace, bucket_name, filename)
        content = get_obj.data.content

        # 4. Content-Type の自動判別
        # 拡張子に基づいて適切な MIME タイプ（text/html, image/png 等）を設定
        mime_type, _ = mimetypes.guess_type(filename)
        if not mime_type:
            mime_type = 'application/octet-stream'

        return response.Response(
            ctx, 
            response_data=content,
            headers={"Content-Type": mime_type},
            status_code=200
        )

    except oci.exceptions.ServiceError as e:
        logging.error(f"Error fetching object: {str(e)}")
        return response.Response(
            ctx, 
            response_data=json.dumps({"error": "File not found or access denied"}),
            headers={"Content-Type": "application/json"},
            status_code=404
        )
    except Exception as e:
        logging.error(f"Unexpected error: {str(e)}")
        return response.Response(
            ctx, 
            response_data=json.dumps({"error": "Internal Server Error"}),
            headers={"Content-Type": "application/json"},
            status_code=500
        )
