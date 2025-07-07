import re
from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.core.exceptions import ValidationError

# 自訂使用者管理器
class CustomUserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, employee_id, name, password=None, **extra_fields):
        if not employee_id:
            raise ValueError('必須提供員工編號')
        if not name:
            raise ValueError('必須提供姓名')
        user = self.model(employee_id=employee_id, name=name, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, employee_id, name, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(employee_id, name, password, **extra_fields)

# 驗證五位數員工編號
def validate_five_digit_id(value):
    if value == 'A0000':
        return  # 特例通過
    if not re.fullmatch(r'\d{5}', value):
        raise ValidationError('員工編號必須是五位數數字（例如 00001）')

# 自訂使用者模型（員工帳號）
class CustomUser(AbstractUser):
    username = None
    employee_id = models.CharField(
        max_length=5,
        unique=True,
        verbose_name='員工編號',
        validators=[validate_five_digit_id]
    )
    name = models.CharField(max_length=100, verbose_name='姓名')

    ROLE_CHOICES = (
        ('A', '管理者'),
        ('B', '查詢者'),
    )
    role = models.CharField(max_length=1, choices=ROLE_CHOICES, default='B')

    USERNAME_FIELD = 'employee_id'
    REQUIRED_FIELDS = ['name']

    objects = CustomUserManager()

    def __str__(self):
        return f"{self.employee_id} - {self.name} ({self.role})"
    
    class Meta:
        verbose_name = '員工帳號'
        verbose_name_plural = '帳號管理'
        ordering = ['employee_id']

# 工作說明書模型
class SignalGuide(models.Model):
    category = models.CharField(max_length=100)       # 類別
    title = models.CharField(max_length=200)          # 工作說明書名稱
    device_name = models.CharField(max_length=200)    # 設備名稱
    error_description = models.TextField()            # 故障情形
    file = models.FileField(upload_to='manuals/')     # 上傳 PDF

    def __str__(self):
        return self.title
    
    class Meta:
        verbose_name = '工作說明書'
        verbose_name_plural = '工作說明書列表'
        ordering = ['category', 'title']
