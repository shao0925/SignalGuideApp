from django.db import models

# Create your models here.

class SignalGuide(models.Model):
    category = models.CharField(max_length=100)  # 類別
    title = models.CharField(max_length=200)     # 工作說明書名稱
    device_name = models.CharField(max_length=200)  # 設備名稱
    error_description = models.TextField()       # 故障情形
    file = models.FileField(upload_to='manuals/')  # 上傳的 PDF 檔案

    def __str__(self):
        return self.title